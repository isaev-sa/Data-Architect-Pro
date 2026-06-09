{{ config(materialized='table', schema='raw_vault_grants') }}

SELECT 'APPLICANT' AS role_code, 'Заявитель' AS role_name
UNION ALL
SELECT 'PARTNER', 'Партнер'