{% macro audit_pre_hook() %}
    {% if execute %}
        {% set batch_id_query %}
            SELECT DBT_CITI_1.AUDIT_LOG.DBT_BATCH_SEQ.NEXTVAL
        {% endset %}
        {% set results = run_query(batch_id_query) %}
        {% set batch_id = results.columns[0].values()[0] %}

        {% set start_time_query %}
            SELECT CURRENT_TIMESTAMP()
        {% endset %}
        {% set start_results = run_query(start_time_query) %}
        {% set start_time = start_results.columns[0].values()[0] %}

        -- Variables ko dbt ke context mein store karo taaki post_hook mein use ho sakein
        {% do var('audit_batch_id', batch_id) %}

        {{ log("Audit Pre-Hook: Batch ID = " ~ batch_id ~ " | Start Time = " ~ start_time, info=True) }}

        INSERT INTO DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
        (
            BATCH_ID, PIPELINE_NAME, MODEL_NAME, SOURCE_TABLE, TARGET_TABLE,
            LOAD_TYPE, STATUS, START_TIME, WAREHOUSE_NAME, ROLE_NAME, EXECUTED_BY, COMMENTS
        )
        VALUES
        (
            {{ batch_id }},
            'DBT_CITI_1_PIPELINE',
            '{{ this.name }}',
            '{{ this.schema }}.SOURCE',
            '{{ this }}',
            'INCREMENTAL',
            'RUNNING',
            '{{ start_time }}',
            CURRENT_WAREHOUSE(),
            CURRENT_ROLE(),
            CURRENT_USER(),
            'Model run started'
        )
    {% endif %}
{% endmacro %}


{% macro audit_post_hook() %}
    {% if execute %}
        {% set update_query %}
            UPDATE DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
            SET
                END_TIME = CURRENT_TIMESTAMP(),
                STATUS = 'SUCCESS',
                ROWS_AFFECTED = (SELECT COUNT(*) FROM {{ this }}),
                EXECUTION_TIME =
                    LPAD(FLOOR(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()) / 3600), 2, '0') || ':' ||
                    LPAD(FLOOR(MOD(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()), 3600) / 60), 2, '0') || ':' ||
                    LPAD(MOD(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()), 60), 2, '0'),
                COMMENTS = 'Model run completed successfully'
            WHERE MODEL_NAME = '{{ this.name }}'
              AND STATUS = 'RUNNING'
              AND AUDIT_ID = (
                    SELECT MAX(AUDIT_ID)
                    FROM DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
                    WHERE MODEL_NAME = '{{ this.name }}'
              )
        {% endset %}
        {% do run_query(update_query) %}
        {{ log("Audit Post-Hook: Execution completed for model " ~ this.name, info=True) }}
    {% endif %}
{% endmacro %}