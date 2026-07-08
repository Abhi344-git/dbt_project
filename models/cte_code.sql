{{ config(materialized="table", alias="customer_brz") }}
with
    cte_customer_bronze as (
        select customer_id, first_name, last_name, email, signup_date, last_updated
        from {{ source("DB_Connection","customer") }}
        where first_name is not null and email is not null
    )

select customer_id, first_name, last_name, email, signup_date
from cte_customer_bronze

