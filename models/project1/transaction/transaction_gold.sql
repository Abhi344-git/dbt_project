{{ config(materialized='table') }}

select *
from {{ ref('transaction_silver') }}