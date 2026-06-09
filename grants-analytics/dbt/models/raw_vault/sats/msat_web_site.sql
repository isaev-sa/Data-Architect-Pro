{{
  config(
        materialized='incremental',
        schema='raw_vault_grants',
        apply_source_filter = true,
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_sat_web_composite ON {{ this }} USING btree (hub_organization_hk, load_datetime DESC)"
            ]
  )
}}

{%- set yaml_metadata -%}
source_model: stg_org_web_site
src_pk: hub_organization_hk
src_cdk:
  - web_site
src_hashdiff: web_site_hashdiff
src_payload: []
src_ldts: load_datetime
src_source: record_source
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.ma_sat(src_pk=metadata_dict["src_pk"],
                      src_cdk=metadata_dict["src_cdk"],
                      src_hashdiff=metadata_dict["src_hashdiff"],
                      src_payload=metadata_dict["src_payload"],
                      src_ldts=metadata_dict["src_ldts"],
                      src_source=metadata_dict["src_source"],
                      source_model=metadata_dict["source_model"]) }}