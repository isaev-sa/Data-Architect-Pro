import os
import pandas as pd
from sqlalchemy import create_engine
from etl.execute_ddl_file import execute_ddl_file
from datetime import datetime


def load_parquet_to_postgres (
    database_url: str,
    target_table: str,
    schema: str, 
    parquet_file_path: str,
    table_ddl_file_path: str,
    record_source: str, 
    load_datetime: datetime,
    chunksize: int = 10000
) -> None:

    # Создание таблицы-приемника, если ее нет
    execute_ddl_file(table_ddl_file_path, database_url)

    # Проверка существования parquet-файла
    if not os.path.exists(parquet_file_path):
        raise FileNotFoundError(f"Файл по пути '{parquet_file_path}' не найден.")

    print(f"1. Чтение Parquet-файла: {os.path.basename(parquet_file_path)}...")
    df = pd.read_parquet(parquet_file_path, engine="pyarrow")
    print(f"Успешно загружено в память строк: {len(df)}")

    print(f"2. Обогащение данных системными полями [record_source, load_datetime]")
    df['record_source'] = record_source
    df['load_datetime'] = load_datetime

    print(f"3. Выполнение пакетной вставки в {schema}.{target_table}...")
    engine = create_engine(database_url)

    # Удаление полных дублей
    df = df.drop_duplicates()

    df.to_sql(
        name=target_table,
        con=engine,
        schema=schema,
        if_exists='append',
        index=False, 
        method='multi',
        chunksize=chunksize
    )
    
    print(f"Успешно! Все данные записаны в таблицу.")