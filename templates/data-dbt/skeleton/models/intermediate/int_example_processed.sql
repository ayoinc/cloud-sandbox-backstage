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
        -- The macro expands to the warehouse's date arithmetic, which exceeds the line limit.
        {{ dbt.datediff("created_at", "updated_at", "day") }} as days_since_creation -- noqa: LT05
    from staged
)

select * from processed
