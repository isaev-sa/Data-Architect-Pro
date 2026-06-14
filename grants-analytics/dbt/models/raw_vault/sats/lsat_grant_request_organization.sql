{{
    config(
        materialized='incremental',
        schema='raw_vault_grants',
        apply_source_filter = true,
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_lsat_grq_org_composite ON {{ this }} USING btree (link_grant_request_organization_hk, load_datetime DESC)"
            ]
    )
}}

{%- set source_model = "stg_dadata_org_info" -%}

{%- set src_pk = "LINK_GRANT_REQUEST_ORGANIZATION_HK" -%}

{# 
  ВЕДУЩИЙ КЛЮЧ (Driving Key): Теперь это ТОЛЬКО Заявка.
  AutomateDV будет проверять ВСЕХ участников, привязанных к этой заявке.
#}
{%- set src_dfk = ["HUB_GRANT_REQUEST_HK"] -%}

{# 
  ВТОРИЧНЫЙ КЛЮЧ (Secondary Key): Склеенная строка Организация + Роль.
  Если этот составной ключ пропадет из новых данных по заявке, период закроется.
#}
{%- set src_sfk = "ORG_WITH_ROLE_KEY" -%}

{# Колонки дат, настроенные на Шаге 1 #}
{%- set src_start_date = "START_DATE" -%}
{%- set src_end_date = "END_DATE" -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATETIME" -%}
{%- set src_source = "RECORD_SOURCE" -%}


{{ automate_dv.eff_sat(src_pk=src_pk, src_dfk=src_dfk, src_sfk=src_sfk,
                       src_start_date=src_start_date, src_end_date=src_end_date,
                       src_eff=src_eff, src_ldts=src_ldts, src_source=src_source,
                       source_model=source_model) }}