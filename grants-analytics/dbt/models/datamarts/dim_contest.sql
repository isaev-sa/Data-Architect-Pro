{{ config(
    materialized='table',
    schema='datamart_grants'
) }}

SELECT hub_contest_hk,
    contest,
    year
   FROM {{ ref('hub_contest') }} h