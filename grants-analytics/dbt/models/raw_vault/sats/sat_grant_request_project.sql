{{
    config(
        materialized='incremental',
        schema='raw_vault_grants',
        apply_source_filter = true,
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_sat_grq_prj_composite ON {{ this }} USING btree (hub_grant_request_hk, load_datetime DESC)"
            ]
    )
}}

{%- set yaml_metadata -%}
source_model: stg_pres_grants
src_pk: hub_grant_request_hk
src_hashdiff: grant_request_project_hashdiff
src_payload:
  - name
  - pj_geo
  - implem_start
  - implem_end
  - money_req_grant
  - cofunding
  - total_money
  - is_long_term_project
  - date_req
  - link
src_ldts: load_datetime
src_source: record_source
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"])   }}