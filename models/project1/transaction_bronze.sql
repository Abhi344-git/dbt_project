{{ config(
materialized='incremental',
database='DBT_PROJECT1',
schema='BRONZE',
pre_hook="
INSERT INTO DBT_PROJECT1.AUDIT.ETL_AUDIT_LOG
(RUN_ID,MODEL_NAME,LAYER,START_TIME,STATUS)
VALUES('{{ invocation_id }}','{{ this.identifier }}','BRONZE',CURRENT_TIMESTAMP(),'RUNNING')
",
post_hook="
UPDATE DBT_PROJECT1.AUDIT.ETL_AUDIT_LOG
SET END_TIME=CURRENT_TIMESTAMP(),
STATUS='SUCCESS',
SOURCE_COUNT=(SELECT COUNT(*) FROM {{ source('DB_Connection','TRANSACTION') }}),
TARGET_COUNT=(SELECT COUNT(*) FROM {{ this }}),
EXECUTION_TIME=DATEDIFF(SECOND,START_TIME,CURRENT_TIMESTAMP())
WHERE RUN_ID='{{ invocation_id }}'
AND MODEL_NAME='{{ this.identifier }}'
"
) }}


SELECT *
FROM {{ source('DB_Connection', 'TRANSACTION') }}

{% if is_incremental() %}

WHERE last_updated_x >
(
    SELECT COALESCE(MAX(last_updated_x), '1990-01-01 00:00:00')
    FROM {{ this }}
)
{% endif %}
