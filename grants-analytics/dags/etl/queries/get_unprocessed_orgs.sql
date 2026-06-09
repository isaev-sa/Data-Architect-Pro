SELECT distinct c.inn, c.ogrn 
FROM raw_stage_grants.pres_grants c
LEFT JOIN raw_stage_grants.ogr_info_from_dadata r 
ON    (c.inn  = r.old_inn and c.ogrn = r.old_ogrn) 
    or c.inn  = r.inn_dadata
    or c.ogrn = r.ogrn_dadata
WHERE r.id IS NULL OR r.status = 'error'
LIMIT $1;