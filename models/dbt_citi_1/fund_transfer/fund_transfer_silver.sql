{{
config(
materialized='incremental',
pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'FUND_TRANSFER') }}",
post_hook="{{ audit_post_hook() }}"
)
}}

WITH fund_bronze AS (
SELECT *
FROM {{ ref('fund_transfer_bronze') }}
{% if is_incremental() %}
where ingested_at >(
select coalesce(max(ingested_at),'1900-01-01')
from {{this}}
) 
{%endif%}
),

validated AS (
SELECT *,
CASE
WHEN REGEXP_LIKE(transfer_date, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
THEN TRY_TO_DATE(transfer_date, 'YYYY-MM-DD')
WHEN REGEXP_LIKE(transfer_date, '^[0-9]{4}/[0-9]{2}/[0-9]{2}$')
THEN TRY_TO_DATE(transfer_date, 'YYYY/MM/DD')
WHEN REGEXP_LIKE(transfer_date, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
THEN TRY_TO_DATE(transfer_date, 'DD/MM/YYYY')
ELSE NULL
END AS transfer_date_converted,
TRY_TO_DECIMAL(
    REGEXP_REPLACE(amount, '[^0-9.]', ''),
    18,
    2
) AS amount_cleaned
FROM fund_bronze
),

cleaned as (
select
{{ etrim(['transfer_id', 'account_id', 'customer_id']) }},
amount_cleaned as amount,
transfer_date_converted AS transfer_date,
{{ uptrim(['status', 'transfer_type']) }},
ingested_at
FROM validated
WHERE transfer_date_converted IS NOT NULL
),

dedup as (
select * from cleaned 
qualify row_number () over (partition by transfer_id order by ingested_at desc) =1
),

valid as (
select *,
case 
when transfer_id is null then 'invalid'
when account_id is null then 'invalid'
when customer_id is null then 'invalid'
when status not in (
    'PENDING',
    'COMPLETED',
    'FAILED',
    'CANCELLED') then 'invalid'
else 'valid'
end as status_record

from dedup
)
SELECT

    transfer_id,
    account_id,
    customer_id,
    amount,
   transfer_date,
    status,
    transfer_type,
    ingested_at,
    status_record,
    CURRENT_TIMESTAMP() AS silver_processed_at
from valid
where status_record='valid'
