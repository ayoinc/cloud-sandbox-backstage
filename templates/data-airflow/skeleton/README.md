# ${{ values.name }}

${{ values.description }}

## Overview

Apache Airflow DAGs for data pipeline orchestration.

## Getting Started

```bash
# Start Airflow with Docker Compose
docker-compose up -d

# Or use local installation
pip install apache-airflow
airflow standalone
```

Access UI at [http://localhost:8080](http://localhost:8080)

## Project Structure

```
├── dags/             # Airflow DAG definitions
├── plugins/          # Custom operators and hooks
├── tests/            # DAG tests
└── docker-compose.yml
```

## Creating DAGs

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

with DAG(
    dag_id='example_dag',
    start_date=datetime(2024, 1, 1),
    schedule_interval='@daily',
) as dag:
    task = PythonOperator(
        task_id='example_task',
        python_callable=lambda: print("Hello"),
    )
```

## Testing

```bash
pytest tests/
```

## License

MIT

## Author

${{ values.owner }}
