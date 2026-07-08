
---configure the table to create schema table in snowflake--
{{config
(materialized='table',
alias="customer_silver1")
}}

--after the creation of customer_silver lets transform the data to showcase only de-duplicated value from ref brz_customer---
with silver_cs_code as(
    select customer_id, first_name, last_name, email, signup_date,
    row_number() over (partition by customer_id order by customer_id) as rnk
    from  {{ ref("cte_code") }}
)
select  customer_id, first_name, last_name, email, signup_date,rnk from silver_cs_code
where rnk=1
