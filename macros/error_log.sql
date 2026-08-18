{% macro audit_error_log() %}
    {% if execute %}
        {% for res in results %}
            {% if res.status == 'error' or res.status == 'fail' %}
                {% set error_insert %}
                    INSERT INTO DBT_CITI_1.AUDIT_LOG.DBT_ERROR_LOG
                    (
                        PIPELINE_NAME,
                        MODEL_NAME,
                        SOURCE_TABLE,
                        TARGET_TABLE,
                        ERROR_MESSAGE,
                        ERROR_TIME,
                        WAREHOUSE_NAME,
                        ROLE_NAME,
                        EXECUTED_BY,
                        STATUS
                    )
                    VALUES
                    (
                        'DBT_CITI_1_PIPELINE',
                        '{{ res.node.name }}',
                        '{{ res.node.schema }}.SOURCE',
                        '{{ res.node.database }}.{{ res.node.schema }}.{{ res.node.name }}',
                        '{{ res.message | replace("'", "''") }}',
                        CURRENT_TIMESTAMP(),
                        CURRENT_WAREHOUSE(),
                        CURRENT_ROLE(),
                        CURRENT_USER(),
                        'FAILED'
                    )
                {% endset %}
                {% do run_query(error_insert) %}

                -- Audit log table mein bhi status FAILED update karo
                {% set audit_update %}
                    UPDATE DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
                    SET
                        END_TIME = CURRENT_TIMESTAMP(),
                        STATUS = 'FAILED',
                        EXECUTION_TIME =
                            LPAD(FLOOR(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()) / 3600), 2, '0') || ':' ||
                            LPAD(FLOOR(MOD(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()), 3600) / 60), 2, '0') || ':' ||
                            LPAD(MOD(DATEDIFF('SECOND', START_TIME, CURRENT_TIMESTAMP()), 60), 2, '0'),
                        COMMENTS = '{{ res.message | replace("'", "''") }}'
                    WHERE MODEL_NAME = '{{ res.node.name }}'
                      AND STATUS = 'RUNNING'
                      AND AUDIT_ID = (
                            SELECT MAX(AUDIT_ID)
                            FROM DBT_CITI_1.AUDIT_LOG.DBT_AUDIT_LOGG
                            WHERE MODEL_NAME = '{{ res.node.name }}'
                      )
                {% endset %}
                {% do run_query(audit_update) %}

                {{ log("Error Logged for model: " ~ res.node.name, info=True) }}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}