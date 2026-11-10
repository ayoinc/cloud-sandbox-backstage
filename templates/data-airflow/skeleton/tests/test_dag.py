"""
Tests for ${{ values.name }} DAG.

Run with: pytest tests/ -v
"""

from pathlib import Path

import pytest
from airflow.dag_processing.dagbag import DagBag

DAGS_FOLDER = Path(__file__).resolve().parent.parent / "dags"
DAG_ID = "${{ values.name }}"


@pytest.fixture(scope="module")
def dag_bag():
    """Load DAGs from the dags folder."""
    return DagBag(dag_folder=str(DAGS_FOLDER))


@pytest.fixture(scope="module")
def dag(dag_bag):
    """The DAG under test."""
    return dag_bag.dags[DAG_ID]


def test_no_import_errors(dag_bag):
    """Test that every file in the dags folder imports cleanly."""
    assert dag_bag.import_errors == {}


def test_dag_loaded(dag_bag):
    """Test that DAG is loaded."""
    assert DAG_ID in dag_bag.dags


def test_dag_has_correct_schedule(dag):
    """Test that DAG has the correct schedule."""
    assert dag.schedule == "${{ values.schedule }}"


def test_dag_has_correct_owner(dag):
    """Test that DAG has the correct owner."""
    assert dag.default_args["owner"] == "${{ values.owner }}"


def test_dag_has_required_tasks(dag):
    """Test that DAG has all required tasks."""
    required_tasks = ["start", "extract", "transform", "load", "validate", "end"]
    task_ids = [task.task_id for task in dag.tasks]
    for task in required_tasks:
        assert task in task_ids, f"Missing required task: {task}"


def test_dag_task_dependencies(dag):
    """Test that DAG tasks have correct dependencies."""
    assert dag.get_task("extract").upstream_task_ids == {"start"}
    assert dag.get_task("transform").upstream_task_ids == {"extract"}
    assert dag.get_task("load").upstream_task_ids == {"transform"}
    assert dag.get_task("validate").upstream_task_ids == {"load"}
    assert dag.get_task("end").upstream_task_ids == {"validate"}


def test_dag_catchup_setting(dag):
    """Test that DAG has correct catchup setting."""
    assert dag.catchup is ${{ "True" if values.catchup else "False" }}


def test_dag_max_active_runs(dag):
    """Test that DAG has correct max_active_runs setting."""
    assert dag.max_active_runs == ${{ values.maxActiveRuns or 1 }}


def test_tasks_have_retries(dag):
    """Test that every task retries before failing."""
    for task in dag.tasks:
        assert task.retries >= 1, f"Task {task.task_id} has no retries"
