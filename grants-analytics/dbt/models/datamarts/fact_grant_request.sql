{{ config(
    materialized='table',
    schema='datamart_grants'
) }}

WITH ranked_sat_project AS (
    SELECT 
        hub_grant_request_hk,
        grant_request_project_hashdiff,
        name,
        pj_geo,
        implem_start,
        implem_end,
        money_req_grant,
        cofunding,
        total_money,
        is_long_term_project,
        date_req,
        link,
        load_datetime,
        record_source,
        ROW_NUMBER() OVER (
            PARTITION BY hub_grant_request_hk 
            ORDER BY load_datetime DESC
        ) AS rn
    FROM {{ ref('sat_grant_request_project') }}
), 

ranked_sat_result AS (
    SELECT 
        hub_grant_request_hk,
        grant_request_result_hashdiff,
        winner,
        rate,
        money_granted,
        load_datetime,
        record_source,
        ROW_NUMBER() OVER (
            PARTITION BY hub_grant_request_hk 
            ORDER BY load_datetime DESC
        ) AS rn
    FROM {{ ref('sat_grant_request_result') }}
)

SELECT 
    h.hub_grant_request_hk,
    l_org.hub_organization_hk,
    l_reg.hub_region_hk,
    l_cd.hub_contest_hk,
    l_cd.hub_direction_hk,
    s_proj.implem_start,
    s_proj.implem_end,
    s_proj.date_req,
    s_proj.money_req_grant,
    s_proj.cofunding,
    s_proj.total_money,
    s_res.rate,
    s_res.winner,
    s_res.money_granted
FROM {{ ref('hub_grant_request') }} h
LEFT JOIN {{ ref('link_grant_request_organization') }} l_org 
    ON h.hub_grant_request_hk = l_org.hub_grant_request_hk
LEFT JOIN {{ ref('link_grant_request_region') }} l_reg 
    ON h.hub_grant_request_hk = l_reg.hub_grant_request_hk
LEFT JOIN {{ ref('link_grant_request_contest_direction') }} l_cd 
    ON h.hub_grant_request_hk = l_cd.hub_grant_request_hk
LEFT JOIN ranked_sat_project s_proj 
    ON h.hub_grant_request_hk = s_proj.hub_grant_request_hk 
    AND s_proj.rn = 1
LEFT JOIN ranked_sat_result s_res 
    ON h.hub_grant_request_hk = s_res.hub_grant_request_hk 
    AND s_res.rn = 1