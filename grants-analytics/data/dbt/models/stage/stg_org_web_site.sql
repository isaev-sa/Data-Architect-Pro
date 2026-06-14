{{ config(
    materialized='table',
    schema='stage_grants',
    pre_hook=[
        "DROP INDEX IF EXISTS stage_grants.idx_stg_web_ldts",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_web_org_hk",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_web_sat_opt"
    ],
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_stg_web_ldts ON {{ this }} (load_datetime)",
        "CREATE INDEX IF NOT EXISTS idx_stg_web_org_hk ON {{ this }} (hub_organization_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_web_sat_opt ON {{ this }} (hub_organization_hk, load_datetime DESC)"
    ]
) }}

{%- set yaml_metadata -%}

source_model: "v_org_web_site"

derived_columns:
  RECORD_SOURCE: "record_source"
  LOAD_DATETIME: "load_datetime"

hashed_columns:

  HUB_GRANT_REQUEST_HK: "req_num"

  HUB_ORGANIZATION_HK: "inn"

  WEB_SITE_HASHDIFF:
    is_hashdiff: true
    columns:
      - "web_site"

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}




{{ automate_dv.stage(
    include_source_columns=true,

    source_model=metadata_dict['source_model'],

    derived_columns=metadata_dict['derived_columns'],

    null_columns=none,

    hashed_columns=metadata_dict['hashed_columns'],

    ranked_columns=none
) }}