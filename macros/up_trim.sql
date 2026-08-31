{% macro uptrim(columns) %}

    {% for column in columns %}

        trim(upper({{ column }})) as {{ column }}

        {% if not loop.last %},{% endif %}

    {% endfor %}

{% endmacro %}
