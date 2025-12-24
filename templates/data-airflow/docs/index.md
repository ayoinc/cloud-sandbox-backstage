# Apache Airflow DAG Development Template

## Overview

Apache Airflow is an open-source platform for authoring, scheduling, and monitoring workflows as Directed Acyclic Graphs (DAGs). This template provides a production-ready foundation for building and deploying Airflow DAGs with best practices, testing, and CI/CD automation.

### What are Airflow DAGs?

DAGs (Directed Acyclic Graphs) are workflows defined as Python code that specify the order and dependencies between tasks. Airflow uses these DAG definitions to orchestrate complex data pipelines across multiple systems.

### Common Use Cases

- **ETL/ELT Pipelines**: Extract data from sources, transform it, and load into data warehouses
- **Machine Learning Pipelines**: Data preparation, model training, validation, and deployment
- **Data Quality Checks**: Automated validation and monitoring of data quality metrics
- **Database Operations**: Backups, maintenance, schema migrations
- **API Integrations**: Synchronize data between systems via REST APIs
- **Alerting and Monitoring**: Trigger notifications based on system events or metrics
- **Data Science Workflows**: Jupyter notebook execution, feature engineering, experiments

### Key Benefits

- **Scalability**: Handle thousands of concurrent workflows
- **Extensibility**: 1000+ pre-built operators and hooks for common tasks
- **Monitoring**: Rich UI for DAG visualization and troubleshooting
- **Flexibility**: Define workflows as Python code with full coding capabilities
- **Integration**: Native support for cloud platforms, databases, and data tools

## Features

### 🏗️ Pre-configured DAG Structure

- Organized directory layout following best practices
- Modular DAG definitions with reusable components
- Default ETL template with extract-transform-load pattern
- Proper separation of concerns and code organization

### 🧪 Comprehensive Testing Framework

- Unit tests for DAG validation using pytest
- DAG import and structure testing
- Task dependency verification
- Custom operator and hook testing support

### 🚀 CI/CD Pipeline

- GitHub Actions workflows for automation
- Multi-stage pipeline: lint, test, validate, deploy
- Code quality checks (black, isort, flake8, mypy)
- Automated DAG validation before deployment

### 📚 Type Hints and Code Quality

- MyPy configuration for static type checking
- Black code formatting with consistent style
- Flake8 linting for code quality
- Import sorting with isort

### 🔄 Best Practices Built-in

- Idempotent task design patterns
- Proper retry and timeout configurations
- XCom usage for inter-task communication
- SLA monitoring and alerting setup
- Graceful error handling

## Prerequisites

Before using this template, ensure you have the following installed and configured:

### Required Software

1. **Python 3.9+**

   ```bash
   python --version
   # Should show 3.9 or higher
   ```

2. **pip (Python package manager)**

   ```bash
   pip --version
   ```

3. **Git**
   ```bash
   git --version
   ```

### Development Environment

```bash
# Clone your new repository
git clone <your-repo-url>
cd <repository-name>

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Airflow Installation

The template includes the following Airflow version:

```
apache-airflow>=2.7.0
```

For production use, consider:

- **Managed Airflow**: AWS MWAA, Google Cloud Composer, Azure Data Factory
- **Self-hosted**: Docker deployment with official Airflow images
- **Local development**: Docker Compose setup (see Local Development section)

### Docker Setup (Optional)

For local development with Airflow environment:

```bash
# Install Docker
docker --version

# Install Docker Compose
docker-compose --version
```

### Database Dependencies

Depending on your use case, you may need:

- **PostgreSQL**: `psycopg2-binary>=2.9.0`
- **MySQL**: `mysqlclient>=2.0.0`
- **MSSQL**: `pyodbc>=4.0.0`
- **BigQuery**: `google-cloud-bigquery>=3.0.0`

## Configuration Options

When creating a project from this template, the following parameters can be customized:

### Project Information

| Parameter     | Description                                | Validation                  | Example                       |
| ------------- | ------------------------------------------ | --------------------------- | ----------------------------- |
| `name`        | Project name (used for DAG ID)             | `^[a-z][a-z0-9-]*[a-z0-9]$` | `customer-etl-daily`          |
| `description` | Description of the DAG's purpose           | Any string                  | "Daily ETL for customer data" |
| `owner`       | Team ownership (must be a Backstage group) | Must exist in catalog       | `group:data-engineering`      |

### DAG Configuration

| Parameter       | Description              | Options                                 | Default       | Impact                                  |
| --------------- | ------------------------ | --------------------------------------- | ------------- | --------------------------------------- |
| `environment`   | Deployment environment   | `development`, `staging`, `production`  | `development` | Sets deployment conditions, connections |
| `schedule`      | DAG execution schedule   | Cron presets or expressions (see below) | `@daily`      | Determines when DAG runs                |
| `startDate`     | First scheduled run date | `YYYY-MM-DD` format                     | `2024-01-01`  | Backfill start point                    |
| `catchup`       | Backfill missed runs     | `true` or `false`                       | `false`       | Controls historical run behavior        |
| `maxActiveRuns` | Concurrent DAG runs      | `1-10`                                  | `1`           | Prevents resource exhaustion            |

#### Schedule Intervals

**Cron Presets:**

- `@hourly` - Every hour at minute 0: `0 * * * *`
- `@daily` - Every day at midnight: `0 0 * * *`
- `@weekly` - Every Sunday at midnight: `0 0 * * 0`
- `@monthly` - First day of month at midnight: `0 0 1 \* \*

**Custom Cron Expressions:**

- `0 */6 * * *` - Every 6 hours
- `30 2 * * 1-5` - Weekdays at 2:30 AM
- `0 */3 * * *` - Every 3 hours
- `0 8,14,20 * * *` - At 8 AM, 2 PM, and 8 PM

**Interval Examples:**

```python
# Every 15 minutes
schedule_interval = "*/15 * * * *"

# Every 2 hours
schedule_interval = "0 */2 * * *"

# Monday-Friday at 9 AM and 5 PM
schedule_interval = "0 9,17 * * 1-5"

# Last day of every month at 11 PM
schedule_interval = "0 23 28-31 * *"
```

### Repository Configuration

| Parameter | Description           | Required | Example                       |
| --------- | --------------------- | -------- | ----------------------------- |
| `repoUrl` | GitHub repository URL | Yes      | `https://github.com/org/repo` |

### Template Values in Code

All configuration values are substituted into the generated files:

- `dags/{{values.name}}_dag.py` - The main DAG definition
- `tests/test_dag.py` - DAG validation tests
- `.github/workflows/airflow.yaml` - CI/CD pipeline
- `catalog-info.yaml` - Backstage catalog entry

Example usage in DAG template:

```python
with DAG(
    dag_id='{{ values.name }}',
    schedule_interval='{{ values.schedule }}',
    start_date=datetime.strptime('{{ values.startDate }}', '%Y-%m-%d'),
    catchup={{ values.catchup }},
    max_active_runs={{ values.maxActiveRuns }},
    default_args={'owner': '{{ values.owner }}'}
) as dag:
```

## Project Structure

The template generates a complete Airflow DAG project with the following structure:

```
test-dag/
├── .github/
│   └── workflows/
│       └── airflow.yaml          # CI/CD pipeline configuration
├── dags/
│   ├── __init__.py
│   ├── utils/                    # Shared utilities and helpers
│   │   ├── __init__.py
│   │   └── helpers.py
│   ├── test-dag.py              # Main DAG definition (ETL template)
│   └── test-dag-staging.py      # Environment-specific DAG
├── tests/
│   ├── __init__.py
│   ├── test_dag.py              # DAG validation tests
│   ├── test_utils.py            # Utilities tests
│   └── fixtures.py              # Test data and mocks
├── docs/
│   ├── index.md                 # This documentation
│   ├── architecture.md          # Architecture documentation
│   └── examples.md              # Usage examples
├── .gitignore
├── catalog-info.yaml            # Backstage catalog entry
├── mkdocs.yml                   # MkDocs configuration
├── pyproject.toml               # Python project configuration
├── pytest.ini                   # Pytest configuration
└── requirements.txt             # Python dependencies
```

### Directory Breakdown

#### `dags/` - DAG Definitions

This is the main directory for all your DAG files. Each DAG file should contain:

- **DAG definition**: The workflow structure and schedule
- **Task definitions**: Operators and their configurations
- **Task dependencies**: How tasks relate to each other

```python
# dags/example_dag.py structure
from airflow import DAG
from airflow.operators.python import PythonOperator

def task_function(**context):
    # Task implementation
    pass

with DAG(
    dag_id='example_dag',
    schedule_interval='@daily',
    # ... other configurations
) as dag:

    task1 = PythonOperator(
        task_id='task1',
        python_callable=task_function
    )

    # Task dependencies
    task1 >> task2
```

#### `dags/utils/` - Shared Utilities

Contains reusable functions, constants, and helper classes:

```python
# dags/utils/helpers.py
from typing import Dict, Any
from datetime import datetime

def get_execution_date(context: Dict[str, Any]) -> datetime:
    """Extract execution date from Airflow context."""
    return context['execution_date']

def format_date_for_query(date: datetime) -> str:
    """Format date for SQL queries."""
    return date.strftime('%Y-%m-%d')

def send_slack_notification(message: str, channel: str):
    """Send notification to Slack channel."""
    # Implementation here
    pass
```

#### `plugins/` - Custom Operators and Hooks

Airflow plugins directory for custom:

- **Operators**: Custom task types
- **Hooks**: Connections to external systems
- **Sensors**: Custom polling mechanisms

```python
# plugins/custom_operators.py
from airflow.models.baseoperator import BaseOperator

class DataQualityCheckOperator(BaseOperator):
    """Custom operator for data quality checks."""

    def __init__(self, query, expected_result, **kwargs):
        self.query = query
        self.expected_result = expected_result
        super().__init__(**kwargs)

    def execute(self, context):
        # Implementation here
        pass
```

#### `tests/` - Test Suite

Organized test structure following pytest conventions:

```python
# tests/test_dag.py
from datetime import datetime
from airflow.models import DagBag

class TestCustomerEtlDag:
    """Test suite for customer ETL DAG."""

    def setup_method(self):
        self.dag_bag = DagBag(dag_folder='dags')
        self.dag = self.dag_bag.get_dag('customer-etl')

    def test_dag_loaded(self):
        assert self.dag is not None
        assert self.dag_bag.import_errors == {}
```

**Test Types:**

- **DAG validation tests**: Ensure DAGs can be imported without errors
- **Structure tests**: Verify task dependencies and configurations
- **Unit tests**: Test individual task functions
- **Integration tests**: Test task interactions and data flow

#### `requirements.txt` - Dependencies

Python package dependencies with version constraints:

```
# Core Airflow
apache-airflow>=2.7.0

# Database
psycopg2-binary>=2.9.0
sqlalchemy>=2.0.0

# Data processing
pandas>=2.0.0
numpy>=1.24.0

# Cloud providers (uncomment as needed)
# apache-airflow-providers-amazon>=8.0.0
# apache-airflow-providers-google>=10.0.0
# apache-airflow-providers-microsoft-azure>=8.0.0
```

## DAG Development

### Writing Your First DAG

Follow this pattern to create production-ready DAGs:

```python
"""
customer-etl-daily DAG

Daily ETL pipeline for processing customer data from source to data warehouse.
Owner: group:data-engineering
Schedule: 0 2 * * * (2 AM daily)
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.dates import days_ago
import logging

# Configure logging
logger = logging.getLogger(__name__)

# Default arguments applied to all tasks
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['data-team@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
    'execution_timeout': timedelta(hours=2),
    'trigger_rule': 'all_success',
}

def extract_customer_data(**context):
    """
    Extract customer data from source database.

    Args:
        context: Airflow context passed from PythonOperator

    Returns:
        dict: Extraction metadata including row count
    """
    logger.info("Starting customer data extraction")

    # TODO: Implement actual database extraction
    # Example with PostgreSQL:
    # import psycopg2
    # conn = psycopg2.connect(os.getenv('CUSTOMER_DB_CONN'))
    # cursor = conn.cursor()
    # cursor.execute("SELECT * FROM customers WHERE created_at >= %s", (execution_date,))

    # Simulated extraction for template
    execution_date = context['execution_date']
    extracted_records = 1000  # Simulate record count

    logger.info(f"Extracted {extracted_records} customer records for {execution_date}")

    # Return metadata for downstream tasks
    return {
        'validation_context': {
            'execution_date': str(execution_date),
            'extracted_count': extracted_records,
            'status': 'completed'
        }
    }

def transform_customer_data(**context):
    """
    Transform extracted customer data.

    Args:
        context: Airflow context

    Returns:
        dict: Transformation metadata
    """
    logger.info("Starting customer data transformation")

    # Pull data from upstream task
    ti = context['ti']
    extract_result = ti.xcom_pull(task_ids='extract', key='return_value')

    # TODO: Implement actual transformation logic
    # Common operations:
    # - Data type conversion
    # - Null value handling
    # - Data validation
    # - Aggregation
    # - Join with reference data

    extracted_count = extract_result.get('extracted_count', 0)
    transformed_count = extracted_count  # Simulate transformation

    logger.info(f"Transformed {transformed_count} customer records")

    return {
        'validation_context': {
            'transformed_count': transformed_count,
            'status': 'completed'
        }
    }

def load_customer_data(**context):
    """
    Load transformed customer data to data warehouse.

    Args:
        context: Airflow context

    Returns:
        dict: Load metadata
    """
    logger.info("Starting customer data load")

    ti = context['ti']
    transform_result = ti.xcom_pull(task_ids='transform', key='return_value')

    # TODO: Implement actual load logic
    # Example with PostgreSQL:
    # import psycopg2
    # conn = psycopg2.connect(os.getenv('WAREHOUSE_DB_CONN'))

    transformed_count = transform_result.get('transformed_count', 0)
    loaded_count = transformed_count

    logger.info(f"Loaded {loaded_count} customer records to warehouse")

    return {
        'records_loaded': loaded_count,
        'status': 'completed'
    }

def validate_customer_data(**context):
    """
    Validate loaded customer data for quality and completeness.

    Args:
        context: Airflow context
    """
    logger.info("Starting customer data validation")

    ti = context['ti']
    load_result = ti.xcom_pull(task_ids='load', key='return_value')

    records_loaded = load_result.get('records_loaded', 0)

    # TODO: Implement actual validation
    # Common checks:
    # - Row count validation
    # - Null value checks
    # - Data type validation
    # - Referential integrity
    # - Business rule validation

    if records_loaded == 0:
        raise ValueError("No records loaded, validation failed")

    logger.info(f"Validation completed: {records_loaded} records validated")

# Define the DAG
with DAG(
    dag_id='customer-etl-daily',
    default_args=default_args,
    description='Daily ETL pipeline for customer data processing',
    schedule_interval='0 2 * * *',  # Run at 2 AM daily
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=['data', 'etl', 'customer', 'daily'],
) as dag:

    # Define tasks
    start = EmptyOperator(task_id='start')

    extract_task = PythonOperator(
        task_id='extract',
        python_callable=extract_customer_data,
        provide_context=True,
    )

    transform_task = PythonOperator(
        task_id='transform',
        python_callable=transform_customer_data,
        provide_context=True,
    )

    load_task = PythonOperator(
        task_id='load',
        python_callable=load_customer_data,
        provide_context=True,
    )

    validate_task = PythonOperator(
        task_id='validate',
        python_callable=validate_customer_data,
        provide_context=True,
    )

    end = EmptyOperator(task_id='end')

    # Define workflow dependencies
    start >> extract_task >> transform_task >> load_task >> validate_task >> end
```

### Available Operators

#### PythonOperator

Execute Python functions with full access to Airflow context:

```python
from airflow.operators.python import PythonOperator

def my_task(**context):
    # Access all Airflow context variables
    execution_date = context['execution_date']
    ti = context['ti']
    dag_run = context['dag_run']

    # Your logic here
    result = some_python_function()

    # Push to XCom for downstream tasks
    ti.xcom_push(key='result', value=result)

python_task = PythonOperator(
    task_id='my_python_task',
    python_callable=my_task,
    provide_context=True,
    retries=3,
    retry_delay=timedelta(minutes=5)
)
```

#### BashOperator

Run shell commands and scripts:

```python
from airflow.operators.bash import BashOperator

bash_task = BashOperator(
    task_id='run_script',
    bash_command='/path/to/script.sh --date {{ ds }}',
    env={'MY_VAR': 'value'},
    append_env=True
)
```

#### SQL Operators

Execute SQL statements against databases:

```python
from airflow.providers.postgres.operators.postgres import PostgresOperator

postgres_task = PostgresOperator(
    task_id='create_table',
    postgres_conn_id='postgres_default',
    sql="""
        CREATE TABLE IF NOT EXISTS customer_metrics (
            date DATE,
            customer_id INTEGER,
            revenue DECIMAL(10,2)
        );
    """
)
```

#### HTTP Operators

Make HTTP requests to APIs:

```python
from airflow.providers.http.operators.http import SimpleHttpOperator

http_task = SimpleHttpOperator(
    task_id='fetch_api_data',
    http_conn_id='api_connection',
    endpoint='customers',
    method='GET',
    data={'date': '{{ ds }}'},
    response_filter=lambda response: response.json(),
    log_response=True
)
```

#### EmptyOperator

Placeholder tasks for workflow control:

```python
from airflow.operators.empty import EmptyOperator

start = EmptyOperator(task_id='start')
end = EmptyOperator(task_id='end')

task1 >> task2 >> end
start >> task3 >> end
```

### Task Dependencies and Branching

#### Basic Dependencies

```python
# Linear workflow
task1 >> task2 >> task3

# Multiple downstream tasks
task1 >> [task2, task3, task4]

# Multiple upstream tasks
[task1, task2, task3] >> task4

# Mixed patterns
task1 >> task2 >> [task3, task4]
[task3, task4] >> task5
```

#### Branching with PythonBranchOperator

```python
from airflow.operators.python import BranchPythonOperator
from airflow.utils.trigger_rule import TriggerRule

def choose_branch(**context):
    day_of_week = context['execution_date'].strftime('%A')

    if day_of_week in ['Saturday', 'Sunday']:
        return 'weekend_task'
    else:
        return 'weekday_task'

branching_task = BranchPythonOperator(
    task_id='branching',
    python_callable=choose_branch,
    provide_context=True
)

weekend_task = PythonOperator(
    task_id='weekend_task',
    python_callable=weekend_processing,
    trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS
)

weekday_task = PythonOperator(
    task_id='weekday_task',
    python_callable=weekday_processing,
    trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS
)

branching_task >> [weekend_task, weekday_task]
```

### XCom (Cross-Communication)

Share data between tasks using XCom:

#### Pushing Data

```python
def extract_data(**context):
    data = fetch_data_from_api()

    # Push to XCom
    context['ti'].xcom_push(
        key='extracted_data',
        value=data,
        # Optional: specify DAG run for sharing between DAGs
        execution_date=context['execution_date']
    )

    return data  # Automatically pushed to XCom with key 'return_value'
```

#### Pulling Data

```python
def process_data(**context):
    ti = context['ti']

    # Pull from upstream task
    extracted_data = ti.xcom_pull(
        key='extracted_data',
        task_ids='extract',
        # Optional: Pull from specific DAG run
        execution_date=context['execution_date']
    )

    # Process data
    processed_data = transform_data(extracted_data)
    return processed_data
```

Using the `@task` decorator (Airflow 2.0+):

```python
from airflow.decorators import task
from typing import Dict

@task
def extract() -> Dict:
    return fetch_data()

@task
def transform(data: Dict) -> Dict:
    return process_data(data)

@task
def load(data: Dict):
    save_to_database(data)

# TaskFlow API automatically handles XCom
extract_task = extract()
transform_task = transform(extract_task)
load_task = load(transform_task)
```

### DAG Parameters

Make DAGs configurable at runtime:

```python
from airflow.models.param import Param
from airflow.models import DAG

with DAG(
    dag_id='parameterized_dag',
    params={
        'table_name': Param(
            default='customers',
            type='string',
            title='Table name',
            description='Name of the table to process'
        ),
        'date_range': Param(
            default=30,
            type='number',
            title='Date range (days)',
            description='Number of days to backfill'
        ),
        'validate': Param(
            default=True,
            type='boolean',
            title='Run validation',
            description='Whether to run data quality checks'
        )
    },
    # ... other configurations
) as dag:

    def process_data(**context):
        table_name = context['params']['table_name']
        date_range = context['params']['date_range']
        validate = context['params']['validate']

        logger.info(f"Processing table: {table_name}, range: {date_range} days")
```

Trigger with parameters via CLI:

```bash
airflow dags trigger parameterized_dag --conf '{"table_name": "orders", "date_range": 7}'
```

### Error Handling and Retries

#### Configure Retries

```python
default_args = {
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
    'max_retry_delay': timedelta(minutes=30),
}
```

#### Handle Failures

```python
def resilient_task(**context):
    try:
        result = risky_operation()
        return result
    except SpecificException as e:
        logger.error(f"Specific error occurred: {e}")
        # Re-raise for Airflow to handle retries
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        # Send alert
        send_alert(f"Task failed: {context['task_instance_key_str']}")
        raise
```

## Testing DAGs

Testing is a critical component of reliable Airflow deployments. This template includes a comprehensive testing suite.

### Test Structure

```
tests/
├── __init__.py
├── conftest.py              # Pytest fixtures
├── test_dag.py             # DAG validation tests
├── test_utils.py           # Utilities tests
├── test_operators.py       # Custom operator tests
├── fixtures.py             # Test data
└── mocks/
    ├── __init__.py
    └── airflow_mocks.py    # Airflow object mocks
```

### Running Tests

```bash
# Install test dependencies
pip install -r requirements.txt

# Run all tests with coverage
pytest tests/ -v --cov=dags --cov-report=html

# Run specific test file
pytest tests/test_dag.py -v

# Run tests matching pattern
pytest tests/ -k "test_dag" -v

# Run with coverage report
pytest tests/ --cov=dags --cov-report=term-missing

# Run tests in parallel
pytest tests/ -n auto
```

### DAG Validation Tests

Verify DAG structure and configuration:

```python
"""Tests for customer ETL DAG."""

import pytest
from datetime import datetime
from airflow.models import DagBag
import os

@pytest.fixture
def dag_bag():
    """Load DAGs from the dags folder."""
    os.environ['AIRFLOW_HOME'] = os.getcwd()
    return DagBag(dag_folder='dags', include_examples=False)

def test_dag_loaded(dag_bag):
    """Test that DAG is loaded without errors."""
    dag = dag_bag.get_dag(dag_id='customer-etl-daily')
    assert dag is not None
    assert len(dag_bag.import_errors) == 0

def test_dag_schedule(dag_bag):
    """Test that DAG has the correct schedule."""
    dag = dag_bag.get_dag('customer-etl-daily')
    assert dag.schedule_interval == '0 2 * * *'

def test_dag_default_args(dag_bag):
    """Test that DAG has correct default arguments."""
    dag = dag_bag.get_dag('customer-etl-daily')
    assert dag.default_args['owner'] == 'data-engineering'
    assert dag.default_args['retries'] == 3

def test_dag_has_all_tasks(dag_bag):
    """Test that DAG has all required tasks."""
    dag = dag_bag.get_dag('customer-etl-daily')
    task_ids = [task.task_id for task in dag.tasks]
    required_tasks = ['start', 'extract', 'transform', 'load', 'validate', 'end']

    for task_id in required_tasks:
        assert task_id in task_ids, f"Missing required task: {task_id}"

def test_task_dependencies(dag_bag):
    """Test that tasks have correct dependencies."""
    dag = dag_bag.get_dag('customer-etl-daily')

    # Test extract task upstream
    extract_task = dag.get_task('extract')
    upstream_tasks = [t.task_id for t in extract_task.upstream_list]
    assert 'start' in upstream_tasks

    # Test transform task upstream
    transform_task = dag.get_task('transform')
    upstream_tasks = [t.task_id for t in transform_task.upstream_list]
    assert 'extract' in upstream_tasks

    # Test load task upstream
    load_task = dag.get_task('load')
    upstream_tasks = [t.task_id for t in load_task.upstream_list]
    assert 'transform' in upstream_tasks

def test_max_active_runs(dag_bag):
    """Test DAG max_active_runs configuration."""
    dag = dag_bag.get_dag('customer-etl-daily')
    assert dag.max_active_runs == 1

def test_dag_catchup(dag_bag):
    """Test that catchup is disabled."""
    dag = dag_bag.get_dag('customer-etl-daily')
    assert dag.catchup is False

def test_dag_tags(dag_bag):
    """Test that DAG has correct tags."""
    dag = dag_bag.get_dag('customer-etl-daily')
    expected_tags = {'data', 'etl', 'customer', 'daily'}
    assert set(dag.tags) == expected_tags
```

### Testing Individual Task Functions

```python
"""Test individual task functions."""

from unittest.mock import Mock, patch, MagicMock
import pytest
from dags.customer_etl_dag import extract_customer_data, transform_customer_data

def test_extract_customer_data():
    """Test the extract function."""
    # Mock Airflow context
    context = {
        'execution_date': datetime(2024, 1, 15),
        'ti': Mock()
    }

    result = extract_customer_data(**context)

    assert result is not None
    assert 'validation_context' in result
    assert result['validation_context']['status'] == 'completed'

def test_extract_customer_data_with_database():
    """Test extract with mocked database connection."""
    context = {
        'execution_date': datetime(2024, 1, 15),
        'ti': Mock()
    }

    with patch('psycopg2.connect') as mock_connect:
        mock_cursor = MagicMock()
        mock_cursor.fetchall.return_value = [
            (1, 'user1', 'user1@email.com'),
            (2, 'user2', 'user2@email.com')
        ]
        mock_cursor.rowcount = 2

        mock_conn = MagicMock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        from dags.customer_etl_dag import extract_customer_data
        result = extract_customer_data(**context)

        assert result['validation_context']['extracted_count'] == 2

def test_transform_customer_data():
    """Test the transform function."""
    context = {
        'ti': Mock()
    }

    # Mock XCom pull from extract task
    context['ti'].xcom_pull.return_value = {
        'validation_context': {
            'extracted_count': 100
        }
    }

    result = transform_customer_data(**context)

    assert 'validation_context' in result
    assert result['validation_context']['transformed_count'] == 100
```

### Testing Custom Operators

```python
"""Test custom operators."""

import pytest
from unittest.mock import Mock, patch
from plugins.custom_operators import DataQualityCheckOperator

def test_data_quality_check_operator():
    """Test custom data quality operator."""
    task = DataQualityCheckOperator(
        task_id='quality_check',
        query='SELECT COUNT(*) FROM customers WHERE created_at < now()',
        expected_result=1000,
        conn_id='postgres_default'
    )

    # Mock the database connection and execution
    with patch('plugins.custom_operators.postgres_hook') as mock_hook:
        mock_conn = Mock()
        mock_conn.execute.return_value = [(1000,)]
        mock_hook.get_conn.return_value = mock_conn

        # Mock the context
        context = {'execution_date': datetime(2024, 1, 15)}

        # Should not raise exception if result matches expected
        task.execute(context)

def test_data_quality_check_fails():
    """Test that quality check fails when unexpected result."""
    task = DataQualityCheckOperator(
        task_id='quality_check',
        query='SELECT COUNT(*) FROM customers',
        expected_result=1000,
        conn_id='postgres_default'
    )

    with patch('plugins.custom_operators.postgres_hook') as mock_hook:
        mock_conn = Mock()
        mock_conn.execute.return_value = [(500,)]  # Different result
        mock_hook.get_conn.return_value = mock_conn

        context = {'execution_date': datetime(2024, 1, 15)}

        with pytest.raises(ValueError, match="Data quality check failed"):
            task.execute(context)
```

### Test Fixtures

```python
# tests/conftest.py

import pytest
from datetime import datetime
from unittest.mock import Mock

@pytest.fixture
def test_context():
    """Provide standard Airflow context for testing."""
    return {
        'execution_date': datetime(2024, 1, 15),
        'ds': '2024-01-15',
        'ds_nodash': '20240115',
        'ti': Mock(),
        'dag_run': Mock(),
        'params': {},
        'logical_date': datetime(2024, 1, 15),
        'data_interval_start': datetime(2024, 1, 15),
        'data_interval_end': datetime(2024, 1, 16),
    }

@pytest.fixture
def sample_customer_data():
    """Provide sample customer data for tests."""
    return [
        {'id': 1, 'name': 'Alice', 'email': 'alice@email.com', 'created_at': '2024-01-01'},
        {'id': 2, 'name': 'Bob', 'email': 'bob@email.com', 'created_at': '2024-01-02'},
        {'id': 3, 'name': 'Charlie', 'email': 'charlie@email.com', 'created_at': '2024-01-03'},
    ]

@pytest.fixture
def mock_db_connection():
    """Provide mocked database connection."""
    from unittest.mock import MagicMock

    mock_cursor = MagicMock()
    mock_cursor.execute.return_value = None
    mock_cursor.fetchall.return_value = []
    mock_cursor.rowcount = 0

    mock_conn = MagicMock()
    mock_conn.cursor.return_value = mock_cursor

    return mock_conn
```

### Mocking Airflow Components

```python
# tests/mocks/airflow_mocks.py

from unittest.mock import Mock
from datetime import datetime

def create_mock_context(**kwargs):
    """Create a mock Airflow context."""
    mock = Mock()
    mock.execution_date = datetime(2024, 1, 15)
    mock.ds = '2024-01-15'
    mock.ds_nodash = '20240115'
    mock.log = Mock()
    mock.ti = Mock()
    mock.dag_run = Mock()
    mock.params = {}

    for k, v in kwargs.items():
        setattr(mock, k, v)

    return mock

def create_mock_task_instance():
    """Create a mock task instance for testing."""
    mock = Mock()
    mock.xcom_pull.return_value = None
    mock.xcom_push.return_value = None
    mock.log = Mock()
    mock.task_instance_key_str = "test_dag__test_task__20240115"
    mock.try_number = 1

    return mock
```

## Local Development

### Setting Up Airflow Locally with Docker

Create a `docker-compose.yml` file at project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres-db-volume:/var/lib/postgresql/data
    ports:
      - '5432:5432'
    healthcheck:
      test: ['CMD', 'pg_isready', '-U', 'airflow']
      interval: 10s
      retries: 5

  airflow-init:
    image: apache/airflow:2.7.0
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      _AIRFLOW_WWW_USER_USERNAME: admin
      _AIRFLOW_WWW_USER_PASSWORD: admin
      _AIRFLOW_WWW_USER_FIRSTNAME: Admin
      _AIRFLOW_WWW_USER_LASTNAME: User
      _AIRFLOW_WWW_USER_EMAIL: admin@airflow.com
    volumes:
      - .:/opt/airflow/dags
      - ./tests:/opt/airflow/tests
      - ./plugins:/opt/airflow/plugins
      - ./requirements.txt:/requirements.txt
    command:
      [
        'bash',
        '-c',
        'pip install -r requirements.txt && airflow db init && airflow users create -r Admin -u admin -f Admin -l User -p admin -e admin@airflow.com',
      ]

  airflow-webserver:
    image: apache/airflow:2.7.0
    restart: always
    depends_on:
      - airflow-init
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
    volumes:
      - .:/opt/airflow/dags
      - ./tests:/opt/airflow/tests
      - ./plugins:/opt/airflow/plugins
    ports:
      - '8080:8080'
    command: airflow webserver

  airflow-scheduler:
    image: apache/airflow:2.7.0
    restart: always
    depends_on:
      - airflow-init
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
    volumes:
      - .:/opt/airflow/dags
      - ./tests:/opt/airflow/tests
      - ./plugins:/opt/airflow/plugins
    command: airflow scheduler

volumes:
  postgres-db-volume:
```

### Starting Local Airflow

```bash
# Start all services in background
docker-compose up -d

# Watch logs
docker-compose logs -f

# Check status
docker-compose ps
```

### Accessing Airflow UI

Once services are running:

- **Web UI**: http://localhost:8080
- **Username**: admin
- **Password**: admin

### Running DAGs Locally

```bash
# List all DAGs
docker-compose exec airflow-scheduler airflow dags list

# Trigger a DAG
docker-compose exec airflow-scheduler airflow dags trigger customer-etl-daily

# Run a specific task
docker-compose exec airflow-scheduler airflow tasks test customer-etl-daily extract 2024-01-15

# Clear task instances
docker-compose exec airflow-scheduler airflow tasks clear customer-etl-daily

# Check DAG import errors
docker-compose exec airflow-scheduler airflow dags list-import-errors
```

### Local DAG Testing

```bash
# Test DAG import without starting Airflow
python -c "from airflow.models import DagBag; bag = DagBag('dags'); print(bag.import_errors)"

# Run specific task with specific execution date
docker-compose exec airflow-scheduler airflow tasks test customer-etl-daily extract 2024-01-15

# Run full DAG test
docker-compose exec airflow-scheduler airflow dags backfill customer-etl-daily --start-date 2024-01-01 --end-date 2024-01-07
```

### Using Python Virtual Environment

If you prefer local Python environment over Docker:

```bash
# Set up environment variables
export AIRFLOW_HOME=$(pwd)
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export AIRFLOW__CORE__EXECUTOR=LocalExecutor

# Initialize Airflow metadata database
airflow db init

# Create admin user
airflow users create -r Admin -u admin -f Admin -l User -p admin -e admin@airflow.com

# Start webserver
airflow webserver --port 8080

# In another terminal, start scheduler
airflow scheduler
```

### VSCode Debugging

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Debug DAG",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/tests/test_dag.py",
      "console": "integratedTerminal",
      "justMyCode": false,
      "env": {
        "AIRFLOW_HOME": "${workspaceFolder}",
        "PYTHONPATH": "${workspaceFolder}:${workspaceFolder}/dags"
      }
    },
    {
      "name": "Python: Debug Task",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/debug_task.py",
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ]
}
```

Create `debug_task.py`:

```python
#!/usr/bin/env python
"""Debug individual task functions."""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'dags'))

from datetime import datetime
from dags.customer_etl_dag import extract_customer_data

# Mock context for debugging
mock_context = {
    'execution_date': datetime(2024, 1, 15),
    'ds': '2024-01-15',
    'ti': type('MockTI', (), {'xcom_push': lambda *args, **kwargs: None})()
}

# Test the function
result = extract_customer_data(**mock_context)
print(f"Debug result: {result}")
```

## Operators and Hooks

### Using Built-in Operators

#### Database Operators

```python
from airflow.providers.postgres.operators.postgres import PostgresOperator

# Execute SQL
create_table = PostgresOperator(
    task_id='create_table',
    postgres_conn_id='postgres_default',
    sql="""
        CREATE TABLE IF NOT EXISTS customer_metrics (
            date DATE,
            customer_id INTEGER,
            total_orders INTEGER,
            total_revenue DECIMAL(10,2),
            created_at TIMESTAMP DEFAULT NOW()
        )
    """
)

# Template SQL
insert_metrics = PostgresOperator(
    task_id='insert_metrics',
    postgres_conn_id='postgres_default',
    sql='sql/insert_customer_metrics.sql',  # External file
    parameters={
        'date': '{{ ds }}'
    }
)
```

#### File Operators

```python
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.providers.apache.hdfs.sensors.hdfs import HdfsSensor

# Wait for file in HDFS
wait_for_file = HdfsSensor(
    task_id='wait_for_file',
    hdfs_conn_id='hdfs_default',
    filepath='/data/customers/{{ ds }}.csv',
    timeout=60 * 30,  # 30 minutes
    retries=0
)

# Submit Spark job
spark_job = SparkSubmitOperator(
    task_id='spark_job',
    application='jobs/customer_processing.py',
    application_args=[
        '--date', '{{ ds }}',
        '--input', '/data/customers/{{ ds }}.csv',
        '--output', '/data/processed/{{ ds }}'
    ],
    conf={
        'spark.driver.memory': '4g',
        'spark.executor.memory': '8g'
    }
)
```

#### Cloud Operators

```python
from airflow.providers.amazon.aws.operators.s3 import S3CreateBucketOperator, S3DeleteBucketOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

# AWS S3 operations
create_s3_bucket = S3CreateBucketOperator(
    task_id='create_s3_bucket',
    bucket_name='customer-data-{{ ds }}',
    region_name='us-east-1'
)

# BigQuery operations
bigquery_job = BigQueryInsertJobOperator(
    task_id='bigquery_job',
    configuration={
        "query": {
            "query": """
                SELECT * FROM `project.dataset.customers`
                WHERE DATE(created_at) = "{{ ds }}"
            """,
            "useLegacySql": False
        }
    },
    location='US'
)
```

### Creating Custom Operators

Create reusable task logic in `plugins/`:

```python
# plugins/custom_operators.py

from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class DataQualityCheckOperator(BaseOperator):
    """
    Performs data quality checks on a database table.

    Checks include:
    - Row count validation
    - Null value checks
    - Data type validation
    - Referential integrity

    :param conn_id: Connection ID to the database
    :param table_name: Name of the table to validate
    :param expected_min_rows: Minimum expected rows
    :param expected_max_rows: Maximum expected rows
    :param sql_quality_checks: Additional SQL quality check queries
    :param tolerance_percent: Percentage tolerance for row count validation
    """

    @apply_defaults
    def __init__(
        self,
        conn_id: str,
        table_name: str,
        expected_min_rows: int = 1,
        expected_max_rows: Optional[int] = None,
        sql_quality_checks: Optional[Dict[str, str]] = None,
        tolerance_percent: float = 5.0,
        *args,
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.conn_id = conn_id
        self.table_name = table_name
        self.expected_min_rows = expected_min_rows
        self.expected_max_rows = expected_max_rows
        self.sql_quality_checks = sql_quality_checks or {}
        self.tolerance_percent = tolerance_percent

    def execute(self, context):
        """Execute data quality checks."""
        import psycopg2
        from psycopg2 import Error

        connection = None

        try:
            # Establish database connection
            connection = psycopg2.connect(self.conn_id)
            cursor = connection.cursor()

            # Check 1: Row count validation
            row_count = self._check_row_count(cursor)

            # Check 2: Null value validation
            self._check_null_values(cursor)

            # Check 3: Run custom SQL checks
            self._run_custom_checks(cursor)

            # Check 4: Referential integrity
            self._check_referential_integrity(cursor)

            logger.info(f"Data quality checks passed for table {self.table_name}")

        except Error as e:
            logger.error(f"Database error during quality check: {e}")
            raise
        finally:
            if connection:
                connection.close()

    def _check_row_count(self, cursor):
        """Check if row count is within expected range."""
        query = f"SELECT COUNT(*) FROM {self.table_name}"
        cursor.execute(query)
        actual_count = cursor.fetchone()[0]

        if actual_count < self.expected_min_rows:
            error_msg = (
                f"Row count validation failed for {self.table_name}. "
                f"Expected at least {self.expected_min_rows} rows, "
                f"but found {actual_count}"
            )
            logger.error(error_msg)
            raise ValueError(error_msg)

        if self.expected_max_rows and actual_count > self.expected_max_rows:
            warning_msg = (
                f"Row count exceeded maximum for {self.table_name}. "
                f"Expected at most {self.expected_max_rows} rows, "
                f"but found {actual_count}"
            )
            logger.warning(warning_msg)

        return actual_count

    def _check_null_values(self, cursor):
        """Check for unexpected null values in critical fields."""
        critical_fields = ['id', 'created_at']  # Define based on your schema

        for field in critical_fields:
            query = f"SELECT COUNT(*) FROM {self.table_name} WHERE {field} IS NULL"
            cursor.execute(query)
            null_count = cursor.fetchone()[0]

            if null_count > 0:
                raise ValueError(
                    f"Null value check failed for {self.table_name}.{field}. "
                    f"Found {null_count} null values"
                )

    def _run_custom_checks(self, cursor):
        """Run custom SQL quality checks."""
        for check_name, check_query in self.sql_quality_checks.items():
            try:
                cursor.execute(check_query)
                result = cursor.fetchone()

                if not result or not result[0]:
                    raise ValueError(f"Custom quality check failed: {check_name}")

                logger.info(f"Custom check passed: {check_name}")

            except Exception as e:
                logger.error(f"Error in custom check '{check_name}': {e}")
                raise

class ApiRequestOperator(BaseOperator):
    """
    Make authenticated API requests with error handling.

    :param endpoint: API endpoint (relative to base URL)
    :param method: HTTP method (GET, POST, PUT, DELETE)
    :param connection_id: Airflow connection ID for API
    :param headers: Additional headers
    :param payload: Request payload for POST/PUT
    :param parameters: Query parameters
    :param retry_codes: HTTP status codes to retry
    :param timeout: Request timeout in seconds
    """

    @apply_defaults
    def __init__(
        self,
        endpoint: str,
        method: str = 'GET',
        connection_id: str,
        headers: Optional[Dict[str, str]] = None,
        payload: Optional[Dict[str, Any]] = None,
        parameters: Optional[Dict[str, str]] = None,
        retry_codes: tuple = (429, 500, 502, 503, 504),
        timeout: int = 30,
        *args,
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self.endpoint = endpoint
        self.method = method.upper()
        self.connection_id = connection_id
        self.headers = headers or {}
        self.payload = payload
        self.parameters = parameters
        self.retry_codes = retry_codes
        self.timeout = timeout

    def execute(self, context):
        """Execute API request."""
        import requests
        from airflow.hooks.base import BaseHook

        # Get connection details
        conn = BaseHook.get_connection(self.connection_id)

        # Construct full URL
        base_url = conn.host
        if conn.port:
            base_url = f"{base_url}:{conn.port}"

        full_url = f"{base_url}{self.endpoint}"

        # Prepare authentication
        auth = None
        if conn.login and conn.password:
            auth = (conn.login, conn.password)

        # Prepare headers
        headers = {
            'Content-Type': 'application/json',
            **self.headers
        }

        # Add API key if present
        if conn.extra:
            import json
            try:
                extra_data = json.loads(conn.extra)
                if 'api_key' in extra_data:
                    headers['Authorization'] = f"Bearer {extra_data['api_key']}"
            except json.JSONDecodeError:
                pass

        # Prepare request
        request_kwargs = {
            'method': self.method,
            'url': full_url,
            'auth': auth,
            'headers': headers,
            'timeout': self.timeout,
            'params': self.parameters
        }

        if self.payload and self.method in ['POST', 'PUT']:
            request_kwargs['json'] = self.payload

        # Execute request with retries
        session = requests.Session()
        retry_adapter = requests.adapters.HTTPAdapter(
            max_retries=requests.packages.urllib3.util.retry.Retry(
                total=3,
                backoff_factor=1,
                status_forcelist=self.retry_codes,
                method_whitelist=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE"]
            )
        )
        session.mount("http://", retry_adapter)
        session.mount("https://", retry_adapter)

        response = session.request(**request_kwargs)

        # Log response
        self.log.info(f"Request to {full_url} returned status {response.status_code}")

        # Check for errors
        response.raise_for_status()

        # Return response data
        try:
            return response.json()
        except ValueError:
            return response.text
```

### Using Custom Operators in DAGs

```python
from plugins.custom_operators import DataQualityCheckOperator, ApiRequestOperator

# Use data quality operator
data_quality = DataQualityCheckOperator(
    task_id='validate_customer_data',
    conn_id='warehouse_db',
    table_name='customers',
    expected_min_rows=1000,
    sql_quality_checks={
        'unique_ids': 'SELECT COUNT(DISTINCT id) = COUNT(*) FROM customers',
        'valid_emails': "SELECT COUNT(*) = 0 FROM customers WHERE email NOT LIKE '%@%'"
    }
)

# Use API operator
fetch_customer_data = ApiRequestOperator(
    task_id='fetch_customer_api',
    endpoint='/customers',
    method='GET',
    connection_id='customer_api',
    parameters={'date': '{{ ds }}'}
)
```

## Connections and Variables

### Managing Airflow Connections

Connections store credentials and connection details for external systems.

#### Creating Connections via UI

1. Go to "Admin" → "Connections" in Airflow UI
2. Click "Add a new record"
3. Configure connection parameters

#### Creating Connections via CLI

```bash
# PostgreSQL connection
airflow connections add 'postgres_default' \
    --conn-type postgres \
    --conn-host localhost \
    --conn-port 5432 \
    --conn-login airflow \
    --conn-password airflow \
    --conn-schema airflow

# HTTP API connection
airflow connections add 'customer_api' \
    --conn-type http \
    --conn-host https://api.customers.com \
    --conn-login apiuser \
    --conn-password apipassword
    --conn-extra '{"api_key": "your-api-key"}'

# Amazon S3 connection
airflow connections add 'aws_s3' \
    --conn-type s3 \
    --conn-extra '{
        "aws_access_key_id": "your-access-key",
        "aws_secret_access_key": "your-secret-key",
        "region_name": "us-east-1"
    }'
```

#### Environment Variables for Connections

```bash
# PostgreSQL
export AIRFLOW_CONN_POSTGRES_DEFAULT=postgresql://airflow:airflow@localhost:5432/airflow

# HTTP
export AIRFLOW_CONN_CUSTOMER_API=https://apiuser:apipassword@api.customers.com

# JSON format for extra parameters
export AIRFLOW_CONN_CUSTOMER_API='{"conn_type": "https", "host": "api.customers.com", "password": "apikey"}'
```

### Managing Airflow Variables

Variables store configuration values that may change between environments.

#### Creating Variables

```python
from airflow.models import Variable

# Set variable
Variable.set("customer_api_timeout", "30")

# Get variable
timeout = Variable.get("customer_api_timeout", default_var="60")

# Get variable as JSON
api_config = Variable.get("customer_api_config", deserialize_json=True)
```

#### Variables via CLI

```bash
# Set a variable
airflow variables set customer_api_timeout 30

# Set JSON variable
airflow variables set customer_api_config '{"timeout": 30, "retries": 3}'

# Get a variable
airflow variables get customer_api_timeout

# List all variables
airflow variables list

# Delete a variable
airflow variables delete customer_api_timeout
```

#### Environment Variables for Variables

```bash
export AIRFLOW_VAR_CUSTOMER_API_TIMEOUT=30
export AIRFLOW_VAR_CUSTOMER_API_CONFIG='{"timeout": 30, "retries": 3}'
```

### Best Practices for Connections and Variables

1. **Use connection IDs instead of hardcoded credentials**

   ```python
   # Good: Uses connection from Airflow
   PostgresOperator(postgres_conn_id='warehouse_db', ...)

   # Avoid: Hardcoded credentials
   import psycopg2
   conn = psycopg2.connect(host='localhost', password='secret')
   ```

2. **Use variables for configuration**

   ```python
   # Store thresholds, flags, and configuration
   validation_enabled = Variable.get('enable_data_validation', default_var=True)
   retry_limit = int(Variable.get('api_retry_limit', default_var='3'))
   ```

3. **Set appropriate connection types**

   - Use `HTTP` for APIs
   - Use `JDBC` for database connections when needed
   - Use `AWS` or cloud-specific types for cloud resources

4. **Secure sensitive data**

   - Store passwords in connections, not in code
   - Use Airflow's built-in secret management
   - Consider using secret backends (AWS Secrets Manager, HashiCorp Vault)

5. **Test connections in development**
   ```bash
   # Test connection from CLI
   airflow connections test postgres_default
   ```

## CI/CD Pipeline

The template includes a comprehensive GitHub Actions workflow for continuous integration and deployment.

### Pipeline Overview

```d2
direction: down

trigger: Pull Request/Push {
  style.fill: "#e3f2fd"
}

lint: Lint {
  style.fill: "#fff3e0"
  label: "Lint\n- Code formatting (Black, isort)\n- Linting (flake8)\n- Type checking (mypy)"
}

test: Test {
  style.fill: "#e8f5e9"
  label: "Test\n- Unit tests (pytest)\n- Coverage reporting\n- Parallel execution"
}

dag-validation: DAG Validation {
  style.fill: "#f3e5f5"
  label: "DAG Validation\n- Load all DAGs\n- Check for import errors\n- Validate DAG structure"
}

deploy: Deploy {
  style.fill: "#e0f7fa"
  label: "Deploy\n- Deploy to staging/production\n- (Only on main branch push)"
}

trigger -> lint -> test -> dag-validation -> deploy
```

### GitHub Actions Configuration

The `.github/workflows/airflow.yaml` file defines the pipeline:

```yaml
name: Airflow CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: '3.11'

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install black flake8 isort mypy

      - name: Check formatting
        run: black --check .

      - name: Check import ordering
        run: isort --check-only .

      - name: Lint code
        run: flake8 dags/ tests/ --max-line-length=100

      - name: Type checking
        run: mypy dags/ --ignore-missing-imports

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Initialize Airflow
        run: |
          export AIRFLOW_HOME=$(pwd)
          airflow db init

      - name: Run tests
        run: pytest tests/ -v --cov=dags --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          fail_ci_if_error: false

  dag-validation:
    name: DAG Validation
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install apache-airflow psycopg2-binary

      - name: Initialize Airflow
        run: |
          export AIRFLOW_HOME=$(pwd)
          airflow db init

      - name: Validate DAGs
        run: |
          export AIRFLOW_HOME=$(pwd)
          python3 -c "
          from airflow.models import DagBag
          import sys

          dag_bag = DagBag(dag_folder='dags', include_examples=False)

          if dag_bag.import_errors:
              print('❌ DAG Import Errors:')
              for dag_id, error in dag_bag.import_errors.items():
                  print(f'  {dag_id}: {error}')
              sys.exit(1)

          print(f'✅ Successfully validated {len(dag_bag.dags)} DAGs:')
          for dag_id in dag_bag.dags.keys():
              print(f'  - {dag_id}')
          "

  deploy:
    name: Deploy DAGs
    runs-on: ubuntu-latest
    needs: [test, dag-validation]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: ${{ values.environment }}
    steps:
      - uses: actions/checkout@v4

      # Configure AWS for S3 deployment
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
        if: ${{ values.environment == 'production' }}

      # Deploy to S3 (for AWS MWAA or similar)
      - name: Sync DAGs to S3
        run: |
          echo "Deploying DAGs to S3..."
          aws s3 sync dags/ s3://${{ secrets.DAG_S3_BUCKET }}/dags/
          echo "DAGs deployment complete!"
        if: ${{ values.environment == 'production' }}

      # Deploy via Git (for self-hosted Airflow)
      - name: Deploy to Airflow Git repository
        run: |
          echo "Deploying DAGs via Git..."
          git config --global user.email "airflow-deployment@company.com"
          git config --global user.name "Airflow Deployment"

          git clone ${{ secrets.AIRFLOW_GIT_REPO }} airflow-dags
          cd airflow-dags

          cp -r ../dags/* dags/
          cp -r ../plugins/* plugins/

          git add dags/ plugins/
          git commit -m "Automated deployment of DAGs from ${{ github.sha }}"
          git push origin main
        if: ${{ values.environment == 'staging' }}

      # Notify deployment
      - name: Notify deployment
        run: |
          echo "🚀 Successfully deployed DAGs to ${{ values.environment }} environment"
```

### Customizing the Pipeline

#### Add Pre-commit Hooks

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
        args: [--max-line-length=100]

  - repo: local
    hooks:
      - id: dag-validate
        name: Validate Airflow DAGs
        entry: python -c "from airflow.models import DagBag; d = DagBag(); exit(len(d.import_errors))"
        language: system
        pass_filenames: false
```

Install pre-commit:

```bash
pip install pre-commit
pre-commit install
```

#### Environment-Specific Deployments

```yaml
# Add to workflow
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    environment: staging
    # ... deployment steps for staging

  deploy-production:
    if: github.ref == 'refs/heads/main'
    environment: production
    # ... deployment steps for production
```

#### Notification Integration

Add Slack notifications:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "DAGs deployed to ${{ values.environment }}",
        "attachments": [{
          "fields": [
            {"title": "Environment", "value": "${{ values.environment }}"},
            {"title": "Commit", "value": "${{ github.sha }}"},
            {"title": "User", "value": "${{ github.actor }}"}
          ]
        }]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Best Practices

### DAG Design Patterns

#### 1. Idempotency

Tasks should be safe to run multiple times without side effects:

```python
def load_data(**context):
    """Idempotent data loading."""
    # Delete existing data for this date first (idempotency)
    delete_query = "DELETE FROM orders WHERE date = '{{ ds }}'"
    execute_query(delete_query)

    # Then insert new data
    insert_query = "INSERT INTO orders SELECT * FROM staging.orders"
    execute_query(insert_query)
```

#### 2. Task Granularity

Keep tasks focused and atomic:

```python
# ❌ Bad: Monolithic task
def etl_all(**context):
    extract()
    transform()
    load()
    validate()

# ✅ Good: Separate tasks
task1 = PythonOperator(task_id='extract', python_callable=extract)
task2 = PythonOperator(task_id='transform', python_callable=transform)
task3 = PythonOperator(task_id='load', python_callable=load)
task4 = PythonOperator(task_id='validate', python_callable=validate)

task1 >> task2 >> task3 >> task4
```

#### 3. Error Handling

Implement graceful degradation:

```python
def process_data(**context):
    try:
        result = risky_operation()
    except RecoverableError as e:
        logger.warning(f"Recoverable error: {e}")
        context['task_instance'].xcom_push(key='partial_success', value=True)
    except FatalError as e:
        logger.error(f"Fatal error: {e}")
        send_alert(f"Pipeline failed: {e}")
        raise
```

#### 4. Configuration Management

Use variables for environment-specific settings:

```python
from airflow.models import Variable

def create_report(**context):
    # Get configuration from variables
    recipient_list = Variable.get('report_recipients', deserialize_json=True)
    format = Variable.get('report_format', default_var='pdf')

    generate_report(format=format, recipients=recipient_list)
```

### Retry Strategy

Configure appropriate retry behavior:

```python
default_args = {
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
    'max_retry_delay': timedelta(minutes=30),
}
```

- **Transient failures**: API timeouts, network issues → Use retries
- **Permanent failures**: Invalid data, authentication errors → Fail fast

### SLA Monitoring

Track task completion times:

```python
from datetime import timedelta

with DAG(
    dag_id='critical_pipeline',
    default_args=default_args,
    sla_miss_callback=sla_miss_alert,
) as dag:

    critical_task = PythonOperator(
        task_id='critical_task',
        python_callable=important_processing,
        sla=timedelta(hours=2),  # Alert if takes longer than 2 hours
    )

def sla_miss_alert(dag, task_list, blocking_task_list, sla_miss):
    """Send alert when SLA is missed."""
    message = f"SLA miss on {dag.dag_id}: {sl{{ 'user': task_list }}a_miss}"
    send_alert(message)
```

### Resource Management

#### Pool Usage

Control concurrent execution:

```python
# In Airflow UI: Admin → Pools
# Create pool: "api_pool", slots: 5

task_with_pool = PythonOperator(
    task_id='rate_limited_api_call',
    python_callable=call_api,
    pool='api_pool',
    pool_slots=1,  # Use 1 slot from the pool
)
```

#### Priority Weights

Control execution order:

```python
critical_task = PythonOperator(
    task_id='priority_task',
    python_callable=process_data,
    priority_weight=10,  # Higher = executed first
)

normal_task = PythonOperator(
    task_id='normal_task',
    python_callable=process_data,
    priority_weight=5,
)
```

### Documentation and Comments

```python
"""
Monthly Sales Report DAG

Generates monthly sales report and sends to stakeholders.
Owner: sales-analytics-team
Schedule: First day of month at 6 AM
Dependencies: sales-db, email-service
"""

def generate_report(**context):
    """
    Generate monthly sales report.

    Fetches data from sales database, aggregates metrics,
    and creates visualizations. Handles missing data gracefully
    by using previous month's data as fallback.

    Args:
        context: Airflow context with execution_date, etc.

    Returns:
        dict: Report metadata including file paths and record counts

    Raises:
        DataQualityError: If critical data quality checks fail
    """
    execution_date = context['execution_date']
    # ... implementation
```

### Testing Strategy

- **Unit tests**: Test individual functions in isolation
- **Integration tests**: Test task interactions
- **DAG validation tests**: Ensure DAGs can be imported
- **End-to-end tests**: Test full workflows with sample data

## Troubleshooting

### Common DAG Issues

#### 1. DAG Not Appearing in UI

**Symptoms**: DAG doesn't show up in Airflow web UI

**Solutions**:

```bash
# Check for import errors
airflow dags list-import-errors

# DAG may be paused
airflow dags unpause dag_id

# Permissions issue
ls -la dags/
chmod +r dags/*.py

# DAG folder configuration
airflow config get-value core dags_folder
```

#### 2. Tasks Stuck in "Running"

**Symptoms**: Tasks remain in running state indefinitely

**Solutions**:

```bash
# Check scheduler logs
airflow scheduler --debug

# Clear stuck task instances
airflow tasks clear dag_id --task-regex task_id

# Check for zombie tasks
airflow jobs check

# Restart scheduler
airflow scheduler --stop
airflow scheduler --daemon
```

#### 3. XCom Errors

**Symptoms**: `KeyError` or `xcom_pull` returns `None`

**Solutions**:

```python
# Add debug logging
def task_function(**context):
    ti = context['ti']
    result = ti.xcom_pull(task_ids='upstream_task')

    if result is None:
        logger.warning("XCom returned None, checking upstream task…")
        # Check if upstream task ran successfully
        dag_run = context['dag_run']
        upstream_task = dag_run.get_task_instance('upstream_task')
        logger.info(f"Upstream state: {upstream_task.state}")
```

#### 4. Connection Errors

**Symptoms**: Connection errors in task logs

**Solutions**:

```bash
# Test connection from CLI
airflow connections test connection_id

# Check connection details in UI
# Admin → Connections

# Verify network access from scheduler container
docker-compose exec airflow-scheduler curl -v http://your-host:port
```

#### 5. Performance Issues

**Symptoms**: Slow DAG execution, scheduler lag

**Solutions**:

```python
# Reduce DAG parsing timeout (in airflow.cfg)
min_file_process_interval = 10
dag_dir_list_interval = 300

# Use LatestOnlyOperator for expensive tasks
from airflow.operators.latest_only import LatestOnlyOperator

latest_only = LatestOnlyOperator(task_id='latest_only', dag=dag)
expensive_task = PythonOperator(task_id='expensive_task', ...)

latest_only >> expensive_task
```

### Log Analysis

Tail logs in real-time:

```bash
# Scheduler logs
docker-compose logs -f airflow-scheduler

# Task logs (local)
tail -f $AIRFLOW_HOME/logs/dag_id/task_id/2024-01-15T00:00:00+00:00/1.log

# Webserver logs
docker-compose logs -f airflow-webserver
```

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)

# In specific task
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
```

### Database Issues

Check PostgreSQL performance:

```sql
-- Check for locks
SELECT * FROM pg_locks WHERE NOT granted;

-- Check long-running queries
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND now() - query_start > interval '1 minute';

-- Check connection count
SELECT count(*) from pg_stat_activity;
```

### Common Error Messages

**"Broken DAG: Undefined variable"**

- Check for syntax errors in DAG files
- Verify all imports are correct
- Check for circular dependencies

**"Executor reports task instance finished but was not in running state"**

- This is often transient, but check for:
  - Database connectivity issues
  - Scheduler restart during task execution

**"Task exited with return code 1"**

- Check task logs for Python errors
- Verify all dependencies are installed
- Check for resource constraints (memory, CPU)

### Debug Mode

Run scheduler in debug mode for detailed logging:

```bash
airflow scheduler --debug
```

## Related Templates

### Data Pipeline Ecosystem

This Airflow template is part of a comprehensive data platform:

- **[data-dbt](https://github.com/your-org/backstage/tree/main/templates/data-dbt)** - Data transformation with dbt

  - Models your data warehouse transformations
  - Integrates seamlessly with Airflow via the `DbtRunOperator`
  - Shared data lineage between Airflow and dbt

- **[data-superset](https://github.com/your-org/backstage/tree/main/templates/data-superset)** - Business intelligence and dashboards
  - Create visualizations on data processed by Airflow DAGs
  - Schedule dashboard cache refreshes via Airflow
  - Alerts on data freshness
- **[data-sisense](https://github.com/your-org/backstage/tree/main/templates/data-sisense)** - Data analytics and embedded BI
- Advanced analytics on processed datasets
- Integration points with Airflow
- Automated report distribution

### Integration Patterns

**Airflow + dbt**: ELT orchestration

```python
from airflow_dbt.operators.dbt_operator import DbtRunOperator

with DAG('customer_pipeline') as dag:
    # Extract and load with Airflow
    extract_task = PythonOperator(task_id='extract', ...)
    load_task = PythonOperator(task_id='load', ...)

    # Transform with dbt
    dbt_run = DbtRunOperator(
        task_id='dbt_transform',
        models=['customers', 'orders'],
        profiles_dir='/dbt',
        target='prod'
    )

    # BI refresh with Superset
    refresh_dashboard = SimpleHttpOperator(
        task_id='refresh_dashboards',
        http_conn_id='superset',
        endpoint='/api/v1/dashboard/refresh',
        method='POST'
    )

    extract_task >> load_task >> dbt_run >> refresh_dashboard
```

**Airflow + Superset**: Dashboard automation

```python
# Refresh Superset dashboard after data update
refresh_task = SimpleHttpOperator(
    task_id='refresh_customer_dashboard',
    http_conn_id='superset_api',
    endpoint='/api/v1/dashboard/{{ var.value.customer_dashboard_id }}/cache',
    method='POST',
    headers={"Authorization": "Bearer {{ var.value.superset_api_token }}"}
)
```

### Template Comparison

| Template          | Purpose                | Language     | Primary Use Case   | Integrates With              |
| ----------------- | ---------------------- | ------------ | ------------------ | ---------------------------- |
| **data-airflow**  | Workflow orchestration | Python       | Data pipelines     | dbt, Superset, Sisense       |
| **data-dbt**      | Data transformation    | SQL + YAML   | Data modeling      | Airflow, Snowflake, BigQuery |
| **data-superset** | BI & Dashboards        | Python + SQL | Data visualization | Airflow, dbt, PostgreSQL     |
| **data-sisense**  | Advanced Analytics     | Multiple     | Complex analytics  | Airflow, cloud DW            |

### Getting Started with Multiple Templates

1. Start with **data-airflow** to create data ingestion framework
2. Add **data-dbt** for data transformation and modeling
3. Use **data-superset** for self-service BI
4. Integrate **data-sisense** for embedded analytics

### Documentation Updates

Keep documentation in sync across templates:

```bash
# Generate cross-template documentation
./tools/generate_integration_docs.sh

# Validate integration points
./tools/validate_integrations.py
```

### Support and Resources

- **Apache Airflow Documentation**: https://airflow.apache.org/docs/
- **Community Forum**: https://github.com/apache/airflow/discussions
- **Slack Community**: https://apache-airflow-slack.herokuapp.com/
- **Template Issues**: Submit issues to your organization's GitHub repository

For internal support:

- **Data Engineering Team**: #data-engineering
- **Office Hours**: Tuesday/Thursday 2-3 PM
- **Email**: data-engineering@company.com
