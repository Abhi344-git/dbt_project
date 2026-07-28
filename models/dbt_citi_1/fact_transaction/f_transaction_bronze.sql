{{
    config(
        materialized='incremental',
        unique_key='TRANSACTION_ID',
        incremental_strategy='merge',

        pre_hook="{{ audit_pre_hook('raw_transactions','transaction_raw') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

SELECT

    TRANSACTION_ID,
    CUSTOMER_ID,
    BRANCH_ID,
    AMOUNT,
    TRANSACTION_TYPE,
    TRANSACTION_DATE,
    CURRENCY,

    CURRENT_TIMESTAMP() AS INGESTED_AT,
    '{{ invocation_id }}' AS BATCH_ID

FROM {{ source('raw_transactions', 'transaction_raw') }}