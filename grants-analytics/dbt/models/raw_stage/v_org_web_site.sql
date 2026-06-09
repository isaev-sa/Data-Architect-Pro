{{ config(
    materialization='view',
    schema='raw_stage_grants'
) }}

SELECT 
    p.req_num,
    d.inn_dadata as inn,
    p.web_site,
    p.record_source,
    GREATEST(p.load_datetime, d.load_datetime) AS load_datetime
FROM raw_stage_grants.pres_grants p
JOIN raw_stage_grants.ogr_info_from_dadata d 
    ON  (p.inn = d.old_inn and p.ogrn = d.old_ogrn)
    OR p.inn = d.inn_dadata OR p.ogrn = d.ogrn_dadata
    and d.status = 'success'
where web_site is not null