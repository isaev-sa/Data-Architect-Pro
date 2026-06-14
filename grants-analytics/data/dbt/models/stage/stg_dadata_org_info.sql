{{ config(
    materialized='table',
    schema='stage_grants',
    pre_hook=[
        "DROP INDEX IF EXISTS stage_grants.idx_stg_dadata_org_ldts",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_dadata_org_hk",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_dadata_lnk_hk",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_dadata_org_sat_opt"
    ],
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_stg_dadata_org_ldts ON {{ this }} (load_datetime)",
        "CREATE INDEX IF NOT EXISTS idx_stg_dadata_org_hk ON {{ this }} (hub_organization_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_dadata_lnk_hk ON {{ this }} (link_grant_request_organization_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_dadata_org_sat_opt ON {{ this }} (hub_organization_hk, load_datetime DESC)"
    ]
) }}

{%- set yaml_metadata -%}

source_model: "v_dadata_org_info"

derived_columns:

  RECORD_SOURCE: "record_source"
  LOAD_DATETIME: "load_datetime"
  ORG_WITH_ROLE_KEY: "inn || '_' || role_code"
  START_DATE: "load_datetime"
  EFFECTIVE_FROM: "load_datetime"
  END_DATE: "CAST('9999-12-31 23:59:59' AS TIMESTAMP)"

hashed_columns:

  HUB_GRANT_REQUEST_HK: "req_num"

  HUB_ORGANIZATION_HK: "inn"

  LINK_GRANT_REQUEST_ORGANIZATION_HK:
    - "inn"
    - "req_num"
    - "role_code"

  ORGANIZATION_HASHDIFF:
    is_hashdiff: true
    columns:
      - "ogrn"
      - "company_name"
      - "region"
      - "city_or_settlement_type"
      - "city_or_settlement"
      - "street"
      - "house"

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