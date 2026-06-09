{{
    config(
        materialized='incremental',
        schema='raw_vault_grants',
        apply_source_filter = true,
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS sat_region_hub_region_hk_idx ON {{ this }} USING btree (hub_region_hk, load_datetime DESC)"
            ]
    )
}}


{%- set yaml_metadata -%}
source_model: stg_pres_grants
src_pk: hub_region_hk
src_hashdiff: region_hashdiff
src_payload:
  - region
  - okato
  - level
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