# ${{ values.name }}

${{ values.description }}

## Overview

Operational runbooks for **${{ values.serviceName }}**: incident response and standard procedures, published through Backstage TechDocs.

## Project Structure

```
├── docs/
│   ├── index.md
│   ├── getting-started/      # Overview and on-call guide
│   ├── incidents/            # One runbook per incident type
│   ├── procedures/           # Standard operating procedures
{%- if values.includeTemplates %}
│   └── runbook-templates.md  # Templates for new runbooks
{%- endif %}
├── scripts/
│   └── validate-runbooks.sh  # The checks CI runs on every runbook
├── catalog-info.yaml
└── mkdocs.yml
```

## Runbook Structure

Every incident runbook in `docs/incidents/` must include these sections:

1. **Summary** - What this runbook covers
2. **Symptoms** - How the incident shows up
3. **Impact** - Severity and who is affected
4. **Investigation Steps** - How to find the cause
5. **Resolution Steps** - How to fix it
6. **Verification** - How to confirm the fix
7. **Escalation** - Who to contact

Every procedure in `docs/procedures/` must start with a **Summary**. Each runbook must be listed in the `index.md` of its directory.

## Getting Started

Install [D2](https://d2lang.com/) for the diagrams, then:

```bash
pip install mkdocs-techdocs-core==1.7.1 mkdocs-d2-plugin==1.7.0
mkdocs serve
```

## Continuous Integration

The `Runbook Validation` workflow runs on every push and pull request. It checks each runbook with `scripts/validate-runbooks.sh` and builds the documentation with `mkdocs build --strict`, which also compiles the D2 diagrams.

## Owner

${{ values.owner }}
