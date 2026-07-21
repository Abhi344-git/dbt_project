{{ config(
materialized='incremental',
database='DBT_PROJECT1',
schema='transaction') }}

WITH clean_data AS (

    SELECT
        customer_id,
        TRIM(INITCAP(first_name)) AS first_name,
        TRIM(INITCAP(last_name)) AS last_name,
        LOWER(TRIM(email)) AS email,
        signup_date,
        transaction_date,
        last_updated_x,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY last_updated_x DESC
        ) AS rnk

    FROM {{ ref('transaction_bronze') }}

    WHERE customer_id IS NOT NULL

    {% if is_incremental() %}
        AND last_updated_x >
        (
            SELECT COALESCE(
                MAX(last_updated_x),
                TO_TIMESTAMP('1999-01-01 00:00:00')
            )
            FROM {{ this }}
        )
    {% endif %}

)  

SELECT *
FROM clean_data
WHERE rnk = 1