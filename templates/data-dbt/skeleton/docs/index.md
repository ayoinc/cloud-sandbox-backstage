# ${{ values.name }}

${{ values.description }}

## Overview

This is a dbt project for data transformation following best practices.

| Property | Value |
|----------|-------|
| **Owner** | ${{ values.owner }} |
| **Environment** | ${{ values.environment }} |
| **Warehouse** | ${{ values.warehouse }} |
| **dbt Version** | ${{ values.dbtVersion }} |

## Quick Start

### Setup

1. **Install dbt**:
   ```bash
   pip install dbt-${{ values.warehouse }}==${{ values.dbtVersion }}.*
   ```

2. **Configure profiles.yml**:
   ```bash
   cp profiles.yml.example ~/.dbt/profiles.yml
   # Edit with your credentials
   ```

3. **Install packages**:
   ```bash
   dbt deps
   ```

### Running dbt

```bash
# Run all models
dbt run

# Run specific models
dbt run --select staging
dbt run --select marts.fct_example+

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Project Structure

```
.
├── models/
│   ├── staging/          # Cleaned source data
│   ├── intermediate/     # Business logic
│   └── marts/           # Final fact/dim tables
├── macros/              # Reusable SQL functions
├── tests/               # Custom data tests
├── seeds/               # Static CSV data
├── snapshots/           # SCD Type 2 tables
└── analyses/            # Ad-hoc queries
```

## Data Lineage

```
sources -> staging -> intermediate -> marts
```

## Testing Strategy

- **Schema tests**: Defined in YAML files
- **Data tests**: Custom SQL in tests/
- **Unit tests**: Using dbt_expectations package
