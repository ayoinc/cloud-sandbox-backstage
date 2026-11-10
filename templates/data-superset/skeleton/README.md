# ${{ values.name }}

${{ values.description }}

## Overview

Apache Superset dashboard, charts, datasets and database connection kept as
JSON, with scripts to validate them and to import them into Superset.

## Getting Started

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt

# Check the asset files (no Superset needed)
python -m scripts.validate
pytest
```

## Project Structure

```
├── dashboards/           # Dashboard definitions
├── charts/               # Chart definitions
├── datasets/             # Dataset definitions
├── databases/            # Database connection (${{ values.dataSource }})
├── scripts/
│   ├── validate.py       # Validate assets
│   ├── import.py         # Import assets into Superset
│   └── export.py         # Export the dashboard from Superset
└── tests/                # Tests for validation and import
```

## Importing and Exporting

```bash
export SUPERSET_URL=http://localhost:8088
export SUPERSET_USERNAME=admin
export SUPERSET_PASSWORD=admin
# SQLAlchemy URI of the data source; needed to create the database connection
export SUPERSET_DATABASE_URI=postgresql://user:password@host:5432/database

python -m scripts.import
python -m scripts.export
```

Connection strings are never stored in `databases/`; the validation rejects
files that contain credentials.

## Pipeline

`.github/workflows/superset.yaml` validates the assets, runs the tests and
lints the scripts on every push and pull request. On `main` it also imports the
assets into Superset once `SUPERSET_URL`, `SUPERSET_USERNAME` and
`SUPERSET_PASSWORD` are set as repository secrets; until then the deployment is
skipped.

## License

MIT

## Author

${{ values.owner }}
