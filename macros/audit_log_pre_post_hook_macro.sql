{% macro audit_pre_hook(source_name, source_table) %}

INSERT INTO DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
(
    INVOCATION_ID,
    MODEL_NAME,
    SOURCE_TABLE,
    TARGET_TABLE,
    LOAD_TYPE,
    ROWS_IN_SOURCE,
    STATUS,
    START_TIME,
    EXECUTED_BY,
    COMMENTS
)

SELECT
    '{{ invocation_id }}',
    '{{ this.identifier }}',
    '{{ source_name }}.{{ source_table }}',
    '{{ this }}',
    '{% if is_incremental() %}INCREMENTAL{% else %}FULL{% endif %}',
    COUNT(*),
    'RUNNING',
    CURRENT_TIMESTAMP(),
    CURRENT_USER(),
    'Pipeline Started'

FROM {{ source(source_name, source_table) }}

{% if is_incremental() %}
WHERE INGESTED_AT >
(
    SELECT COALESCE(MAX(INGESTED_AT), '1900-01-01')
    FROM {{ this }}
)
{% endif %}
;

{% endmacro %}


{% macro audit_post_hook() %}

UPDATE DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG

SET

    ROWS_PROCESSED =
    (
        SELECT COUNT(*)
        FROM {{ this }}
        WHERE BATCH_ID = '{{ invocation_id }}'
    ),

    STATUS = 'SUCCESS',

    END_TIME = CURRENT_TIMESTAMP(),

    COMMENTS = 'Pipeline Completed'

WHERE INVOCATION_ID = '{{ invocation_id }}';

{% endmacro %}

{{
    config(
        materialized='incremental',
        pre_hook="{{ audit_pre_hook('DBT_Citi_1', 'F_TRANS_L') }}",
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