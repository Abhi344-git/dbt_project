{% macro etrim(columns) %}

    {% for column in columns %}

        trim({{ column }}) as {{ column }}

        {% if not loop.last %},{% endif %}

    {% endfor %}

{% endmacro %}