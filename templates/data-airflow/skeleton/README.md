# ${{ values.name }}

${{ values.description }}

## Overview

Apache Airflow DAGs for data pipeline orchestration.

## Getting Started

```bash
python -m venv venv && source venv/bin/activate

# Install Airflow and the development tools with the Airflow constraints
export PIP_CONSTRAINT="https://raw.githubusercontent.com/apache/airflow/constraints-3.4.0/constraints-3.12.txt"
pip install -r requirements-dev.txt

# Run Airflow locally
export AIRFLOW_HOME=$(pwd)/.airflow
export AIRFLOW__CORE__DAGS_FOLDER=$(pwd)/dags
airflow standalone
```

Access UI at [http://localhost:8080](http://localhost:8080)

## Project Structure

```
├── dags/                  # Airflow DAG definitions
│   └── utils/             # Shared helpers
├── tests/                 # DAG integrity and unit tests
├── requirements.txt       # Pinned Airflow release
└── requirements-dev.txt   # Test, lint and security tools
```

## The DAG

`dags/${{ values.name | replace("-", "_") }}_dag.py` defines the DAG `${{ values.name }}`
(schedule `${{ values.schedule }}`): `start >> extract >> transform >> load >> validate >> end`.

## Testing

```bash
pytest tests/

# Run the whole DAG once
airflow db migrate
airflow dags test ${{ values.name }} 2024-01-01
```

## Pipeline

`.github/workflows/airflow.yaml` lints, type-checks, tests and scans the
project and runs the DAG once on every push and pull request. It needs no
secrets. The deploy job syncs `dags/` to an S3 DAGs bucket and is skipped until
the repository variables `AIRFLOW_DAGS_BUCKET`, `AWS_ROLE_ARN` and `AWS_REGION`
are set.

## License

MIT

## Author

${{ values.owner }}
