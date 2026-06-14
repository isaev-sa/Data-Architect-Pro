{{
  config(
        materialized='incremental',
        schema='raw_vault_grants',
        apply_source_filter = true,
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_sat_org_composite ON {{ this }} USING btree (hub_organization_hk, load_datetime DESC)"
            ]
  )
}}

{%- set yaml_metadata -%}
source_model: stg_dadata_org_info
src_pk: hub_organization_hk
src_hashdiff: organization_hashdiff
src_payload:
  - ogrn
  - company_name
  - region
  - city_or_settlement_type
  - city_or_settlement
  - street
  - house
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