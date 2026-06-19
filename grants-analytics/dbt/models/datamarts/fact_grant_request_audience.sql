{{ config(
    materialized='table',
    schema='datamart_grants'
) }}

WITH ranked_sat_project AS (
         SELECT sat_grant_request_project.hub_grant_request_hk,
            sat_grant_request_project.grant_request_project_hashdiff,
            sat_grant_request_project.name,
            sat_grant_request_project.pj_geo,
            sat_grant_request_project.implem_start,
            sat_grant_request_project.implem_end,
            sat_grant_request_project.money_req_grant,
            sat_grant_request_project.cofunding,
            sat_grant_request_project.total_money,
            sat_grant_request_project.is_long_term_project,
            sat_grant_request_project.date_req,
            sat_grant_request_project.link,
            sat_grant_request_project.load_datetime,
            sat_grant_request_project.record_source,
            row_number() OVER (PARTITION BY sat_grant_request_project.hub_grant_request_hk ORDER BY sat_grant_request_project.load_datetime DESC) AS rn
           FROM {{ ref('sat_grant_request_project') }}
        ), ranked_sat_result AS (
         SELECT sat_grant_request_result.hub_grant_request_hk,
            sat_grant_request_result.grant_request_result_hashdiff,
            sat_grant_request_result.winner,
            sat_grant_request_result.rate,
            sat_grant_request_result.money_granted,
            sat_grant_request_result.load_datetime,
            sat_grant_request_result.record_source,
            row_number() OVER (PARTITION BY sat_grant_request_result.hub_grant_request_hk ORDER BY sat_grant_request_result.load_datetime DESC) AS rn
           FROM {{ ref('sat_grant_request_result') }}
        ), ranked_sat_large_attr AS (
         SELECT sat_grant_request_large_attr.hub_grant_request_hk,
            sat_grant_request_large_attr.target_groups,
            row_number() OVER (PARTITION BY sat_grant_request_large_attr.hub_grant_request_hk ORDER BY sat_grant_request_large_attr.load_datetime DESC) AS rn
           FROM {{ ref('sat_grant_request_large_attr') }}
        ), preproc_fact AS (
         SELECT h.hub_grant_request_hk,
            l_org.hub_organization_hk,
            l_reg.hub_region_hk,
            l_cd.hub_contest_hk,
            l_cd.hub_direction_hk,
            s_proj.implem_start,
            s_proj.implem_end,
            s_proj.date_req,
            s_res.rate,
            s_res.winner,
            s_proj.money_req_grant,
            s_proj.cofunding,
            s_proj.total_money,
            s_res.money_granted,
                CASE
                    WHEN category.count_groups_for_grant_request IS NULL OR category.count_groups_for_grant_request = 0 THEN '-1000'::integer
                    ELSE category.category_id
                END AS audience_category_id,
            1.0 /
                CASE
                    WHEN category.count_groups_for_grant_request IS NULL OR category.count_groups_for_grant_request = 0 THEN 1::bigint
                    ELSE category.count_groups_for_grant_request
                END::numeric AS allocation_weight
           FROM {{ ref('hub_grant_request') }} h
             LEFT JOIN {{ ref('link_grant_request_organization') }} l_org ON h.hub_grant_request_hk = l_org.hub_grant_request_hk
             LEFT JOIN {{ ref('link_grant_request_region') }} l_reg ON h.hub_grant_request_hk = l_reg.hub_grant_request_hk
             LEFT JOIN {{ ref('link_grant_request_contest_direction') }} l_cd ON h.hub_grant_request_hk = l_cd.hub_grant_request_hk
             LEFT JOIN ranked_sat_project s_proj ON h.hub_grant_request_hk = s_proj.hub_grant_request_hk AND s_proj.rn = 1
             LEFT JOIN ranked_sat_result s_res ON h.hub_grant_request_hk = s_res.hub_grant_request_hk AND s_res.rn = 1
             LEFT JOIN ranked_sat_large_attr s_large_attr ON h.hub_grant_request_hk = s_large_attr.hub_grant_request_hk AND s_large_attr.rn = 1
             JOIN ( SELECT tg.target_group_id,
                    tg.target_group_text,
                    ac.category_id,
                    ac.category_name,
                    count(*) FILTER (WHERE ac.category_id IS NOT NULL) OVER (PARTITION BY tg.target_group_id) AS count_groups_for_grant_request
                   FROM ml_model.target_groups tg
                     LEFT JOIN ml_model.target_group_category_links l ON l.target_group_id = tg.target_group_id
                     LEFT JOIN ml_model.audience_categories ac ON ac.category_id = l.category_id) category ON s_large_attr.target_groups::text = category.target_group_text
        )
 SELECT hub_grant_request_hk,
    hub_organization_hk,
    hub_region_hk,
    hub_contest_hk,
    hub_direction_hk,
    audience_category_id,
    implem_start,
    implem_end,
    date_req,
    rate,
    winner,
    allocation_weight,
    (money_req_grant * allocation_weight)::numeric(15,2) AS money_req_grant_allocated,
    (cofunding * allocation_weight)::numeric(15,2) AS cofunding_allocated,
    (total_money * allocation_weight)::numeric(15,2) AS total_money_allocated,
    (money_granted * allocation_weight)::numeric(15,2) AS money_granted_allocated
   FROM preproc_fact