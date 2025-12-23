{{
    config(
        materialized='table',
        tags=['marts', 'facts']
    )
}}

with processed as (
    select * from {{ ref('int_example_processed') }}
),

final as (
    select
        id,
        created_at,
        updated_at,
        days_since_creation,
        -- Add your fact table columns here
        current_timestamp() as dbt_updated_at
    from processed
)

select * from final
