{{
    config(
        materialized='incremental',
        pre_hook="{{ audit_pre_hook() }}",
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

FROM {{ source('DBT_Citi_1', 'F_TRANS_L') }}

{% if is_incremental() %}

WHERE INGESTED_AT >
(
    SELECT COALESCE(MAX(INGESTED_AT), '1900-01-01')
    FROM {{ this }}
)

{% endif %}