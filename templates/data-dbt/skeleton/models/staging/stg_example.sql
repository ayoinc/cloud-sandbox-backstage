{{
    config(
        materialized='view',
        tags=['staging']
    )
}}

with source as (
    select * from {{ source('raw', 'example_table') }}
),

renamed as (
    select
        id,
        -- Add your column transformations here
        created_at,
        updated_at
    from source
)

select * from renamed
