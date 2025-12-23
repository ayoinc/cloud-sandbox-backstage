# dbt Project Template

This template creates a dbt (data build tool) project for data transformation.

## Features

- **Modular models** - Organized SQL transformations
- **Testing** - Data quality tests
- **Documentation** - Auto-generated docs
- **Snapshots** - Track slowly changing dimensions
- **Seeds** - Load CSV reference data

## Prerequisites

- Python 3.8+
- dbt-core
- Database connection (Snowflake, BigQuery, Redshift, etc.)

## Quick Start

```bash
# Install dbt
pip install dbt-core dbt-snowflake

# Install dependencies
dbt deps

# Run models
dbt run

# Test models
dbt test

# Generate docs
dbt docs generate
dbt docs serve
```

## Project Structure

```
├── models/
│   ├── staging/        # Source transformations
│   ├── intermediate/   # Business logic
│   └── marts/          # Final tables
├── tests/              # Custom tests
├── macros/             # Reusable SQL
├── seeds/              # CSV data
├── snapshots/          # SCD tracking
└── dbt_project.yml     # Configuration
```

## Configuration

Update `profiles.yml` with your database credentials:

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: xxx
      user: "{{ env_var('DBT_USER') }}"
      password: "{{ env_var('DBT_PASSWORD') }}"
```

## Support

Contact the Data Engineering Team for assistance.
