{{ config(
    materialization='view',
    schema='datamart_grants'
) }}

WITH ranked_sat AS (
    SELECT 
        hub_organization_hk,
        organization_hashdiff,
        ogrn,
        company_name,
        region,
        city_or_settlement_type,
        city_or_settlement,
        street,
        house,
        load_datetime,
        record_source,
        ROW_NUMBER() OVER (
            PARTITION BY hub_organization_hk 
            ORDER BY load_datetime DESC
        ) AS rn
    
    FROM {{ ref('sat_organization') }}
)
SELECT 
    h.hub_organization_hk,
    h.inn AS ogrn,
    s.company_name,
    s.region,
    s.city_or_settlement_type,
    s.city_or_settlement,
    s.street,
    s.house

FROM {{ ref('hub_organization') }} h
LEFT JOIN ranked_sat s 
    ON h.hub_organization_hk = s.hub_organization_hk 
    AND s.rn = 1