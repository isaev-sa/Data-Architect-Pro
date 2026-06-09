import os
from sqlalchemy import create_engine, text

def execute_ddl_file(file_path: str, db_url: str):
    """
    Читает файл DDL-скрипт и выполняет его в базе данных PostgreSQL.
    """
    # Проверяем существование файла
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Файл с DDL не найден по пути: {file_path}")
        
    # Читаем содержимое SQL-файла
    with open(file_path, 'r', encoding='utf-8') as file:
        ddl_script = file.read()
        
    # Подключаемся к БД и выполняем скрипт
    engine = create_engine(db_url)
    
    with engine.begin() as connection:
        connection.execute(text(ddl_script))
        
    print(f"DDL-скрипт из файла '{file_path}' успешно выполнен.")