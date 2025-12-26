# Apache Airflow

Workflow orchestration platform for programmatically authoring, scheduling, and monitoring data pipelines and ETL workflows.

## Quick Start

### Start Airflow with Docker Compose

```bash
# Create directories
mkdir -p ./dags ./logs ./plugins ./config

# Set environment variables
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Initialize database
docker-compose up airflow-init

# Start all services
docker-compose up -d

# Access Web UI
open http://localhost:8080
# Default credentials: airflow / airflow
```

### Create Your First DAG

```python
# dags/my_first_dag.py
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['alerts@example.com'],
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'my_first_dag',
    default_args=default_args,
    description='A simple tutorial DAG',
    schedule='0 0 * * *',  # Daily at midnight
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['example', 'tutorial'],
) as dag:

    task_1 = BashOperator(
        task_id='print_date',
        bash_command='date',
    )

    task_2 = PythonOperator(
        task_id='process_data',
        python_callable=lambda: print("Processing data..."),
    )

    task_1 >> task_2
```

## Features

| Feature                 | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| **DAG Authoring**       | Python-based workflow definitions with full programming capabilities |
| **Dynamic Pipelines**   | Generate tasks dynamically based on data or configuration            |
| **Extensive Operators** | 700+ pre-built operators for AWS, GCP, Azure, databases, etc.        |
| **Task Dependencies**   | Complex dependency patterns with branching and joining               |
| **Scheduling**          | Cron-based scheduling with timezone support                          |
| **Backfilling**         | Catch up on historical runs automatically                            |
| **XComs**               | Share data between tasks via cross-communication                     |
| **Sensors**             | Wait for external conditions before proceeding                       |

## Architecture

```d2
direction: down

title: Apache Airflow Architecture {
  shape: text
  near: top-center
  style: {
    font-size: 24
    bold: true
  }
}

airflow: Apache Airflow {
  style: {
    fill: "#e3f2fd"
    stroke: "#1976d2"
    border-radius: 8
  }

  webserver: Web Server (Flask UI) {
    shape: rectangle
    style: {
      fill: "#bbdefb"
      stroke: "#1976d2"
    }
    features: |md
      - DAG views
      - Task logs
      - Admin UI
      - REST API
    |
  }

  scheduler: Scheduler {
    shape: rectangle
    style: {
      fill: "#c8e6c9"
      stroke: "#388e3c"
    }
    features: |md
      - Parse DAGs
      - Schedule tasks
      - Monitor
    |
  }

  workers: Workers (Executors) {
    shape: rectangle
    style: {
      fill: "#fff3e0"
      stroke: "#f57c00"
    }
    features: |md
      - Run tasks
      - Report status
      - XCom push
    |
  }
}

metadata_db: Metadata Database {
  shape: cylinder
  style: {
    fill: "#f3e5f5"
    stroke: "#7b1fa2"
  }
  label: "Metadata Database\n(PostgreSQL / MySQL)"
}

message_broker: Message Broker {
  shape: hexagon
  style: {
    fill: "#ffebee"
    stroke: "#c62828"
  }
  label: "Message Broker\n(Redis / RabbitMQ)"
}

result_backend: Result Backend {
  shape: cylinder
  style: {
    fill: "#e8f5e9"
    stroke: "#2e7d32"
  }
  label: "Result Backend\n(Redis / DB)"
}

airflow.webserver -> metadata_db: read/write
airflow.scheduler -> metadata_db: state management
airflow.workers -> metadata_db: task status

metadata_db -> message_broker: task queue
metadata_db -> result_backend: results
airflow.scheduler -> message_broker: dispatch tasks
airflow.workers -> message_broker: receive tasks
airflow.workers -> result_backend: store results
```

## Executor Types

| Executor                     | Description                            | Use Case                       |
| ---------------------------- | -------------------------------------- | ------------------------------ |
| **SequentialExecutor**       | Single process, tasks run sequentially | Development only               |
| **LocalExecutor**            | Multi-process on single machine        | Small deployments              |
| **CeleryExecutor**           | Distributed workers via Celery         | Production, horizontal scaling |
| **KubernetesExecutor**       | Each task runs in its own Pod          | Cloud-native, isolation        |
| **CeleryKubernetesExecutor** | Hybrid Celery + Kubernetes             | Mixed workloads                |

## Version Information

- **Apache Airflow**: 2.8.x (current stable)
- **Python**: 3.8 - 3.12
- **Database**: PostgreSQL 12+, MySQL 8+

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and components
- [Usage](usage.md) - DAG patterns, operators, and best practices
