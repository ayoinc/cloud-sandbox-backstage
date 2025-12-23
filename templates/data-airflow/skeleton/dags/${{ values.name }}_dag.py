"""
${{ values.name }} DAG

${{ values.description }}

Owner: ${{ values.owner }}
Schedule: ${{ values.schedule }}
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.dates import days_ago

# Default arguments for the DAG
default_args = {
    'owner': '${{ values.owner }}',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
}


def extract(**context):
    """Extract data from source systems."""
    print("Extracting data...")
    # TODO: Implement extraction logic
    # Example: Read from API, database, or file storage
    data = {"records": 100, "source": "example"}
    context['ti'].xcom_push(key='extract_result', value=data)
    return data


def transform(**context):
    """Transform extracted data."""
    print("Transforming data...")
    extract_result = context['ti'].xcom_pull(key='extract_result', task_ids='extract')
    # TODO: Implement transformation logic
    # Example: Clean, validate, aggregate data
    transformed = {
        "records_processed": extract_result.get("records", 0),
        "status": "transformed"
    }
    context['ti'].xcom_push(key='transform_result', value=transformed)
    return transformed


def load(**context):
    """Load transformed data to destination."""
    print("Loading data...")
    transform_result = context['ti'].xcom_pull(key='transform_result', task_ids='transform')
    # TODO: Implement load logic
    # Example: Write to data warehouse, database, or file storage
    result = {
        "records_loaded": transform_result.get("records_processed", 0),
        "status": "completed"
    }
    return result


def validate(**context):
    """Validate the loaded data."""
    print("Validating data...")
    # TODO: Implement validation logic
    # Example: Run data quality checks
    return {"validation": "passed"}


with DAG(
    dag_id='${{ values.name }}',
    default_args=default_args,
    description='${{ values.description }}',
    schedule_interval='${{ values.schedule }}',
    start_date=datetime.strptime('${{ values.startDate }}', '%Y-%m-%d'),
    catchup=${{ values.catchup }},
    max_active_runs=${{ values.maxActiveRuns }},
    tags=['${{ values.environment }}', 'data', 'etl'],
) as dag:

    start = EmptyOperator(task_id='start')
    end = EmptyOperator(task_id='end')

    extract_task = PythonOperator(
        task_id='extract',
        python_callable=extract,
        provide_context=True,
    )

    transform_task = PythonOperator(
        task_id='transform',
        python_callable=transform,
        provide_context=True,
    )

    load_task = PythonOperator(
        task_id='load',
        python_callable=load,
        provide_context=True,
    )

    validate_task = PythonOperator(
        task_id='validate',
        python_callable=validate,
        provide_context=True,
    )

    # Define task dependencies
    start >> extract_task >> transform_task >> load_task >> validate_task >> end
