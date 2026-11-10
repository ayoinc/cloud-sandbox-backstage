# ${{ values.name }}

${{ values.description }}

## Overview

Architecture Decision Records (ADRs) for this project, written in the {% if values.adrFormat == 'nygard' %}Nygard{% elif values.adrFormat == 'custom' %}custom{% else %}MADR{% endif %} format and published through Backstage TechDocs.

## Structure

```
├── docs/
│   ├── adrs/
│   │   ├── index.md              # Index of all ADRs
│   │   └── 001-use-adrs.md       # One file per decision
│   ├── templates/
│   │   └── adr-template.md       # Copy this to start a new ADR
│   ├── index.md
│   ├── process.md
│   └── templates.md
├── scripts/
│   └── validate-adrs.sh          # The checks CI runs on every ADR
├── catalog-info.yaml
└── mkdocs.yml
```

## Creating a New ADR

1. Copy `docs/templates/adr-template.md` to `docs/adrs/NNN-short-title.md`
2. Fill in the template sections
3. Add the ADR to `docs/adrs/index.md` and to the `nav` in `mkdocs.yml`
4. Run `bash scripts/validate-adrs.sh` and open a pull request

## ADR Statuses

- **Proposed**: Under discussion
- **Accepted**: Approved and active
- **Rejected**: Reviewed and not approved
- **Deprecated**: No longer applies
- **Superseded**: Replaced by another ADR

## Continuous Integration

The `ADR Validation` workflow runs on every push and pull request. It checks each ADR with `scripts/validate-adrs.sh` and builds the documentation with `mkdocs build --strict`, which also compiles the D2 diagrams.

To build the documentation locally, install [D2](https://d2lang.com/) and run:

```bash
pip install mkdocs-techdocs-core==1.7.1 mkdocs-d2-plugin==1.7.0
mkdocs build --strict
```

## Owner

${{ values.owner }}
