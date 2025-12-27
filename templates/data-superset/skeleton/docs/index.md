# ${{ values.name }}

${{ values.description }}

## Overview

This is an Apache Superset dashboard configuration project for the **${{ values.environment }}** environment, using **${{ values.dataSource }}** as the primary data source.

Apache Superset is a modern, enterprise-ready business intelligence web application that provides:

- Interactive data visualization and exploration
- Rich SQL editor for data analysis
- Wide variety of chart types and dashboards
- Role-based access control and security
- Support for most SQL-speaking databases

```d2
direction: right

title: {
  label: Apache Superset Architecture
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

superset: Superset Platform {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  webserver: Web Server {
    shape: hexagon
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"
    label: "Flask/Gunicorn\nWeb Server"
  }

  workers: Celery Workers {
    style.fill: "#FFECB3"
    style.stroke: "#FFA000"

    worker1: Worker 1
    worker2: Worker 2
    worker3: Worker N
  }

  scheduler: Beat Scheduler {
    shape: hexagon
    style.fill: "#FFECB3"
    style.stroke: "#FFA000"
  }
}

cache: Redis Cache {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

metadata: Metadata Database {
  shape: cylinder
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "PostgreSQL\n(Metadata)"
}

datasources: Data Sources {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  primary: ${{ values.dataSource }} {
    shape: cylinder
    style.fill: "#FFE0B2"
    style.stroke: "#FF9800"
  }

  warehouse: Data Warehouse {
    shape: cylinder
    style.fill: "#FFE0B2"
    style.stroke: "#FF9800"
  }

  other: Other DBs {
    shape: cylinder
    style.fill: "#FFE0B2"
    style.stroke: "#FF9800"
  }
}

users -> superset.webserver: HTTPS
superset.webserver -> cache: Session/Results
superset.webserver -> metadata: Config/Users
superset.webserver -> superset.workers: Async Tasks
superset.scheduler -> superset.workers: Scheduled Jobs
superset.workers -> cache: Results
superset.workers -> datasources: SQL Queries
superset.webserver -> datasources: Direct Queries
```

## Configuration Summary

| Setting              | Value                             |
| -------------------- | --------------------------------- |
| **Dashboard Name**   | `${{ values.name }}`              |
| **Owner**            | `${{ values.owner }}`             |
| **Environment**      | `${{ values.environment }}`       |
| **Data Source**      | `${{ values.dataSource }}`        |

## Infrastructure Components

### Core Services

| Component          | Description                                           | Default Configuration      |
| ------------------ | ----------------------------------------------------- | -------------------------- |
| **Web Server**     | Flask/Gunicorn serving the Superset UI and API        | 4 workers, port 8088       |
| **Celery Workers** | Async task processing for queries and alerts          | 2 workers, 4 concurrency   |
| **Beat Scheduler** | Cron-like scheduler for reports and cache refresh     | Single instance            |
| **Redis**          | Caching layer and Celery message broker               | 6.x, 1GB memory            |
| **Metadata DB**    | PostgreSQL database for Superset configuration        | PostgreSQL 15              |

### Resource Requirements

| Environment   | Web Server        | Workers           | Redis   | Metadata DB |
| ------------- | ----------------- | ----------------- | ------- | ----------- |
| Development   | 1 CPU, 2GB RAM    | 1 CPU, 2GB RAM    | 256MB   | 1GB         |
| Staging       | 2 CPU, 4GB RAM    | 2 CPU, 4GB RAM    | 512MB   | 5GB         |
| Production    | 4 CPU, 8GB RAM    | 4 CPU, 8GB RAM    | 2GB     | 20GB        |

---

## CI/CD Pipeline

This repository includes a GitHub Actions pipeline for validating and deploying dashboard configurations.

### Pipeline Features

- **JSON Validation**: Validates all dashboard, chart, and dataset JSON files
- **Python Linting**: Black, isort, and flake8 for import/export scripts
- **Automated Deployment**: Auto-imports to Superset on merge to main
- **Environment Protection**: Deployment requires environment approval

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "JSON Validation\nSchema Check"
}

lint: Lint {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Black\nisort\nflake8"
}

review: Review {
  shape: diamond
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Code\nReview"
}

merge: Merge {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

deploy: Deploy {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Import to\nSuperset"
}

superset: Superset {
  shape: hexagon
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

pr -> validate
pr -> lint
validate -> review
lint -> review
review -> merge -> deploy -> superset
```

### Workflow Triggers

| Trigger         | Actions                                     |
| --------------- | ------------------------------------------- |
| Pull Request    | JSON validation, Python linting             |
| Push to `main`  | Validation, linting, deploy to ${{ values.environment }} |
| Manual Dispatch | Full pipeline with environment selection    |

---

## Prerequisites

### 1. Apache Superset Instance

You need a running Superset instance. Choose one of these deployment options:

#### Option A: Docker Compose (Development)

```bash
# Clone Superset repository
git clone https://github.com/apache/superset.git
cd superset

# Start Superset with Docker Compose
docker-compose -f docker-compose-non-dev.yml up -d

# Access at http://localhost:8088
# Default credentials: admin/admin
```

#### Option B: Kubernetes with Helm (Production)

```bash
# Add Superset Helm repository
helm repo add superset https://apache.github.io/superset
helm repo update

# Install Superset
helm install superset superset/superset \
  --namespace superset \
  --create-namespace \
  --set postgresql.enabled=true \
  --set redis.enabled=true \
  --set ingress.enabled=true \
  --set ingress.hosts[0]="superset.${{ values.environment }}.example.com"
```

#### Option C: Managed Service

- **Preset.io**: Managed Superset SaaS offering
- **AWS**: Deploy on EKS with RDS and ElastiCache
- **GCP**: Deploy on GKE with Cloud SQL and Memorystore

### 2. Data Source Access

Ensure network connectivity and credentials for your data source:

| Data Source    | Default Port | Connection Requirements                    |
| -------------- | ------------ | ------------------------------------------ |
| PostgreSQL     | 5432         | Host, port, database, username, password   |
| MySQL          | 3306         | Host, port, database, username, password   |
| Snowflake      | 443          | Account, warehouse, database, role, user   |
| BigQuery       | 443          | Project ID, service account JSON key       |
| Redshift       | 5439         | Host, port, database, username, password   |

### 3. Python Environment

```bash
# Install Python 3.11+
python --version  # Should be 3.11 or higher

# Install required packages
pip install requests python-dotenv

# For local development with Superset CLI
pip install apache-superset
```

### 4. GitHub Repository Secrets

Configure these secrets in **Settings > Secrets and variables > Actions**:

| Secret              | Description                          | Example                        |
| ------------------- | ------------------------------------ | ------------------------------ |
| `SUPERSET_URL`      | Superset instance URL                | `https://superset.example.com` |
| `SUPERSET_USERNAME` | Admin username for API access        | `admin`                        |
| `SUPERSET_PASSWORD` | Admin password for API access        | `********`                     |

---

## Usage

### Local Development

#### Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

#### Environment Configuration

Create a `.env` file for local development:

```bash
# .env (do not commit to repository)
SUPERSET_URL=http://localhost:8088
SUPERSET_USERNAME=admin
SUPERSET_PASSWORD=admin
```

#### Import Dashboard

```bash
# Export environment variables
export $(cat .env | xargs)

# Import all assets to Superset
python scripts/import.py

# Import specific dashboard
python scripts/import.py --dashboard dashboards/${{ values.name }}.json
```

#### Export Dashboard

```bash
# Export current dashboard state from Superset
python scripts/export.py

# Export specific dashboard by ID
python scripts/export.py --dashboard-id 1
```

### Accessing the Dashboard

1. Navigate to your Superset instance: `https://superset.${{ values.environment }}.example.com`
2. Log in with your credentials
3. Go to **Dashboards** in the top navigation
4. Find and open **${{ values.name }}**

### Development Workflow

1. **Make changes in Superset UI** - Create or modify charts and dashboards visually
2. **Export changes** - Run `python scripts/export.py` to save changes to JSON files
3. **Review changes** - Use `git diff` to review what changed
4. **Commit and push** - `git add . && git commit -m "Update dashboard" && git push`
5. **Create PR** - Open a pull request for code review
6. **Merge** - CI/CD will auto-deploy on merge to main

---

## Adding Data Sources

### Database Connection Configuration

Create or modify the database connection in `databases/${{ values.dataSource }}.json`:

```json
{
  "database_name": "${{ values.dataSource }}-${{ values.environment }}",
  "sqlalchemy_uri": "{{ SQLALCHEMY_URI }}",
  "expose_in_sqllab": true,
  "allow_ctas": false,
  "allow_cvas": false,
  "allow_dml": false,
  "allow_run_async": true,
  "cache_timeout": 3600,
  "extra": {
    "metadata_params": {},
    "engine_params": {
      "pool_size": 5,
      "max_overflow": 10
    }
  }
}
```

### Connection String Examples

#### PostgreSQL

```
postgresql://username:password@host:5432/database
```

#### MySQL

```
mysql://username:password@host:3306/database
```

#### Snowflake

```
snowflake://user:password@account/database/schema?warehouse=COMPUTE_WH&role=ANALYST
```

#### BigQuery

```
bigquery://project-id
```

(Requires `GOOGLE_APPLICATION_CREDENTIALS` environment variable)

#### Redshift

```
redshift+psycopg2://username:password@cluster.region.redshift.amazonaws.com:5439/database
```

### Creating Datasets

Define datasets in `datasets/` directory:

```json
{
  "table_name": "my_table",
  "schema": "public",
  "database_id": 1,
  "sql": null,
  "columns": [
    {
      "column_name": "id",
      "type": "INTEGER",
      "groupby": false,
      "filterable": true
    },
    {
      "column_name": "created_at",
      "type": "TIMESTAMP",
      "is_dttm": true,
      "groupby": true,
      "filterable": true
    }
  ],
  "metrics": [
    {
      "metric_name": "count",
      "expression": "COUNT(*)",
      "metric_type": "count"
    }
  ]
}
```

---

## Security Configuration

### Authentication

Superset supports multiple authentication backends:

| Method      | Configuration                          | Use Case                |
| ----------- | -------------------------------------- | ----------------------- |
| Database    | Built-in user management               | Development, small teams|
| LDAP        | `AUTH_TYPE = AUTH_LDAP`                | Enterprise AD/LDAP      |
| OAuth       | `AUTH_TYPE = AUTH_OAUTH`               | SSO with Google, Okta   |
| OIDC        | `AUTH_TYPE = AUTH_OID`                 | OpenID Connect          |

### Role-Based Access Control

Configure roles in Superset for fine-grained permissions:

| Role        | Permissions                                        |
| ----------- | -------------------------------------------------- |
| Admin       | Full access to all features                        |
| Alpha       | Create charts, dashboards, access SQL Lab          |
| Gamma       | View dashboards and charts only                    |
| sql_lab     | SQL Lab access (add to other roles)                |
| Public      | Anonymous access to public dashboards              |

### Row-Level Security

Implement row-level security for data isolation:

```python
# Example RLS rule
{
    "filter_type": "Regular",
    "tables": ["sales_data"],
    "clause": "region = '{{ current_user.region }}'",
    "roles": ["Sales Team"]
}
```

### Secrets Management

**Never commit secrets to the repository.** Use these approaches:

1. **GitHub Secrets** - For CI/CD pipeline
2. **Environment Variables** - For local development (`.env` file)
3. **Kubernetes Secrets** - For production deployments
4. **Vault/AWS Secrets Manager** - For enterprise secret management

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── superset.yaml       # CI/CD pipeline
├── dashboards/
│   └── ${{ values.name }}.json # Dashboard configuration
├── charts/
│   └── example_chart.json      # Chart configurations
├── datasets/
│   └── example_dataset.json    # Dataset/table definitions
├── databases/
│   └── ${{ values.dataSource }}.json  # Database connections
├── scripts/
│   ├── __init__.py
│   ├── import.py               # Import assets to Superset
│   └── export.py               # Export assets from Superset
├── docs/
│   └── index.md                # This documentation
├── catalog-info.yaml           # Backstage catalog metadata
├── mkdocs.yml                  # MkDocs configuration
└── README.md                   # Repository README
```

---

## Troubleshooting

### Connection Issues

**Error: Unable to connect to Superset API**

```
requests.exceptions.ConnectionError: Failed to establish connection
```

**Resolution:**
1. Verify `SUPERSET_URL` is correct and accessible
2. Check network connectivity: `curl -I $SUPERSET_URL/health`
3. Ensure Superset is running: check container/pod status
4. Verify firewall rules allow access from your location

### Authentication Failures

**Error: 401 Unauthorized**

```
{"message": "Invalid credentials"}
```

**Resolution:**
1. Verify username and password are correct
2. Check if account is active in Superset admin
3. Ensure API access is enabled for the user role
4. Try logging in via the web UI to verify credentials

### Import Failures

**Error: Dashboard import failed**

```
{"message": "Error importing dashboard: ..."}
```

**Resolution:**
1. Validate JSON syntax: `python -m json.tool dashboard.json`
2. Check for missing database references
3. Ensure referenced datasets exist
4. Review Superset logs: `docker logs superset_app`

### Database Connection Errors

**Error: Could not connect to database**

```
sqlalchemy.exc.OperationalError: could not connect to server
```

**Resolution:**
1. Verify database host is reachable from Superset
2. Check credentials are correct
3. Ensure database user has required permissions
4. Verify SSL/TLS configuration if required
5. Check for IP allowlisting requirements

### Chart/Dashboard Not Updating

**Issue: Changes not reflected after import**

**Resolution:**
1. Clear Superset cache: Admin > Refresh Metadata
2. Clear browser cache or use incognito mode
3. Check if dashboard is cached: reduce `cache_timeout`
4. Verify export captured latest changes

### Pipeline Failures

**JSON Validation Failed**

```
Error: Expecting property name enclosed in double quotes
```

**Resolution:**
1. Check for trailing commas in JSON files
2. Validate with: `python -m json.tool <file>.json`
3. Use a JSON validator extension in your IDE

**Python Lint Errors**

```
black --check: would reformat scripts/import.py
```

**Resolution:**
```bash
# Auto-format code
black scripts/
isort scripts/
```

---

## Related Templates

| Template                                                          | Description                               |
| ----------------------------------------------------------------- | ----------------------------------------- |
| [data-metabase](/docs/default/template/data-metabase)             | Metabase dashboard configuration          |
| [data-looker](/docs/default/template/data-looker)                 | Looker/LookML project                     |
| [data-dbt](/docs/default/template/data-dbt)                       | dbt data transformation project           |
| [data-airflow](/docs/default/template/data-airflow)               | Apache Airflow DAGs                       |
| [data-prefect](/docs/default/template/data-prefect)               | Prefect workflow orchestration            |
| [aws-rds](/docs/default/template/aws-rds)                         | AWS RDS database (data source)            |
| [gcp-bigquery](/docs/default/template/gcp-bigquery)               | Google BigQuery dataset (data source)     |
| [snowflake-database](/docs/default/template/snowflake-database)   | Snowflake database (data source)          |

---

## References

- [Apache Superset Documentation](https://superset.apache.org/docs/intro)
- [Superset GitHub Repository](https://github.com/apache/superset)
- [Superset API Reference](https://superset.apache.org/docs/api)
- [Superset Helm Chart](https://github.com/apache/superset/tree/master/helm/superset)
- [SQLAlchemy Connection Strings](https://docs.sqlalchemy.org/en/14/core/engines.html)
- [Preset.io (Managed Superset)](https://preset.io/)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
