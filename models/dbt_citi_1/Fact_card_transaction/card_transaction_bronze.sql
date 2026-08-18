{{
    config(
        materialized='incremental',
        database='DBT_CITI_1',
        schema='CARD_TRANSACTION',
        pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'CARD_TRANSACTION') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

SELECT
    *,
    CURRENT_TIMESTAMP() AS INGESTED_AT,
    '{{ invocation_id }}' AS BATCH_ID

FROM {{ source('citi_fact', 'CARD_TRANSACTION') }}

{% if is_incremental() %}

WHERE TXN_DATE >
(
    SELECT COALESCE(MAX(TXN_DATE), '1900-01-01')
    FROM {{ this }}
)

{% endif %}