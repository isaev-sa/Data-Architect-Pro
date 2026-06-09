from datetime import datetime
from airflow import DAG
from airflow.decorators import task
from airflow.models import Variable
from airflow.providers.postgres.hooks.postgres import PostgresHook
import asyncio
import os

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, RenderConfig
from cosmos.constants import LoadMode
from cosmos.profiles import PostgresUserPasswordProfileMapping

from etl.load_from_dadata import load_from_dadata
from etl.load_parquet_to_postgres import load_parquet_to_postgres
from etl.move_file_with_datetime import move_file_with_datetime

#Время запуска 
load_datetime = datetime.now()

# Настройка подключения к базе данных для dbt внутри Airflow
profile_config = ProfileConfig(
    profile_name="dwh",
    target_name="dev",              
    profile_mapping=PostgresUserPasswordProfileMapping(
        conn_id="postgres_dwh",
        profile_args={"schema": "dbt"},
    ),
)


with DAG(
    dag_id='grants_pipeline',
    start_date=datetime(2026, 1, 1),
    schedule='@monthly',
    catchup=False,
    tags=['dbt', 'analytics'],
) as dag:

    # Сенсор на файл
    @task.sensor(poke_interval=30, timeout=600, mode="reschedule")
    def wait_parquet_file():
        file_path = Variable.get("load_grants_config", deserialize_json=True)["parquet_file_path"]
        return os.path.exists(file_path)

    # Загрузка данных в базу
    @task(task_id="load_techno_st")
    def load_techno_st():
        load_grants_config = Variable.get("load_grants_config", deserialize_json=True)
        hook = PostgresHook(postgres_conn_id="postgres_dwh")
        database_url = hook.get_uri()
        load_grants_config['database_url'] = database_url
        load_grants_config['load_datetime'] = load_datetime

        
        load_parquet_to_postgres(**load_grants_config)
    
    # Архивирование файла
    @task(task_id="archive_processed_file")
    def archive_processed_file():
        archive_processed_file_config = Variable.get("archive_processed_file_config", deserialize_json=True)
        archive_processed_file_config['process_time'] = load_datetime

        move_file_with_datetime(**archive_processed_file_config)




    # Загрузка данных из dadata
    @task(task_id="load_dadata")
    def load_dadata():
        load_from_dadata_config = Variable.get("load_from_dadata_config", deserialize_json=True)
        hook = PostgresHook(postgres_conn_id="postgres_dwh")
        database_url = hook.get_uri()
        load_from_dadata_config['database_url'] = database_url
        load_from_dadata_config['load_datetime'] = load_datetime

        asyncio.run(load_from_dadata(**load_from_dadata_config))

    # Генератация тасок dbt
    dbt_transformations = DbtTaskGroup(
        group_id="dbt_analytics_models",
        project_config=ProjectConfig(
            dbt_project_path="/opt/airflow/dbt"
        ),
        profile_config=profile_config,

        render_config=RenderConfig(
            load_method=LoadMode.DBT_LS,
            exclude=["package:dbt_project_evaluator"] 
        )
    )


    load_techno_st_task = load_techno_st()
    wait_parquet_file() >> load_techno_st_task >> load_dadata() >> dbt_transformations
    load_techno_st_task >> archive_processed_file()