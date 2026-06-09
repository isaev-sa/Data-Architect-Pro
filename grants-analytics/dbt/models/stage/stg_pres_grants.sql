{{ config(
    materialized='table',
    schema='stage_grants',
    pre_hook=[
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_ldts",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_hub_grq",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_hub_org",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_hub_cnt",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_lnk_cnt_dir",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_lnk_grq_cnt",
        "DROP INDEX IF EXISTS stage_grants.idx_stg_pres_sat_prj_opt"
    ],
    post_hook=[
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_ldts ON {{ this }} (load_datetime)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_hub_grq ON {{ this }} (hub_grant_request_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_hub_org ON {{ this }} (hub_organization_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_hub_cnt ON {{ this }} (hub_contest_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_lnk_cnt_dir ON {{ this }} (link_contest_direction_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_lnk_grq_cnt ON {{ this }} (link_grant_request_contest_direction_hk)",
        "CREATE INDEX IF NOT EXISTS idx_stg_pres_sat_prj_opt ON {{ this }} (hub_grant_request_hk, load_datetime DESC)"
    ]
) }}

{%- set yaml_metadata -%}

source_model: "v_pres_grants"

derived_columns:

  RECORD_SOURCE: "record_source"
  LOAD_DATETIME: "load_datetime"

hashed_columns:

  HUB_GRANT_REQUEST_HK: "req_num"

  HUB_ORGANIZATION_HK: "inn"

  HUB_REGION_HK: "oktmo"

  HUB_CONTEST_HK:
    - "contest"
    - "year"

  HUB_DIRECTION_HK: "direction"

  LINK_CONTEST_DIRECTION_HK:
    - "contest"
    - "year"
    - "direction"

  LINK_GRANT_REQUEST_CONTEST_DIRECTION_HK:
    - "req_num"
    - "contest"
    - "year"
    - "direction"

  LINK_GRANT_REQUEST_REGION_HK:
    - "req_num"
    - "oktmo"
  
  GRANT_REQUEST_PROJECT_HASHDIFF:
    is_hashdiff: true
    columns:
      - "name"
      - "pj_geo"
      - "implem_start"
      - "implem_end"
      - "money_req_grant"
      - "cofunding"
      - "total_money"
      - "is_long_term_project"
      - "date_req"
      - "link"

  GRANT_REQUEST_LARGE_ATTR_HASHDIFF:
    is_hashdiff: true
    columns:
      - "description"
      - "goal"
      - "tasks"
      - "target_groups"
      - "soc_signif"


  GRANT_REQUEST_RESULT_HASHDIFF:
    is_hashdiff: true
    columns:
      - "winner"
      - "rate"
      - "money_granted"

  REGION_HASHDIFF:
    is_hashdiff: true
    columns:
      - "region"
      - "okato"
      - "level"

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