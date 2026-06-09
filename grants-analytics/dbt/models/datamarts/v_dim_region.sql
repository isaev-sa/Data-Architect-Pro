{{ config(
    materialization='view',
    schema='datamart_grants'
) }}

WITH ranked_sat AS (
    SELECT 
        hub_region_hk,
        region_hashdiff,
        region,
        okato,
        level,
        load_datetime,
        record_source,
        ROW_NUMBER() OVER (
            PARTITION BY hub_region_hk 
            ORDER BY load_datetime DESC
        ) AS rn
    
    FROM {{ ref('sat_region') }}
)
SELECT 
    h.hub_region_hk,
    s.region,
    s.okato,
    s.level

FROM {{ ref('hub_region') }} h
LEFT JOIN ranked_sat s 
    ON h.hub_region_hk = s.hub_region_hk 
    AND s.rn = 1