# ${{ values.name }}

${{ values.description }}

## Overview

dbt (data build tool) project for data transformation and modeling.

## Getting Started

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements-ci.txt
export DBT_PROFILES_DIR=$(pwd)

# Build and test on a local DuckDB database; no warehouse needed
dbt deps
dbt seed
dbt build --exclude resource_type:seed
```

To run against ${{ values.warehouse }}, install `requirements.txt`, set the
environment variables named in `profiles.yml` and pass `--target ${{ values.environment }}`.

## Project Structure

```
├── models/           # SQL models
│   ├── staging/      # Raw data transformations
│   ├── intermediate/ # Business logic
│   └── marts/        # Final tables
├── seeds/            # Sample source data for the ci target
├── tests/            # Data tests
├── macros/           # Jinja macros
├── profiles.yml      # Connection profiles (no credentials)
└── dbt_project.yml   # Project config
```

## Pipeline

`.github/workflows/dbt.yaml` lints the SQL with sqlfluff and builds and tests
the models on DuckDB on every push and pull request, with no secrets. The
deploy job runs `dbt build` on ${{ values.warehouse }} and is skipped until the warehouse
secrets are set. See `docs/index.md`.

## Commands

- `dbt run` - Run models
- `dbt test` - Run tests
- `dbt build` - Run + test
- `dbt docs generate` - Generate docs
- `dbt docs serve` - Serve docs locally

## Configuration

Edit `dbt_project.yml` and `profiles.yml`. Connection values are read from environment variables; never commit credentials.

## License

MIT

## Author

${{ values.owner }}
