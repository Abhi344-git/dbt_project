{{
    config(
        materialized='incremental',
        pre_hook="{{ audit_pre_hook('DBT_CITI_1', 'FUND_TRANSFER') }}",
        post_hook="{{ audit_post_hook() }}"
    )
}}

with fund_bronze as (

    select *
    from {{ ref('fund_transfer_bronze') }}

)

select
    {{ uptrim(['status', 'transfer_type']) }},
    {{ etrim(['transfer_id', 'account_id', 'customer_id']) }},
    
from fund_bronze