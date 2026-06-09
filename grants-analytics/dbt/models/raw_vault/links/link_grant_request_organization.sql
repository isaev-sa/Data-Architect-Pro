{{
    config(
        materialized='incremental',
        schema='raw_vault_grants',
        post_hook = [ 
            "CREATE INDEX IF NOT EXISTS idx_lnk_grq_org_pk ON {{ this }} USING btree (link_grant_request_organization_hk)"
            ]
    )
}}

{%- set yaml_metadata -%}
source_model: stg_dadata_org_info
src_pk: link_grant_request_organization_hk
src_fk:
  - hub_grant_request_hk
  - hub_organization_hk
  - role_code
src_ldts: load_datetime
src_source: record_source
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.link(src_pk=metadata_dict["src_pk"],
                    src_fk=metadata_dict["src_fk"], 
                    src_ldts=metadata_dict["src_ldts"],
                    src_source=metadata_dict["src_source"], 
                    source_model=metadata_dict["source_model"]) }}