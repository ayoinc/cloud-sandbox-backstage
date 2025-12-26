# ${{ values.name }}

${{ values.description }}

## Overview

dbt (data build tool) project for data transformation and modeling.

## Getting Started

```bash
pip install dbt-core dbt-postgres  # or dbt-snowflake, dbt-bigquery
dbt deps
dbt run
```

## Project Structure

```
├── models/           # SQL models
│   ├── staging/      # Raw data transformations
│   ├── intermediate/ # Business logic
│   └── marts/        # Final tables
├── seeds/            # CSV data files
├── tests/            # Data tests
├── macros/           # Jinja macros
└── dbt_project.yml   # Project config
```

## Commands

- `dbt run` - Run models
- `dbt test` - Run tests
- `dbt build` - Run + test
- `dbt docs generate` - Generate docs
- `dbt docs serve` - Serve docs locally

## Configuration

Edit `dbt_project.yml` and `profiles.yml`.

## License

MIT

## Author

${{ values.owner }}
