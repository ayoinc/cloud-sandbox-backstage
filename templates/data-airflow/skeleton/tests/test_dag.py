"""
Tests for ${{ values.name }} DAG.

Run with: pytest tests/ -v
"""

import pytest
from datetime import datetime
from airflow.models import DagBag


@pytest.fixture
def dag_bag():
    """Load DAGs from the dags folder."""
    return DagBag(dag_folder='dags', include_examples=False)


def test_dag_loaded(dag_bag):
    """Test that DAG is loaded without errors."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    assert dag is not None
    assert len(dag_bag.import_errors) == 0


def test_dag_has_correct_schedule(dag_bag):
    """Test that DAG has the correct schedule interval."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    assert dag.schedule_interval == '${{ values.schedule }}'


def test_dag_has_correct_owner(dag_bag):
    """Test that DAG has the correct owner."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    assert dag.default_args['owner'] == '${{ values.owner }}'


def test_dag_has_required_tasks(dag_bag):
    """Test that DAG has all required tasks."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    required_tasks = ['start', 'extract', 'transform', 'load', 'validate', 'end']
    task_ids = [task.task_id for task in dag.tasks]
    for task in required_tasks:
        assert task in task_ids, f"Missing required task: {task}"


def test_dag_task_dependencies(dag_bag):
    """Test that DAG tasks have correct dependencies."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    
    extract_task = dag.get_task('extract')
    assert 'start' in [t.task_id for t in extract_task.upstream_list]
    
    transform_task = dag.get_task('transform')
    assert 'extract' in [t.task_id for t in transform_task.upstream_list]
    
    load_task = dag.get_task('load')
    assert 'transform' in [t.task_id for t in load_task.upstream_list]


def test_dag_catchup_setting(dag_bag):
    """Test that DAG has correct catchup setting."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    assert dag.catchup == ${{ values.catchup }}


def test_dag_max_active_runs(dag_bag):
    """Test that DAG has correct max_active_runs setting."""
    dag = dag_bag.get_dag(dag_id='${{ values.name }}')
    assert dag.max_active_runs == ${{ values.maxActiveRuns }}
