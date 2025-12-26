# ${{ values.name }}

${{ values.description }}

## Overview

Operational runbook documentation for incident response and procedures.

## Project Structure

```
├── docs/
│   ├── index.md
│   ├── incidents/
│   └── procedures/
└── mkdocs.yml
```

## Runbook Template

Each runbook should include:

1. **Overview** - What this runbook covers
2. **Prerequisites** - Required access/tools
3. **Steps** - Numbered procedures
4. **Troubleshooting** - Common issues
5. **Escalation** - Who to contact

## Getting Started

```bash
pip install mkdocs mkdocs-techdocs-core
mkdocs serve
```

## License

MIT

## Author

${{ values.owner }}
