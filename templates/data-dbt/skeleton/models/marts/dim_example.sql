{{
    config(
        materialized='table',
        tags=['marts', 'dimensions']
    )
}}

with source as (
    select * from {{ ref('stg_example') }}
),

final as (
    select
        id,
        -- Add your dimension attributes here
        created_at as first_seen_at,
        current_timestamp() as dbt_updated_at
    from source
)

select * from final
