{{config
(materialized='table',
alias="customer_gold")
}}

select customer_id, first_name, last_name, email, signup_date
from  {{ ref("silver_customer") }}
where signup_date> '2022-01-15'
