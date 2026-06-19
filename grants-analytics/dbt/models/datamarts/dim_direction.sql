{{ config(
    materialized='table',
    schema='datamart_grants'
) }}

SELECT hub_direction_hk,
    direction
   FROM {{ ref('hub_direction') }} h