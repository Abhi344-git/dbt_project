{% macro clean(column_name)%}
 initcap(trim({{column_name}}))
{% endmacro %}

