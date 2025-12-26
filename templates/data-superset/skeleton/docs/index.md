# ${{ values.name }}

${{ values.description }}

## Overview

This is an Apache Superset dashboard configuration project.

| Property        | Value                     |
| --------------- | ------------------------- |
| **Owner**       | ${{ values.owner }}       |
| **Environment** | ${{ values.environment }} |
| **Data Source** | ${{ values.dataSource }}  |

## Quick Start

### Prerequisites

- Apache Superset instance running
- Access to ${{ values.dataSource }} database
- Superset CLI (`pip install apache-superset`)

### Import Dashboard

```bash
# Export environment variables
export SUPERSET_URL=http://localhost:8088
export SUPERSET_USERNAME=admin
export SUPERSET_PASSWORD=admin

# Import assets
python scripts/import.py
```

### Export Dashboard

```bash
# Export current dashboard state
python scripts/export.py
```

## Project Structure

```
.
├── dashboards/           # Dashboard JSON exports
├── charts/              # Chart configurations
├── datasets/            # Dataset/table definitions
├── databases/           # Database connection configs
├── scripts/             # Import/export scripts
└── docs/                # Documentation
```

## Development Workflow

1. **Make changes in Superset UI**
2. **Export changes**: `python scripts/export.py`
3. **Commit changes**: `git add . && git commit -m "Update dashboard"`
4. **Deploy to production**: CI/CD will auto-import on merge to main

## Data Sources

This dashboard uses ${{ values.dataSource }} as its primary data source.

Configure the connection string in `databases/${{ values.dataSource }}.json`.
