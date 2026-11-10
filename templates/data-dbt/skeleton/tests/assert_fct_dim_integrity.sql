-- Test that all IDs in fct_example exist in dim_example
select fct.id
from {{ ref('fct_example') }} as fct
left join {{ ref('dim_example') }} as dim on fct.id = dim.id
where dim.id is null
