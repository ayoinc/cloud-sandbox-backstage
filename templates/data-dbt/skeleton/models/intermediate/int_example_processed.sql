{{
    config(
        materialized='table',
        tags=['intermediate']
    )
}}

with staged as (
    select * from {{ ref('stg_example') }}
),

processed as (
    select
        id,
        -- Add your intermediate transformations here
        created_at,
        updated_at,
        -- Example: Add derived columns
        datediff('day', created_at, updated_at) as days_since_creation
    from staged
)

select * from processed
