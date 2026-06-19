from datetime import datetime
from airflow import DAG
from airflow.decorators import task
from airflow.models import Variable
from airflow.providers.postgres.hooks.postgres import PostgresHook
import asyncio
import os

from etl.load_from_dadata import load_from_dadata


#Время запуска 
load_datetime = datetime.now()

with DAG(
    dag_id='load_dadata',
    start_date=datetime(2026, 1, 1),
    schedule='@monthly',
    catchup=False,
    tags=['dbt', 'analytics'],
) as dag:


    # Загрузка данных из dadata
    @task(task_id="load_dadata")
    def load_dadata():
        load_from_dadata_config = Variable.get("load_from_dadata_config", deserialize_json=True)
        hook = PostgresHook(postgres_conn_id="postgres_dwh")
        database_url = hook.get_uri()
        load_from_dadata_config['database_url'] = database_url
        load_from_dadata_config['load_datetime'] = load_datetime

        asyncio.run(load_from_dadata(**load_from_dadata_config))


    load_dadata()