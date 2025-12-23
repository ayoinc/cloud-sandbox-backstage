{% macro cents_to_dollars(column_name, precision=2) %}
    round({{ column_name }} / 100.0, {{ precision }})
{% endmacro %}

{% macro safe_divide(numerator, denominator, default=0) %}
    case
        when {{ denominator }} = 0 then {{ default }}
        else {{ numerator }} / {{ denominator }}
    end
{% endmacro %}

{% macro date_spine(start_date, end_date) %}
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=start_date,
        end_date=end_date
    ) }}
{% endmacro %}
