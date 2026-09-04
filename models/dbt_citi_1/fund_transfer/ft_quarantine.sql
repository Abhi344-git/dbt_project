{{
config(
    materialized='incremental',
    pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'ft_quarantine') }}",
    post_hook="{{ audit_post_hook() }}"
)
}}

WITH fund_bronze AS (

    SELECT *
    FROM {{ ref('fund_transfer_bronze') }}

    {% if is_incremental() %}

    WHERE ingested_at > (
        SELECT COALESCE(MAX(ingested_at), '1900-01-01')
        FROM {{ this }}
    )

    {% endif %}
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
        END AS transfer_date_converted,

     TRY_TO_DECIMAL(
            REGEXP_REPLACE(amount, '[^0-9.]', ''),
            18,
            2
        ) AS amount_cleaned


    FROM fund_bronze
),

cleaned AS (

    SELECT

        {{ etrim(['transfer_id', 'account_id', 'customer_id']) }},

        -- ORIGINAL VALUES
        amount AS amount_original,
        transfer_date AS transfer_date_original,

        -- CLEANED VALUES
        amount_cleaned,
        transfer_date_converted AS transfer_date_cleaned,

        -- OTHER CLEANED COLUMNS
        {{ uptrim(['status', 'transfer_type']) }},

        ingested_at

    FROM validated
),

dedup AS (

    SELECT *
    FROM cleaned

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY transfer_id
        ORDER BY ingested_at DESC
    ) = 1
),

valid AS (

    SELECT
        *,

        CASE
            WHEN transfer_id IS NULL THEN 'invalid'
            WHEN account_id IS NULL THEN 'invalid'
            WHEN customer_id IS NULL THEN 'invalid'
            WHEN transfer_date_cleaned IS NULL THEN 'invalid'
            WHEN amount_cleaned IS NULL THEN 'invalid'
            WHEN status NOT IN (
                'PENDING',
                'COMPLETED',
                'FAILED',
                'CANCELLED'
            ) THEN 'invalid'
            ELSE 'valid'
        END AS status_record,

        CASE
            WHEN transfer_id IS NULL
                THEN 'MISSING_TRANSFER_ID'

            WHEN account_id IS NULL
                THEN 'MISSING_ACCOUNT_ID'

            WHEN customer_id IS NULL
                THEN 'MISSING_CUSTOMER_ID'

            WHEN transfer_date_cleaned IS NULL
                THEN 'INVALID_TRANSFER_DATE'

            WHEN amount_cleaned IS NULL
                THEN 'INVALID_AMOUNT'

            WHEN status NOT IN (
                'PENDING',
                'COMPLETED',
                'FAILED',
                'CANCELLED'
            )
                THEN 'INVALID_STATUS'

            ELSE NULL
        END AS invalid_reason

    FROM dedup
)

SELECT

    transfer_id,
    account_id,
    customer_id,

    -- ORIGINAL VALUES
    amount_original,
    amount_cleaned,
    transfer_date_original,

    -- CLEANED VALUES
    
    transfer_date_cleaned, 
    status,
    transfer_type,
    ingested_at,

    status_record,
    invalid_reason,

    CURRENT_TIMESTAMP() AS quarantine_processed_at

FROM valid

WHERE status_record = 'invalid'