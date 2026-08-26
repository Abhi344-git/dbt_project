{{
    config(
        materialized='incremental',
        database='DBT_CITI_1',
        schema='ACCOUNT_BALANCE',

        pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'ACCOUNT_BALANCE') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

SELECT
    RAW_DATA:BALANCE_ID::VARCHAR       AS BALANCE_ID,
    RAW_DATA:ACCOUNT_ID::VARCHAR       AS ACCOUNT_ID,
    RAW_DATA:BALANCE::VARCHAR          AS BALANCE,
    RAW_DATA:BALANCE_DATE::VARCHAR     AS BALANCE_DATE,
    INGESTED_AT::TIMESTAMP             AS INGESTED_AT

FROM {{ source('citi_fact', 'ACCOUNT_BALANCE_JSON') }}

{% if is_incremental() %}

WHERE INGESTED_AT > (
    SELECT COALESCE(
        MAX(INGESTED_AT),
        '1900-01-01'::TIMESTAMP
    )
    FROM {{ this }}
)

{% endif %}