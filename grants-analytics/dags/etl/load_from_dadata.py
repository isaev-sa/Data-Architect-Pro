import asyncio
import logging
from typing import Any, Dict, List, Optional
import asyncpg
from dadata import DadataAsync
import json
from datetime import datetime
from etl.execute_ddl_file import execute_ddl_file

# Настройка логирования для мониторинга процесса
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


async def process_single_company(
    dadata_client: DadataAsync, 
    old_inn: Optional[str], 
    old_ogrn: Optional[str]
) -> Dict[str, Any]:

    status = "success"
    error_message = None
    suggestions = []
    
    # Очистка входящих данных от пробелов
    clean_ogrn = str(old_ogrn).strip() if old_ogrn else None
    clean_inn = str(old_inn).strip() if old_inn else None

    # Итоговый словарь ответа
    result = {
        "old_inn": old_inn,
        "old_ogrn": old_ogrn,
        "inn_dadata": None,
        "ogrn_dadata": None,
        "organizations_count": 0,
        "dadata_response": None,       
        "status": status,
        "error": error_message
    }

    try:
        # Попытка 1 - Поиск по OGRN
        if clean_ogrn and len(clean_ogrn) <= 300:
            try:
                suggestions = await dadata_client.find_by_id(name="party", query=clean_ogrn)
            except Exception as e:
                logging.warning(f"Запрос по ОГРН {clean_ogrn} завершился ошибкой: {e}. Пробуем по ИНН.")
        
        # Попытка 2 - Поиск по ИНН (если ОГРН пустой или запрос по нему вернул пустоту/ошибку)
        if not suggestions and clean_inn and len(clean_inn) <= 300:
            suggestions = await dadata_client.find_by_id(name="party", query=clean_inn)

    except Exception as main_err:
        # Сетевой сбой или критическая ошибка API Дадаты
        logging.error(f"Критическая ошибка для ИНН:{clean_inn} / ОГРН:{clean_ogrn} -> {main_err}")
        result["status"] = "error"
        result["error"] = str(main_err)
        return result

    # Разбор и разложение ответа
    if suggestions and isinstance(suggestions, list):
        result["organizations_count"] = len(suggestions)
        result["dadata_response"] = suggestions  # Сохраняем полный список объектов

        if len(suggestions) == 1:
            # Если организация строго одна — парсим её реквизиты
            first_match = suggestions[0]
            org_data = first_match.get("data", {}) or {}
            result["inn_dadata"] = org_data.get("inn")
            result["ogrn_dadata"] = org_data.get("ogrn")
            result["status"] = "success"
        else:
            # Если организаций несколько — пишем None
            result["inn_dadata"] = None
            result["ogrn_dadata"] = None
            result["status"] = "multiple_found"
            
    else:
        # Если Дадата ответила успешно, но в реестрах ничего не найдено []
        result["organizations_count"] = 0
        result["inn_dadata"] = None
        result["ogrn_dadata"] = None
        result["status"] = "not_found"
        result["dadata_response"] = suggestions

    return result


async def load_from_dadata(    
          database_url: str,
          dadata_tocken: str,
          table_ddl_file_path: str, 
          dadata_rps_limit: int,
          dadata_daily_limit: int,
          unprocessed_orgs_sql_file: str,
          record_source: str,
          load_datetime: datetime):

    # Контроль частоты RPS
    RATE_LIMIT_DELAY = 1.0 / dadata_rps_limit  

    # Создаю таблицу в базе для данных из dadata, если ее еще не создали.
    execute_ddl_file(table_ddl_file_path, database_url)

    # Читаю файл с запросом, который возвращает список необработанных организаций
    with open(unprocessed_orgs_sql_file, "r", encoding="utf-8") as f:
                    query_select = f.read()

    async with DadataAsync(dadata_tocken) as dadata_client:
        async with asyncpg.create_pool(dsn=database_url) as db_pool:
            
            # ШАГ 1: Извлечение порции необработанных организаций
            async with db_pool.acquire() as connection:
                logging.info("Выборка строк из raw_stage.pres_grants...")
                rows = await connection.fetch(query_select, dadata_daily_limit)
                
            if not rows:
                logging.info("Все данные успешно обработаны. Новых строк нет.")
                return

            logging.info(f"Получено {len(rows)} строк. Фильтрация дубликатов внутри пачки...")

            # ШАГ 2: Защита от дублей внутри текущей пачки
            seen_queries = set()
            tasks = []
            
            for row in rows:
                inn = row["inn"]
                ogrn = row["ogrn"]
                
                # Создаем уникальный текстовый ключ для определения дубликата в памяти
                lookup_key = f"{inn}_{ogrn}"
                if lookup_key in seen_queries:
                    continue
                seen_queries.add(lookup_key)

                # Создаем асинхронную задачу
                task = asyncio.create_task(
                    process_single_company(dadata_client, inn, ogrn)
                )
                tasks.append(task)
                
                # Искусственная микропауза для соблюдения лимита 30 запросов в секунду
                await asyncio.sleep(RATE_LIMIT_DELAY)
            
            if not tasks:
                logging.info("Все строки в текущей выборке оказались дубликатами друг друга.")
                return

            logging.info(f"Запуск {len(tasks)} уникальных асинхронных запросов к Дадате...")
            final_results = await asyncio.gather(*tasks)
            logging.info("Все запросы к Дадате выполнены.")

            # ШАГ 3: Трансформация результатов в массив кортежей под INSERT
            insert_data = [
                (
                    res["old_inn"],
                    res["old_ogrn"],
                    res["inn_dadata"],
                    res["ogrn_dadata"],
                    res["organizations_count"],
                    json.dumps(res["dadata_response"], ensure_ascii=False) if res["dadata_response"] is not None else None,
                    res["status"],
                    res["error"],
                    record_source,
                    load_datetime
                )
                for res in final_results
            ]

            # ШАГ 4: Пакетное сохранение в базу данных 
            logging.info("Сохранение результатов в raw_stage.ogr_info_from_dadata...")
            
            query_insert = """
                INSERT INTO raw_stage_grants.ogr_info_from_dadata (
                    old_inn, old_ogrn, inn_dadata, ogrn_dadata, organizations_count, dadata_response, status, error, record_source, load_datetime
        
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)

            """
            
            async with db_pool.acquire() as connection:
                await connection.executemany(query_insert, insert_data)
                
            logging.info(f"Пакет успешно сохранен. Записано строк в БД: {len(insert_data)}.")