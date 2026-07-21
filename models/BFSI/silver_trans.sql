{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        schema='silver',
        unique_key='transaction_id',
        alias='sil_transaction'
    )
}}

with sil_trans as (

    select
        transaction_id,
        account_id,
        customer_id,
        branch_id,
        product_id,
        employee_id,
        channel,
        transaction_type,
        transaction_category,
        amount,
        balance_after,
        merchant_category,
        is_fraud_flag,
        status,
        source_system,
        transaction_datetime,
        batch_date,
        ingested_timestamp
    from {{ ref("ts_bronze") }}

    {% if is_incremental() %}
    where ingested_timestamp >
        (select coalesce(max(ingested_timestamp), '1900-01-01')
         from {{ this }})
    {% endif %}

),

dedup as (

    select *,
           row_number() over (
               partition by transaction_id
               order by ingested_timestamp desc
           ) as rnk
    from sil_trans

)

select *
from dedup
where rnk = 1