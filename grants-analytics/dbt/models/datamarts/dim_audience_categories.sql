{{ config(
    materialized='table',
    schema='datamart_grants'
) }}

SELECT audience_categories.category_id,
    audience_categories.category_name,
    audience_categories.category_description,
    audience_categories.keywords
   FROM ml_model.audience_categories
UNION
 SELECT '-1000'::integer AS category_id,
    'Остальные'::text AS category_name,
    ''::text AS category_description,
    ''::text AS keywords