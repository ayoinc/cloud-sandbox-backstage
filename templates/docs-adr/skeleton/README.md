# ${{ values.name }}

${{ values.description }}

## Overview

Architecture Decision Record (ADR) documentation following the MADR format.

## Structure

```
├── docs/
│   ├── decisions/
│   │   ├── 0001-record-architecture-decisions.md
│   │   └── template.md
│   └── index.md
└── mkdocs.yml
```

## Creating a New ADR

1. Copy `template.md` to `NNNN-title.md`
2. Fill in the template sections
3. Update status as decisions evolve

## ADR Statuses

- **Proposed**: Under discussion
- **Accepted**: Approved and active
- **Deprecated**: No longer applies
- **Superseded**: Replaced by another ADR

## Template Sections

- Title
- Status
- Context
- Decision
- Consequences

## License

MIT

## Author

${{ values.owner }}
