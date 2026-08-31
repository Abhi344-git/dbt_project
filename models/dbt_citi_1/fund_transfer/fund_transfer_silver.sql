{{
    config(
        materialized='incremental',
        pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'FUND_TRANSFER') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

with fund_bronze as (

    select *
    from {{ ref('fund_transfer_bronze') }}

)

select
    {{ etrim(['transfer_id', 'account_id', 'customer_id']) }},
    amount,
    regexp_replace (transfer_date,'^99/','9/'),
    {{ uptrim(['status', 'transfer_type']) }},
    ingested_at

from fund_bronze

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

),

validated AS (

    SELECT
        *,
        CASE
            WHEN REGEXP_LIKE(
                transfer_date,
                '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            )
                THEN TRY_TO_DATE(transfer_date, 'YYYY-MM-DD')

            WHEN REGEXP_LIKE(
                transfer_date,
                '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
            )
                THEN TRY_TO_DATE(transfer_date, 'YYYY/MM/DD')

            WHEN REGEXP_LIKE(
                transfer_date,
                '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            )
                THEN TRY_TO_DATE(transfer_date, 'DD/MM/YYYY')

            ELSE NULL
        END AS transfer_date_converted

    FROM fund_bronze

)

SELECT
    {{ etrim(['transfer_id', 'account_id', 'customer_id']) }},
    amount,
    transfer_date_converted AS transfer_date,
    {{ uptrim(['status', 'transfer_type']) }},
    ingested_at

FROM validated

WHERE transfer_date_converted IS NOT NULL