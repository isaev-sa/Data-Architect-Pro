{{ config(
    materialization='view',
    schema='raw_stage_grants'
) }}


{# 1. Проверяем существование таблицы в базе данных через адаптер dbt #}
{%- set sat_relation = adapter.get_relation(
      database=this.database,
      schema='raw_vault_grants',
      identifier='sat_grant_request_project'
   ) -%}

{# 2. Флаг: True, если таблица существует #}
{%- set sat_exists = sat_relation is not none -%}

select 
	   pres_grants."name", 
       pres_grants.contest, 
       pres_grants."year",
       TRIM(
        REGEXP_REPLACE(
            replace(direction, ' — долгосрочный проект', ''), 
            '\s+', ' ', 'g')
        ) as direction,
       direction like '%долгосрочный проект%' as  is_long_term_project,
       pres_grants.date_req, 
       pres_grants.region, 
       pres_grants.org, 
       pres_grants.inn, 
       pres_grants.ogrn, 
       pres_grants.implem_start, 
       pres_grants.implem_end,
       pres_grants.winner, 
       pres_grants.rate, 
       pres_grants.cofunding, 
       pres_grants.total_money, 
       pres_grants.description, 
       pres_grants.goal, 
       pres_grants.tasks, 
       pres_grants.soc_signif, 
       pres_grants.pj_geo, 
       pres_grants.target_groups, 
       pres_grants.address, 
       pres_grants.web_site, 
       pres_grants.req_num, 
       pres_grants.link, 
       pres_grants.okato, 
       pres_grants.oktmo, 
       pres_grants."level",
       pres_grants.record_source, 
       pres_grants.load_datetime,
       
    {# Если сателлит уже создан, собираем логику последующих запусков #}
    {% if sat_exists %}
        CASE 
            WHEN pres_grants.winner = FALSE OR pres_grants.winner IS NULL THEN pres_grants.money_req_grant 
            ELSE prev_sat.money_req_grant
        END AS money_req_grant,
    
    {# Если сателлита еще нет, собираем логику ПЕРВОГО запуска #}
    {% else %}
        CASE 
            WHEN pres_grants.winner = FALSE OR pres_grants.winner IS NULL THEN pres_grants.money_req_grant 
            ELSE NULL
        END AS money_req_grant,
    {% endif %}

       CASE WHEN winner = TRUE 
       THEN pres_grants.money_req_grant ELSE NULL 
       END AS money_granted

from raw_stage_grants.pres_grants

{# Присоединяем LATERAL только если таблица физически существует в базе #}
{% if sat_exists %}
LEFT JOIN LATERAL (
    SELECT money_req_grant
    FROM raw_vault_grants.sat_grant_request_project
    WHERE hub_grant_request_hk = md5(coalesce(pres_grants.req_num, ''))::bytea
    ORDER BY load_datetime DESC
    LIMIT 1
) prev_sat ON TRUE
{% endif %}