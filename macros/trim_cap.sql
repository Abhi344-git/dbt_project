{% macro trim_cap(columns) %}

{% for column in columns %}

 initcap(trim{{column}})) as {{column}}

 {% if not loop.last%},{% endif%}

{%endfor%}

{%endmacro%}