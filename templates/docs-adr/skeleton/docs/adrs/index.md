# Architecture Decision Records

This directory contains all Architecture Decision Records for the project.

## ADR Index

|#|Title|Status|Date|
|---|---|---|---|
|[001](001-use-adrs.md)|Use ADRs for Architecture Decisions|Accepted|2024-01-01|
{%- if values.includeExamples %}
|[002](002-example-decision.md)|Example Decision|Proposed|2024-01-15|
{%- endif %}

## Categories

{% for category in values.categories -%}
### ${{ category | capitalize }}

{% if category == 'architecture' -%}
- [001 - Use ADRs](001-use-adrs.md)
{%- else -%}
_No ADRs yet_
{%- endif %}

{% endfor -%}

## Creating a New ADR

1. Determine the next ADR number
2. Copy the template: `cp ../templates/adr-template.md NNN-title.md`
3. Fill in the sections
4. Add to the index above
5. Submit a pull request
