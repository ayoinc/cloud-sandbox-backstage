# Apache Airflow Usage Guide

## Prerequisites

- Python 3.8+
- Docker and Docker Compose
- PostgreSQL 12+ (for production)
- Redis (for Celery executor)

## Deployment with Docker Compose

### Production-Ready Setup

```yaml
# docker-compose.yml
version: '3.8'

x-airflow-common: &airflow-common
  image: apache/airflow:2.8.0
  environment: &airflow-common-env
    AIRFLOW__CORE__EXECUTOR: CeleryExecutor
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
    AIRFLOW__CELERY__RESULT_BACKEND: db+postgresql://airflow:airflow@postgres/airflow
    AIRFLOW__CELERY__BROKER_URL: redis://:@redis:6379/0
    AIRFLOW__CORE__FERNET_KEY: ''
    AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION: 'true'
    AIRFLOW__CORE__LOAD_EXAMPLES: 'false'
    AIRFLOW__API__AUTH_BACKENDS: 'airflow.api.auth.backend.basic_auth'
    AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK: 'true'
    _PIP_ADDITIONAL_REQUIREMENTS: ${_PIP_ADDITIONAL_REQUIREMENTS:-}
  volumes:
    - ./dags:/opt/airflow/dags
    - ./logs:/opt/airflow/logs
    - ./plugins:/opt/airflow/plugins
    - ./config:/opt/airflow/config
  user: '${AIRFLOW_UID:-50000}:0'
  depends_on: &airflow-common-depends-on
    redis:
      condition: service_healthy
    postgres:
      condition: service_healthy

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres-db-volume:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD', 'pg_isready', '-U', 'airflow']
      interval: 10s
      retries: 5
      start_period: 5s
    restart: always

  redis:
    image: redis:7
    expose:
      - 6379
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 30s
      retries: 50
      start_period: 30s
    restart: always

  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - '8080:8080'
    healthcheck:
      test: ['CMD', 'curl', '--fail', 'http://localhost:8080/health']
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always

  airflow-scheduler:
    <<: *airflow-common
    command: scheduler
    healthcheck:
      test: ['CMD', 'curl', '--fail', 'http://localhost:8974/health']
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always

  airflow-worker:
    <<: *airflow-common
    command: celery worker
    healthcheck:
      test:
        - 'CMD-SHELL'
        - 'celery --app airflow.providers.celery.executors.celery_executor.app inspect ping -d "celery@$${HOSTNAME}"'
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always
    deploy:
      replicas: 2

  airflow-triggerer:
    <<: *airflow-common
    command: triggerer
    healthcheck:
      test:
        [
          'CMD-SHELL',
          'airflow jobs check --job-type TriggererJob --hostname "$${HOSTNAME}"',
        ]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always

  airflow-init:
    <<: *airflow-common
    entrypoint: /bin/bash
    command:
      - -c
      - |
        airflow db migrate
        airflow users create \
          --username admin \
          --firstname Admin \
          --lastname User \
          --role Admin \
          --email admin@example.com \
          --password admin
    depends_on:
      <<: *airflow-common-depends-on

  flower:
    <<: *airflow-common
    command: celery flower
    ports:
      - '5555:5555'
    healthcheck:
      test: ['CMD', 'curl', '--fail', 'http://localhost:5555/']
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always

volumes:
  postgres-db-volume:
```

## DAG Examples

### ETL Pipeline

The following diagram illustrates a typical ETL pipeline flow in Airflow:

```d2
direction: right

title: ETL Pipeline Flow {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

s3_source: S3 Data Source {
  shape: cylinder
  style: {
    fill: "#fff3e0"
    stroke: "#ff9800"
  }
  label: "S3 Bucket\n(Raw Data)"
}

sensor: S3 Key Sensor {
  shape: hexagon
  style: {
    fill: "#e3f2fd"
    stroke: "#1976d2"
  }
  label: "Wait for File\n(S3KeySensor)"
}

extract: Extract {
  shape: rectangle
  style: {
    fill: "#e8f5e9"
    stroke: "#4caf50"
    border-radius: 8
  }
  desc: |md
    - Read from S3
    - Parse CSV/JSON
    - Push to XCom
  |
}

transform: Transform {
  shape: rectangle
  style: {
    fill: "#f3e5f5"
    stroke: "#9c27b0"
    border-radius: 8
  }
  desc: |md
    - Clean data
    - Apply business logic
    - Deduplication
  |
}

create_table: Create Table {
  shape: rectangle
  style: {
    fill: "#e0f2f1"
    stroke: "#009688"
    border-radius: 8
  }
  label: "Create Table\n(PostgresOperator)"
}

load: Load {
  shape: rectangle
  style: {
    fill: "#fce4ec"
    stroke: "#e91e63"
    border-radius: 8
  }
  desc: |md
    - Write to PostgreSQL
    - Batch inserts
    - Verify row count
  |
}

postgres_db: PostgreSQL {
  shape: cylinder
  style: {
    fill: "#e8eaf6"
    stroke: "#3f51b5"
  }
  label: "PostgreSQL\n(Data Warehouse)"
}

s3_source -> sensor: poll for file
sensor -> extract: file ready
extract -> transform: raw data
transform -> create_table: prepare schema
transform -> load: transformed data
create_table -> load: table ready
load -> postgres_db: insert records
```

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
import pandas as pd

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['data-alerts@example.com'],
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
    'max_retry_delay': timedelta(minutes=30),
}

def extract_from_s3(**context):
    """Extract data from S3"""
    s3_hook = S3Hook(aws_conn_id='aws_default')
    execution_date = context['execution_date'].strftime('%Y-%m-%d')

    # Read file from S3
    file_content = s3_hook.read_key(
        key=f'raw/data/{execution_date}/events.csv',
        bucket_name='my-data-bucket'
    )

    df = pd.read_csv(io.StringIO(file_content))

    # Push to XCom (for small data)
    context['ti'].xcom_push(key='record_count', value=len(df))

    # Save to temp location
    df.to_parquet(f'/tmp/events_{execution_date}.parquet')
    return f'/tmp/events_{execution_date}.parquet'

def transform_data(**context):
    """Transform extracted data"""
    file_path = context['ti'].xcom_pull(task_ids='extract')
    df = pd.read_parquet(file_path)

    # Apply transformations
    df['processed_at'] = datetime.utcnow()
    df['event_date'] = pd.to_datetime(df['timestamp']).dt.date
    df = df.drop_duplicates(subset=['event_id'])

    output_path = file_path.replace('.parquet', '_transformed.parquet')
    df.to_parquet(output_path)
    return output_path

def load_to_postgres(**context):
    """Load data to PostgreSQL"""
    file_path = context['ti'].xcom_pull(task_ids='transform')
    df = pd.read_parquet(file_path)

    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    engine = pg_hook.get_sqlalchemy_engine()

    df.to_sql(
        'events',
        engine,
        if_exists='append',
        index=False,
        method='multi',
        chunksize=10000
    )

    return len(df)

with DAG(
    'etl_pipeline',
    default_args=default_args,
    description='ETL pipeline from S3 to PostgreSQL',
    schedule='0 2 * * *',  # 2 AM daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=['etl', 'production'],
) as dag:

    wait_for_file = S3KeySensor(
        task_id='wait_for_file',
        bucket_name='my-data-bucket',
        bucket_key='raw/data/{{ ds }}/events.csv',
        aws_conn_id='aws_default',
        timeout=3600,
        poke_interval=60,
        mode='reschedule',
    )

    extract = PythonOperator(
        task_id='extract',
        python_callable=extract_from_s3,
    )

    transform = PythonOperator(
        task_id='transform',
        python_callable=transform_data,
    )

    create_table = PostgresOperator(
        task_id='create_table',
        postgres_conn_id='postgres_default',
        sql="""
            CREATE TABLE IF NOT EXISTS events (
                event_id VARCHAR(50) PRIMARY KEY,
                user_id VARCHAR(50),
                event_type VARCHAR(50),
                timestamp TIMESTAMP,
                event_date DATE,
                processed_at TIMESTAMP
            );
        """,
    )

    load = PythonOperator(
        task_id='load',
        python_callable=load_to_postgres,
    )

    wait_for_file >> extract >> transform >> [create_table, load]
    create_table >> load
```

### Dynamic Task Generation

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from datetime import datetime

def process_partition(partition_id, **context):
    print(f"Processing partition {partition_id}")
    # Process logic here
    return f"Completed partition {partition_id}"

with DAG(
    'dynamic_tasks',
    start_date=datetime(2024, 1, 1),
    schedule='@daily',
    catchup=False,
) as dag:

    start = EmptyOperator(task_id='start')
    end = EmptyOperator(task_id='end')

    # Dynamic task generation
    partitions = ['us-east', 'us-west', 'eu-west', 'ap-south']

    for partition in partitions:
        task = PythonOperator(
            task_id=f'process_{partition.replace("-", "_")}',
            python_callable=process_partition,
            op_kwargs={'partition_id': partition},
        )
        start >> task >> end
```

### TaskFlow API (Airflow 2.0+)

```python
from airflow.decorators import dag, task
from datetime import datetime
import requests

@dag(
    schedule='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['taskflow'],
)
def taskflow_example():

    @task()
    def extract():
        """Extract data from API"""
        response = requests.get('https://api.example.com/data')
        return response.json()

    @task()
    def transform(data: dict):
        """Transform data"""
        transformed = []
        for record in data['records']:
            transformed.append({
                'id': record['id'],
                'value': record['value'] * 2,
                'processed': True
            })
        return transformed

    @task()
    def load(data: list):
        """Load data to destination"""
        print(f"Loading {len(data)} records")
        # Load logic here
        return len(data)

    # Define pipeline
    raw_data = extract()
    transformed_data = transform(raw_data)
    load(transformed_data)

# Instantiate DAG
taskflow_example()
```

### Branching and Conditionals

```python
from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.empty import EmptyOperator
from datetime import datetime
import random

def decide_branch(**context):
    """Decide which branch to take"""
    execution_date = context['execution_date']

    # Business logic for branching
    if execution_date.weekday() < 5:  # Weekday
        return 'weekday_processing'
    else:
        return 'weekend_processing'

def check_data_quality(**context):
    """Check if data passes quality checks"""
    # Simulated quality check
    quality_score = random.uniform(0, 1)

    if quality_score > 0.8:
        return 'data_ok'
    else:
        return 'data_needs_review'

with DAG(
    'branching_example',
    start_date=datetime(2024, 1, 1),
    schedule='@daily',
    catchup=False,
) as dag:

    start = EmptyOperator(task_id='start')

    branch = BranchPythonOperator(
        task_id='branch_by_day',
        python_callable=decide_branch,
    )

    weekday = EmptyOperator(task_id='weekday_processing')
    weekend = EmptyOperator(task_id='weekend_processing')

    quality_check = BranchPythonOperator(
        task_id='quality_check',
        python_callable=check_data_quality,
        trigger_rule='none_failed_min_one_success',
    )

    data_ok = EmptyOperator(task_id='data_ok')
    data_review = EmptyOperator(task_id='data_needs_review')

    end = EmptyOperator(
        task_id='end',
        trigger_rule='none_failed_min_one_success',
    )

    start >> branch >> [weekday, weekend] >> quality_check
    quality_check >> [data_ok, data_review] >> end
```

## CLI Commands

```bash
# DAG management
airflow dags list
airflow dags show my_dag
airflow dags trigger my_dag
airflow dags trigger my_dag --conf '{"key": "value"}'
airflow dags pause my_dag
airflow dags unpause my_dag
airflow dags backfill my_dag -s 2024-01-01 -e 2024-01-31

# Task management
airflow tasks list my_dag
airflow tasks test my_dag my_task 2024-01-01
airflow tasks run my_dag my_task 2024-01-01
airflow tasks clear my_dag -s 2024-01-01 -e 2024-01-31
airflow tasks failed-deps my_dag my_task 2024-01-01

# Database
airflow db init
airflow db migrate
airflow db check
airflow db clean --clean-before-timestamp "2024-01-01 00:00:00"

# Users
airflow users create --username admin --role Admin --email admin@example.com -p password
airflow users list
airflow users delete --username old_user

# Connections
airflow connections list
airflow connections add 'my_conn' --conn-type 'postgres' --conn-host 'localhost'
airflow connections delete 'my_conn'

# Variables
airflow variables list
airflow variables set my_var "my_value"
airflow variables get my_var
airflow variables import variables.json

# Pools
airflow pools list
airflow pools set my_pool 10 "My pool description"

# Providers
airflow providers list
```

## Testing DAGs

```python
# tests/test_my_dag.py
import pytest
from airflow.models import DagBag
from datetime import datetime

@pytest.fixture
def dagbag():
    return DagBag(dag_folder='dags/', include_examples=False)

def test_dag_loaded(dagbag):
    """Test that DAG is loaded without errors"""
    dag = dagbag.get_dag('my_dag')
    assert dagbag.import_errors == {}
    assert dag is not None
    assert len(dag.tasks) > 0

def test_dag_structure(dagbag):
    """Test DAG structure"""
    dag = dagbag.get_dag('my_dag')

    # Check task count
    assert len(dag.tasks) == 5

    # Check task dependencies
    extract_task = dag.get_task('extract')
    transform_task = dag.get_task('transform')

    assert transform_task in extract_task.downstream_list

def test_dag_schedule(dagbag):
    """Test DAG schedule"""
    dag = dagbag.get_dag('my_dag')
    assert dag.schedule_interval == '@daily'
    assert dag.catchup == False

def test_task_callable():
    """Test task functions directly"""
    from dags.my_dag import extract_data

    result = extract_data()
    assert result is not None
    assert len(result) > 0
```

## Troubleshooting

| Issue                      | Cause                                | Solution                                |
| -------------------------- | ------------------------------------ | --------------------------------------- |
| DAG not appearing          | Parse error, wrong folder            | Check `airflow dags list-import-errors` |
| Tasks stuck in queued      | No workers, pool exhausted           | Scale workers, increase pool slots      |
| Tasks failing immediately  | Dependency issues, connection errors | Check task logs, verify connections     |
| Scheduler not scheduling   | Scheduler down, DAG paused           | Check scheduler health, unpause DAG     |
| High memory usage          | Large XComs, memory leaks            | Use external storage, optimize tasks    |
| Slow DAG parsing           | Complex DAGs, many imports           | Reduce top-level imports, simplify DAGs |
| Database connection errors | Pool exhausted, timeout              | Increase pool size, add retries         |

### Debug Commands

```bash
# Check DAG parsing errors
airflow dags list-import-errors

# Test task execution
airflow tasks test my_dag my_task 2024-01-01

# View task logs
airflow tasks logs my_dag my_task 2024-01-01

# Check scheduler health
curl http://localhost:8974/health

# View running tasks
airflow tasks states-for-dag-run my_dag 2024-01-01

# Debug connection
airflow connections test my_conn
```

## Best Practices

### DAG Design

1. **Keep DAGs simple** - One DAG per workflow, avoid mega-DAGs
2. **Use TaskFlow API** - Cleaner code, automatic XCom handling
3. **Avoid top-level code** - Move imports inside tasks when possible
4. **Set appropriate timeouts** - Prevent stuck tasks
5. **Use pools** - Control resource usage

### Performance

1. **Minimize XCom size** - Use external storage for large data
2. **Use sensors sparingly** - Prefer deferrable operators
3. **Batch small tasks** - Reduce scheduler overhead
4. **Configure parallelism** - Match to infrastructure capacity

### Production Checklist

- [ ] Set `catchup=False` unless backfill needed
- [ ] Configure email alerts for failures
- [ ] Set appropriate retries and timeouts
- [ ] Use connection/variable encryption
- [ ] Enable remote logging (S3/GCS)
- [ ] Set up monitoring and alerting
- [ ] Regular database cleanup
- [ ] Test DAGs before deployment
- [ ] Use Git for version control
- [ ] Document DAG purposes and dependencies
