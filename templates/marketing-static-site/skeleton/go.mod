module github.com/${{ values.destination.owner }}/${{ values.destination.repo }}

go 1.21

{% if values.hugoTheme == 'ananke' -%}
require github.com/gohugo-ananke/ananke/v2 v2.19.1
{%- elif values.hugoTheme == 'papermod' -%}
require github.com/adityatelange/hugo-PaperMod v0.0.0-20261025062351-118119693d8b
{%- elif values.hugoTheme == 'terminal' -%}
require github.com/panr/hugo-theme-terminal/v4 v4.2.6
{%- elif values.hugoTheme == 'minimal' -%}
require github.com/calintat/minimal v0.0.0-20210103220336-987f270dfee3
{%- endif %}
