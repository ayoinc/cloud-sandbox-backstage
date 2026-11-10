"""
${{ values.name }} DAG

Owner: ${{ values.owner }}
Schedule: ${{ values.schedule }}
"""

from datetime import datetime, timedelta, timezone

from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.providers.standard.operators.python import PythonOperator
from airflow.sdk import DAG

DAG_ID = "${{ values.name }}"
START_DATE = datetime.strptime("${{ values.startDate or '2024-01-01' }}", "%Y-%m-%d").replace(tzinfo=timezone.utc)
DESCRIPTION = ${{ (values.description or values.name) | dump }}  # noqa: E501

# Default arguments for the DAG
default_args = {
    "owner": "${{ values.owner }}",
    "depends_on_past": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}


def extract(**context):
    """Extract data from source systems."""
    print("Extracting data...")
    # Replace with the extraction: read from an API, database, or file storage
    data = {"records": 100, "source": "example"}
    context["ti"].xcom_push(key="extract_result", value=data)
    return data


def transform(**context):
    """Transform extracted data."""
    print("Transforming data...")
    extract_result = context["ti"].xcom_pull(key="extract_result", task_ids="extract")
    # Replace with the transformation: clean, validate, aggregate data
    transformed = {
        "records_processed": extract_result.get("records", 0),
        "status": "transformed",
    }
    context["ti"].xcom_push(key="transform_result", value=transformed)
    return transformed


def load(**context):
    """Load transformed data to destination."""
    print("Loading data...")
    transform_result = context["ti"].xcom_pull(key="transform_result", task_ids="transform")
    # Replace with the load: write to a data warehouse, database, or file storage
    result = {
        "records_loaded": transform_result.get("records_processed", 0),
        "status": "completed",
    }
    return result


def validate(**context):
    """Validate the loaded data."""
    print("Validating data...")
    # Replace with data quality checks on the loaded data
    return {"validation": "passed"}


with DAG(
    dag_id=DAG_ID,
    default_args=default_args,
    description=DESCRIPTION,
    schedule="${{ values.schedule }}",
    start_date=START_DATE,
    catchup=${{ "True" if values.catchup else "False" }},
    max_active_runs=${{ values.maxActiveRuns or 1 }},
    tags=["${{ values.environment }}", "data", "etl"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    extract_task = PythonOperator(
        task_id="extract",
        python_callable=extract,
    )

    transform_task = PythonOperator(
        task_id="transform",
        python_callable=transform,
    )

    load_task = PythonOperator(
        task_id="load",
        python_callable=load,
    )

    validate_task = PythonOperator(
        task_id="validate",
        python_callable=validate,
    )

    # Define task dependencies
    start >> extract_task >> transform_task >> load_task >> validate_task >> end
