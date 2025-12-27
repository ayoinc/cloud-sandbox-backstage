# ${{ values.name }}

${{ values.description }}

## Overview

This Apache Airflow DAG project provides a production-ready data pipeline with:

- ETL (Extract, Transform, Load) workflow pattern
- Built-in data validation and quality checks
- Comprehensive testing and CI/CD pipeline
- Configurable scheduling and retry logic
- XCom-based data passing between tasks
- Environment-aware tagging and configuration

```d2
direction: down

title: {
  label: Apache Airflow Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Users {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

webserver: Airflow Webserver {
  shape: rectangle
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  
  ui: Web UI (Port 8080) {
    style.fill: "#C8E6C9"
  }
  api: REST API {
    style.fill: "#C8E6C9"
  }
}

scheduler: Airflow Scheduler {
  shape: hexagon
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  
  executor: Executor {
    style.fill: "#FFE0B2"
  }
  parser: DAG Parser {
    style.fill: "#FFE0B2"
  }
}

workers: Worker Nodes {
  shape: rectangle
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  
  worker1: Worker 1
  worker2: Worker 2
  worker3: Worker N
}

metadata: Metadata DB {
  shape: cylinder
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "PostgreSQL\n(DAG state, task history)"
}

dags: DAG Files {
  shape: document
  style.fill: "#B2EBF2"
  style.stroke: "#00838F"
  label: "dags/\n${{ values.name }}_dag.py"
}

storage: External Storage {
  shape: cloud
  style.fill: "#F3E5F5"
  style.stroke: "#8E24AA"
  
  s3: S3/GCS
  warehouse: Data Warehouse
  api: External APIs
}

users -> webserver.ui: Monitor DAGs
webserver -> metadata: Read state
scheduler.parser -> dags: Parse DAGs
scheduler -> metadata: Update state
scheduler.executor -> workers: Dispatch tasks
workers -> storage: Read/Write data
workers -> metadata: Report status
```

## Configuration Summary

| Setting             | Value                       | Description                              |
| ------------------- | --------------------------- | ---------------------------------------- |
| **DAG Name**        | `${{ values.name }}`        | Unique identifier for this DAG           |
| **Owner**           | `${{ values.owner }}`       | Team or individual responsible           |
| **Environment**     | `${{ values.environment }}` | Deployment environment                   |
| **Schedule**        | `${{ values.schedule }}`    | Cron expression or preset                |
| **Start Date**      | `${{ values.startDate }}`   | Date from which scheduling begins        |
| **Catchup**         | `${{ values.catchup }}`     | Whether to backfill missed runs          |
| **Max Active Runs** | `${{ values.maxActiveRuns }}` | Concurrent DAG runs limit              |

### Default Task Arguments

| Argument              | Value           | Description                        |
| --------------------- | --------------- | ---------------------------------- |
| `depends_on_past`     | `False`         | Tasks don't wait for prior runs    |
| `email_on_failure`    | `True`          | Send alerts on task failure        |
| `retries`             | `3`             | Number of retry attempts           |
| `retry_delay`         | `5 minutes`     | Wait time between retries          |
| `execution_timeout`   | `2 hours`       | Maximum task execution time        |

---

## DAG Structure

This project follows a standard ETL (Extract, Transform, Load) pattern with validation:

```d2
direction: right

title: {
  label: ${{ values.name }} DAG Workflow
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

start: Start {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

extract: Extract {
  shape: rectangle
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Extract\n(Fetch from source)"
}

transform: Transform {
  shape: rectangle
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Transform\n(Apply business logic)"
}

load: Load {
  shape: rectangle
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "Load\n(Write to destination)"
}

validate: Validate {
  shape: rectangle
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "Validate\n(Quality checks)"
}

end: End {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

start -> extract -> transform -> load -> validate -> end
```

### Task Descriptions

| Task       | Operator         | Purpose                                      |
| ---------- | ---------------- | -------------------------------------------- |
| `start`    | `EmptyOperator`  | DAG entry point for visualization            |
| `extract`  | `PythonOperator` | Fetch data from source systems (APIs, DBs)   |
| `transform`| `PythonOperator` | Apply transformations and business logic     |
| `load`     | `PythonOperator` | Write processed data to destination          |
| `validate` | `PythonOperator` | Run data quality and validation checks       |
| `end`      | `EmptyOperator`  | DAG exit point for visualization             |

### Project Directory Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── airflow.yaml          # CI/CD pipeline
├── dags/
│   ├── ${{ values.name }}_dag.py # Main DAG definition
│   └── utils/
│       └── __init__.py           # Shared utilities
├── tests/
│   ├── __init__.py
│   └── test_dag.py               # DAG unit tests
├── plugins/                      # Custom operators/hooks/sensors
├── docs/
│   └── index.md                  # This documentation
├── requirements.txt              # Python dependencies
├── pyproject.toml                # Project configuration
├── mkdocs.yml                    # Documentation config
└── catalog-info.yaml             # Backstage catalog metadata
```

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline for continuous integration and deployment.

### Pipeline Features

- **Linting**: Code formatting with Black, import ordering with isort
- **Static Analysis**: Type checking with mypy, linting with flake8
- **Testing**: Unit tests with pytest and coverage reporting
- **DAG Validation**: Airflow DagBag import validation
- **Deployment**: Automated deployment to production environment

### Pipeline Workflow

```d2
direction: right

title: {
  label: Airflow CI/CD Pipeline
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

trigger: Push/PR {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Black\nisort\nflake8\nmypy"
}

test: Test {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "pytest\nCoverage"
}

validate: DAG Validation {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "DagBag\nImport Check"
}

deploy: Deploy {
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "Production\n(main branch only)"
}

trigger -> lint
lint -> test
lint -> validate
test -> deploy
validate -> deploy
```

### Pipeline Stages

| Stage          | Trigger                | Jobs Run                               |
| -------------- | ---------------------- | -------------------------------------- |
| Pull Request   | PR to `main`           | Lint, Test, DAG Validation             |
| Push to Main   | Merge to `main`        | Lint, Test, DAG Validation, Deploy     |

---

## Prerequisites

### 1. Python Environment

Ensure Python 3.11+ is installed:

```bash
# Check Python version
python --version  # Should be 3.11+

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# or
.\venv\Scripts\activate   # Windows
```

### 2. Apache Airflow

Install Airflow with constraints to ensure compatibility:

```bash
# Set Airflow version
AIRFLOW_VERSION=2.7.0
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# Install Airflow
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Or simply install from requirements.txt
pip install -r requirements.txt
```

### 3. Docker (Optional)

For containerized local development:

```bash
# Install Docker Desktop
# https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version

# Run Airflow with Docker Compose
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.7.0/docker-compose.yaml'
docker-compose up -d
```

### 4. Development Tools

Install linting and testing tools:

```bash
pip install black flake8 isort mypy pytest pytest-cov
```

---

## Usage

### Local Development

#### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Initialize Airflow database
export AIRFLOW_HOME=$(pwd)
airflow db init

# Create admin user
airflow users create \
  --username admin \
  --password admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com

# Start Airflow services (in separate terminals or background)
airflow webserver --port 8080 &
airflow scheduler &

# Access the UI
open http://localhost:8080
```

#### Environment Variables

| Variable         | Description                    | Default         |
| ---------------- | ------------------------------ | --------------- |
| `AIRFLOW_HOME`   | Airflow configuration directory | `~/airflow`    |
| `AIRFLOW__CORE__DAGS_FOLDER` | DAGs directory    | `$AIRFLOW_HOME/dags` |
| `AIRFLOW__CORE__EXECUTOR` | Executor type        | `SequentialExecutor` |
| `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` | Database URL | SQLite (local) |

### Testing DAGs

#### Run Unit Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=dags --cov-report=html

# Run specific test file
pytest tests/test_dag.py -v

# Run specific test function
pytest tests/test_dag.py::test_dag_loaded -v
```

#### Validate DAG Syntax

```bash
# Check for import errors
export AIRFLOW_HOME=$(pwd)
python -c "
from airflow.models import DagBag
dag_bag = DagBag(dag_folder='dags', include_examples=False)
if dag_bag.import_errors:
    for dag_id, error in dag_bag.import_errors.items():
        print(f'Error in {dag_id}: {error}')
    exit(1)
print(f'Successfully validated {len(dag_bag.dags)} DAGs')
"
```

#### Test Individual Tasks

```bash
# Test a specific task
airflow tasks test ${{ values.name }} extract 2024-01-01

# Test with debug logging
airflow tasks test ${{ values.name }} transform 2024-01-01 --verbose
```

---

## DAG Examples

### Basic ETL Pattern (Current Implementation)

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': '${{ values.owner }}',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='${{ values.name }}',
    default_args=default_args,
    schedule_interval='${{ values.schedule }}',
    start_date=datetime.strptime('${{ values.startDate }}', '%Y-%m-%d'),
    catchup=${{ values.catchup }},
) as dag:
    
    start = EmptyOperator(task_id='start')
    
    extract = PythonOperator(
        task_id='extract',
        python_callable=extract_data,
    )
    
    transform = PythonOperator(
        task_id='transform', 
        python_callable=transform_data,
    )
    
    load = PythonOperator(
        task_id='load',
        python_callable=load_data,
    )
    
    start >> extract >> transform >> load
```

### Parallel Processing Pattern

```python
from airflow.operators.python import PythonOperator

with DAG(...) as dag:
    
    extract_users = PythonOperator(task_id='extract_users', ...)
    extract_orders = PythonOperator(task_id='extract_orders', ...)
    extract_products = PythonOperator(task_id='extract_products', ...)
    
    join_data = PythonOperator(task_id='join_data', ...)
    
    # Parallel extraction, then join
    [extract_users, extract_orders, extract_products] >> join_data
```

### Branching Pattern

```python
from airflow.operators.python import BranchPythonOperator

def choose_branch(**context):
    if context['params'].get('full_refresh'):
        return 'full_load'
    return 'incremental_load'

with DAG(...) as dag:
    
    branch = BranchPythonOperator(
        task_id='choose_load_type',
        python_callable=choose_branch,
    )
    
    full_load = PythonOperator(task_id='full_load', ...)
    incremental_load = PythonOperator(task_id='incremental_load', ...)
    
    branch >> [full_load, incremental_load]
```

### TaskFlow API (Airflow 2.0+)

```python
from airflow.decorators import dag, task

@dag(schedule_interval='${{ values.schedule }}', start_date=datetime(2024, 1, 1))
def ${{ values.name }}_taskflow():
    
    @task
    def extract():
        return {"data": [1, 2, 3]}
    
    @task
    def transform(data: dict):
        return {"transformed": [x * 2 for x in data["data"]]}
    
    @task
    def load(data: dict):
        print(f"Loading: {data}")
    
    # Automatic XCom passing
    raw_data = extract()
    transformed = transform(raw_data)
    load(transformed)

dag = ${{ values.name }}_taskflow()
```

---

## Connections and Variables

### Managing Connections

Connections store credentials for external systems. Configure via UI or CLI:

#### Via Airflow UI

1. Navigate to **Admin > Connections**
2. Click **+ Add a new record**
3. Fill in connection details:
   - **Connection Id**: Unique identifier (e.g., `postgres_default`)
   - **Connection Type**: Database/service type
   - **Host**, **Schema**, **Login**, **Password**, **Port**

#### Via CLI

```bash
# Add a PostgreSQL connection
airflow connections add 'postgres_default' \
    --conn-type 'postgres' \
    --conn-host 'localhost' \
    --conn-schema 'mydb' \
    --conn-login 'user' \
    --conn-password 'password' \
    --conn-port '5432'

# Add an AWS connection
airflow connections add 'aws_default' \
    --conn-type 'aws' \
    --conn-extra '{"region_name": "us-east-1"}'

# List all connections
airflow connections list

# Delete a connection
airflow connections delete 'postgres_default'
```

#### Via Environment Variables

```bash
# Format: AIRFLOW_CONN_{CONN_ID}='{conn_type}://{login}:{password}@{host}:{port}/{schema}'
export AIRFLOW_CONN_POSTGRES_DEFAULT='postgresql://user:password@localhost:5432/mydb'
export AIRFLOW_CONN_AWS_DEFAULT='aws://?region_name=us-east-1'
```

### Managing Variables

Variables store configuration values accessible across DAGs:

#### Via UI

1. Navigate to **Admin > Variables**
2. Click **+ Add a new record**
3. Enter **Key** and **Value**

#### Via CLI

```bash
# Set a variable
airflow variables set 'environment' '${{ values.environment }}'
airflow variables set 'api_endpoint' 'https://api.example.com'
airflow variables set 'config' '{"batch_size": 1000, "timeout": 300}' --json

# Get a variable
airflow variables get 'environment'

# List all variables
airflow variables list

# Delete a variable
airflow variables delete 'environment'
```

#### In DAG Code

```python
from airflow.models import Variable

# Get simple variable
env = Variable.get('environment', default_var='dev')

# Get JSON variable
config = Variable.get('config', deserialize_json=True)
batch_size = config.get('batch_size', 100)
```

### Common Connections

| Connection ID       | Type       | Purpose                          |
| ------------------- | ---------- | -------------------------------- |
| `postgres_default`  | PostgreSQL | Metadata database, data sources  |
| `aws_default`       | AWS        | S3, Redshift, other AWS services |
| `google_cloud_default` | GCP     | BigQuery, GCS, Cloud Functions   |
| `slack_default`     | Slack      | Alert notifications              |
| `http_default`      | HTTP       | REST API endpoints               |

---

## Monitoring and Logging

### Airflow UI Monitoring

| View            | Purpose                                           |
| --------------- | ------------------------------------------------- |
| **DAGs**        | List all DAGs with status, schedule, recent runs  |
| **Grid**        | Task instance history in grid format              |
| **Graph**       | Visual DAG structure with task dependencies       |
| **Calendar**    | DAG runs plotted on calendar                      |
| **Task Duration** | Historical task duration analysis               |
| **Gantt**       | Timeline view of task execution                   |

### Log Access

#### Via UI

1. Click on a DAG run
2. Click on a task instance
3. Select **Log** tab

#### Via CLI

```bash
# View task logs
airflow tasks log ${{ values.name }} extract 2024-01-01

# Follow logs in real-time
airflow tasks log ${{ values.name }} extract 2024-01-01 --follow
```

#### Log Locations

| Configuration | Log Location                                    |
| ------------- | ----------------------------------------------- |
| Local         | `$AIRFLOW_HOME/logs/{dag_id}/{task_id}/{date}/` |
| S3            | `s3://bucket/logs/{dag_id}/{task_id}/{date}/`   |
| GCS           | `gs://bucket/logs/{dag_id}/{task_id}/{date}/`   |

### Alerting Configuration

#### Email Alerts

```python
default_args = {
    'email': ['team@example.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'email_on_success': False,
}
```

#### Slack Alerts

```python
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator

def send_slack_alert(context):
    slack_msg = f"""
    :red_circle: Task Failed
    *DAG*: {context.get('dag').dag_id}
    *Task*: {context.get('task_instance').task_id}
    *Execution Time*: {context.get('execution_date')}
    """
    SlackWebhookOperator(
        task_id='slack_alert',
        http_conn_id='slack_default',
        message=slack_msg,
    ).execute(context)

default_args = {
    'on_failure_callback': send_slack_alert,
}
```

#### SLA Monitoring

```python
from datetime import timedelta

with DAG(..., sla_miss_callback=sla_alert) as dag:
    
    critical_task = PythonOperator(
        task_id='critical_task',
        python_callable=critical_function,
        sla=timedelta(hours=1),  # Alert if task takes > 1 hour
    )
```

### Metrics and Observability

| Tool          | Integration                                      |
| ------------- | ------------------------------------------------ |
| **Prometheus**| StatsD exporter with `statsd_exporter`           |
| **Grafana**   | Dashboards via Prometheus or direct DB queries   |
| **Datadog**   | Airflow integration via DogStatsD                |
| **CloudWatch**| AWS MWAA native integration                      |

---

## Troubleshooting

### Common Issues

#### DAG Not Appearing in UI

**Symptoms**: DAG file exists but doesn't show in the Airflow UI.

**Resolution**:
1. Check for import errors:
   ```bash
   python dags/${{ values.name }}_dag.py
   ```
2. Verify DAG folder configuration:
   ```bash
   echo $AIRFLOW_HOME
   ls -la $AIRFLOW_HOME/dags/
   ```
3. Check scheduler logs:
   ```bash
   airflow scheduler --num-runs 1
   ```
4. Ensure DAG file has `.py` extension
5. Verify DAG is not paused in the UI

#### Task Stuck in Queued State

**Symptoms**: Tasks remain in "queued" status indefinitely.

**Resolution**:
1. Check executor configuration:
   ```bash
   airflow config get-value core executor
   ```
2. Verify workers are running:
   ```bash
   airflow celery worker --help  # For CeleryExecutor
   ```
3. Check for resource constraints (pool slots, parallelism)
4. Review scheduler logs for errors

#### Import Errors

**Symptoms**: `ModuleNotFoundError` or `ImportError` in DAG parsing.

**Resolution**:
1. Install missing packages:
   ```bash
   pip install -r requirements.txt
   ```
2. Verify package is installed in Airflow environment
3. Check for circular imports in custom modules
4. Ensure `__init__.py` exists in package directories

#### Database Connection Errors

**Symptoms**: `Could not connect to database` or `Connection refused`.

**Resolution**:
1. Verify connection configuration:
   ```bash
   airflow connections get postgres_default
   ```
2. Test connection manually:
   ```bash
   psql -h localhost -U user -d database
   ```
3. Check firewall and network settings
4. Verify credentials are correct

#### Scheduler Not Processing DAGs

**Symptoms**: DAG runs not being triggered on schedule.

**Resolution**:
1. Verify scheduler is running:
   ```bash
   ps aux | grep "airflow scheduler"
   ```
2. Check DAG is not paused
3. Verify start_date is in the past
4. Check max_active_runs limit
5. Review scheduler heartbeat in UI

### Debugging Tips

```bash
# Test DAG loading
airflow dags list

# Test single task
airflow tasks test ${{ values.name }} extract 2024-01-01

# Clear failed tasks for rerun
airflow tasks clear ${{ values.name }} -s 2024-01-01 -e 2024-01-01

# Trigger DAG manually
airflow dags trigger ${{ values.name }}

# Check Airflow configuration
airflow config list

# Validate DAG syntax
python -c "from dags.${{ values.name }}_dag import dag; print(dag)"
```

---

## Related Templates

| Template                                                      | Description                            |
| ------------------------------------------------------------- | -------------------------------------- |
| [data-dbt](/docs/default/template/data-dbt)                   | dbt data transformation project        |
| [data-spark](/docs/default/template/data-spark)               | Apache Spark data processing           |
| [aws-mwaa](/docs/default/template/aws-mwaa)                   | Managed Workflows for Apache Airflow   |
| [data-pipeline](/docs/default/template/data-pipeline)         | Generic data pipeline template         |
| [python-service](/docs/default/template/python-service)       | Python microservice                    |
| [aws-lambda-python](/docs/default/template/aws-lambda-python) | Serverless Python function             |

---

## References

- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [Airflow Operators Guide](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/operators.html)
- [TaskFlow API Tutorial](https://airflow.apache.org/docs/apache-airflow/stable/tutorial/taskflow.html)
- [Airflow Connections](https://airflow.apache.org/docs/apache-airflow/stable/howto/connection.html)
- [Airflow Variables](https://airflow.apache.org/docs/apache-airflow/stable/howto/variable.html)
- [Airflow Providers](https://airflow.apache.org/docs/apache-airflow-providers/)
- [GitHub Actions for Python](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-python)
- [pytest Documentation](https://docs.pytest.org/)
