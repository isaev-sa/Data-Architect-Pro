{{ config(
    materialization='view',
    schema='raw_stage_grants'
) }}

SELECT 
    p.req_num,
    d.inn_dadata as inn,
    d.ogrn_dadata ogrn,
    'APPLICANT' AS role_code,

    coalesce(
    (d.dadata_response -> 0 -> 'data' -> 'name' ->> 'short_with_opf'),
    (d.dadata_response -> 0 -> 'data' -> 'name' ->> 'full_with_opf')
    ) AS company_name,
    
    --Региональная привязка
    (d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'region_with_type') AS region,
    
    -- Полный тип (например: "город", "село", "деревня", "поселок городского типа")
    COALESCE(
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'city_type_full',
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'settlement_type_full'
    ) AS city_or_settlement_type,
    
    --Город ИЛИ Населенный пункт
    COALESCE(
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'city_with_type',
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'settlement_with_type'
    ) AS city_or_settlement,
    
    -- Улица
    (d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'street_with_type') AS street,
    
    --  Дом
    CONCAT_WS(' ',
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'house_type',
        d.dadata_response -> 0 -> 'data' -> 'address' -> 'data' ->> 'house'
    ) AS house,
    
    d.record_source,
    GREATEST(p.load_datetime, d.load_datetime) AS load_datetime
FROM raw_stage_grants.pres_grants p
JOIN raw_stage_grants.ogr_info_from_dadata d 
    ON  (p.inn = d.old_inn and p.ogrn = d.old_ogrn)
    OR p.inn = d.inn_dadata OR p.ogrn = d.ogrn_dadata
    and d.status = 'success'