{{config(materialized="incremental",schema='bronze',alias="bronze_transaction",
pre_hook="delete from  DBT.AUDIT_log.etl_log where etl_pipe='{{model.name}}'",
post_hook="insert into  DBT.AUDIT_log.etl_log(etl_pipe,loa_date)
values('{{model.name}}',current_timestamp())")
}}

with brz_ts as (
    select  transaction_id,account_id,customer_id,branch_id,product_id,employee_id,channel,transaction_type,transaction_category,amount,balance_after,
    merchant_category,is_fraud_flag,status,source_system,transaction_datetime,batch_date,ingested_timestamp
from {{source('DB_Connection','transaction')}}
)
select  transaction_id,account_id,customer_id,branch_id,product_id,employee_id,channel,transaction_type,transaction_category,amount,balance_after,
    merchant_category,is_fraud_flag,status,source_system,transaction_datetime,batch_date,ingested_timestamp
    from brz_ts


