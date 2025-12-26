# Apache Superset Template

This template deploys Apache Superset for data exploration and visualization.

## Features

- **Interactive dashboards** - Rich visualization library
- **SQL Lab** - Ad-hoc SQL queries
- **Data sources** - Connect to multiple databases
- **Access control** - Role-based permissions
- **Alerts & Reports** - Scheduled deliveries

## Prerequisites

- Docker and Docker Compose
- Or: Kubernetes cluster
- Database for metadata

## Quick Start

```bash
# Start with Docker Compose
docker-compose up -d

# Initialize database
docker-compose exec superset superset db upgrade
docker-compose exec superset superset init

# Access Superset
open http://localhost:8088
```

## Supported Databases

- PostgreSQL
- MySQL
- Snowflake
- BigQuery
- Redshift
- Presto/Trino
- And many more...

## Configuration

Environment variables:

| Variable              | Description  | Default |
| --------------------- | ------------ | ------- |
| `SUPERSET_SECRET_KEY` | Secret key   | -       |
| `DATABASE_URL`        | Metadata DB  | SQLite  |
| `REDIS_URL`           | Cache/Celery | -       |

## Kubernetes Deployment

```bash
helm repo add superset https://apache.github.io/superset
helm install superset superset/superset
```

## Support

Contact the Data Engineering Team for assistance.
