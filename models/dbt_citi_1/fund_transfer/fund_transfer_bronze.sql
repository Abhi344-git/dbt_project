{{
    config(
        materialized='incremental',

        pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'FUND_TRANSFER') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

SELECT

    VARIANT_COL:TRANSFER_ID::VARCHAR AS TRANSFER_ID,

    VARIANT_COL:ACCOUNT_ID::VARCHAR AS ACCOUNT_ID,

    VARIANT_COL:CUSTOMER_ID::VARCHAR AS CUSTOMER_ID,

    VARIANT_COL:AMOUNT::VARCHAR AS AMOUNT,

    VARIANT_COL:STATUS::VARCHAR AS STATUS,

    VARIANT_COL:TRANSFER_DATE::VARCHAR AS TRANSFER_DATE,

    VARIANT_COL:TRANSFER_TYPE::VARCHAR AS TRANSFER_TYPE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS INGESTED_AT


FROM {{ source('citi_fact', 'FUND_TRANFER_PARQUE') }}

{% if is_incremental() %}
WHERE CURRENT_TIMESTAMP()::TIMESTAMP_NTZ > (
    SELECT COALESCE(
        MAX(INGESTED_AT),
        '1900-01-01'::TIMESTAMP_NTZ
    )
    FROM {{ this }}
)
{% endif %}