# ${{ values.name }}

${{ values.description }}

## Overview

This is an Apache Airflow DAG project that follows best practices for data pipeline development.

| Property | Value |
|----------|-------|
| **Owner** | ${{ values.owner }} |
| **Environment** | ${{ values.environment }} |
| **Schedule** | ${{ values.schedule }} |
| **Start Date** | ${{ values.startDate }} |
| **Catchup** | ${{ values.catchup }} |
| **Max Active Runs** | ${{ values.maxActiveRuns }} |

## Quick Start

### Local Development

1. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Run Airflow locally**:
   ```bash
   export AIRFLOW_HOME=$(pwd)
   airflow db init
   airflow users create --username admin --password admin --firstname Admin --lastname User --role Admin --email admin@example.com
   airflow webserver --port 8080 &
   airflow scheduler &
   ```

3. **Access UI**: Open http://localhost:8080

### Running Tests

```bash
pytest tests/ -v
```

## Project Structure

```
.
├── dags/
│   ├── ${{ values.name }}_dag.py    # Main DAG definition
│   └── utils/                        # Shared utilities
├── tests/
│   └── test_dag.py                   # DAG tests
├── plugins/                          # Custom operators/hooks
├── requirements.txt                  # Python dependencies
└── docs/                             # Documentation
```

## DAG Details

The main DAG implements the following workflow:

1. **Extract**: Fetch data from source systems
2. **Transform**: Apply business logic and transformations
3. **Load**: Write results to destination

## Monitoring

- DAG runs can be monitored in the Airflow UI
- Alerts are configured for task failures
- SLA monitoring is enabled for critical paths
