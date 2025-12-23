-- Test that all IDs in fct_example exist in dim_example
select
    f.id
from {{ ref('fct_example') }} f
left join {{ ref('dim_example') }} d on f.id = d.id
where d.id is null
