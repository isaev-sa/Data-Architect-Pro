{{
    config(
        materialized='incremental',
        schema='raw_vault_grants',
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_hub_cnt_pk ON {{ this }} USING btree (hub_contest_hk)"
            ]
    )
}}

{%- set yaml_metadata -%}
source_model: stg_pres_grants
src_pk: hub_contest_hk
src_nk:
  - contest
  - year
src_ldts: load_datetime
src_source: record_source
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}