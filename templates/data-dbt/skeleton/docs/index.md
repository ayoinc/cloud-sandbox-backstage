# ${{ values.name }}

${{ values.description }}

## Overview

This dbt project provides a production-ready data transformation framework following analytics engineering best practices. It implements a modular, layered architecture for transforming raw data into business-ready analytics models.

Key features:

- Layered data modeling (staging, intermediate, marts)
- Built-in data quality testing framework
- Automated documentation generation
- CI/CD pipeline with SQL linting and validation
- Support for multiple environments (development, staging, production)
- Pre-configured dbt packages for common utilities

```d2
direction: down

title: {
  label: dbt Project Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

sources: Raw Sources {
  shape: cylinder
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "External Data\n(databases, APIs, files)"
}

staging: Staging Layer {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  stg_models: Staging Models {
    label: "1:1 with sources\nRenaming & Casting\nBasic Cleaning"
  }

  stg_tests: Schema Tests {
    shape: hexagon
    label: "unique\nnot_null"
  }

  stg_models -> stg_tests
}

intermediate: Intermediate Layer {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  int_models: Intermediate Models {
    label: "Business Logic\nJoins & Aggregations\nReusable Components"
  }
}

marts: Marts Layer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  facts: Fact Tables {
    label: "fct_*\nMetrics & Events"
  }

  dims: Dimension Tables {
    label: "dim_*\nAttributes & Entities"
  }

  tests: Data Tests {
    shape: hexagon
    label: "Integrity\nBusiness Rules"
  }

  facts -> tests
  dims -> tests
}

docs: Documentation {
  shape: document
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Auto-generated\nLineage & Catalog"
}

sources -> staging
staging -> intermediate
intermediate -> marts
marts -> docs
```

## Configuration Summary

| Setting            | Value                         |
| ------------------ | ----------------------------- |
| **Project Name**   | `${{ values.name }}`          |
| **Owner**          | ${{ values.owner }}           |
| **Environment**    | `${{ values.environment }}`   |
| **Data Warehouse** | `${{ values.warehouse }}`     |
| **dbt Version**    | `${{ values.dbtVersion }}.x`  |
| **Profile**        | `${{ values.name }}`          |

## Project Structure

```
${{ values.name }}/
├── models/
│   ├── sources.yml           # Source definitions and freshness
│   ├── staging/              # Cleaned, typed source data
│   │   ├── _staging.yml      # Staging model documentation
│   │   └── stg_*.sql         # One model per source table
│   ├── intermediate/         # Business logic transformations
│   │   ├── _intermediate.yml # Intermediate model documentation
│   │   └── int_*.sql         # Reusable transformation steps
│   └── marts/                # Final business entities
│       ├── _marts.yml        # Mart model documentation
│       ├── fct_*.sql         # Fact tables (metrics/events)
│       └── dim_*.sql         # Dimension tables (attributes)
├── macros/                   # Reusable SQL functions
│   ├── generate_schema_name.sql
│   └── utils.sql
├── tests/                    # Custom data tests
│   └── assert_*.sql          # SQL-based assertions
├── seeds/                    # Static reference data (CSV)
├── snapshots/                # SCD Type 2 historical tracking
├── analyses/                 # Ad-hoc analytical queries
├── dbt_project.yml           # Project configuration
├── packages.yml              # dbt package dependencies
├── profiles.yml.example      # Connection profile template
└── .github/workflows/        # CI/CD pipeline
    └── dbt.yaml
```

### Layer Descriptions

| Layer            | Prefix  | Purpose                                              |
| ---------------- | ------- | ---------------------------------------------------- |
| **Staging**      | `stg_`  | 1:1 with sources, renaming, type casting, cleaning   |
| **Intermediate** | `int_`  | Business logic, joins, aggregations, reusable CTEs   |
| **Marts**        | `fct_`/`dim_` | Final business entities for analytics/reporting |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with four stages:

- **Lint**: SQL linting with sqlfluff
- **Test**: dbt project validation and compilation
- **Docs**: Auto-generate documentation on main branch
- **Deploy**: Run models in target environment

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "sqlfluff\nSQL Style Check"
}

test: Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "dbt parse\ndbt compile"
}

docs: Generate Docs {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "dbt docs generate\nUpload Artifact"
}

deploy: Deploy {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "dbt run\ndbt test"
}

main: Main Branch {
  shape: diamond
  style.fill: "#E0E0E0"
  style.stroke: "#616161"
}

pr -> lint -> test
test -> main
main -> docs
main -> deploy
```

### Pipeline Triggers

| Trigger             | Actions                         |
| ------------------- | ------------------------------- |
| Pull Request        | Lint, Test (compile only)       |
| Push to main        | Lint, Test, Docs, Deploy        |

---

## Prerequisites

### 1. Python Environment

dbt requires Python 3.8 or higher:

```bash
# Check Python version
python --version  # Should be 3.8+

# Create virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # Linux/macOS
# or: venv\Scripts\activate  # Windows
```

### 2. Install dbt

Install dbt with the appropriate adapter for your data warehouse:

```bash
# For ${{ values.warehouse }}
pip install dbt-${{ values.warehouse }}==${{ values.dbtVersion }}.*

# Common adapters:
# pip install dbt-snowflake==1.7.*
# pip install dbt-bigquery==1.7.*
# pip install dbt-redshift==1.7.*
# pip install dbt-postgres==1.7.*
# pip install dbt-databricks==1.7.*
```

### 3. Database Connection

Configure your connection credentials based on your warehouse:

#### Snowflake

```bash
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
# or use SSO/key-pair authentication
```

#### BigQuery

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
# or use gcloud auth application-default login
```

#### Redshift

```bash
export REDSHIFT_HOST="your-cluster.region.redshift.amazonaws.com"
export REDSHIFT_USER="your_username"
export REDSHIFT_PASSWORD="your_password"
```

### 4. GitHub Repository Setup (for CI/CD)

#### Required Secrets

Configure in **Settings > Secrets and variables > Actions**:

| Secret                | Description                              |
| --------------------- | ---------------------------------------- |
| `DBT_TARGET`          | Target environment for dbt               |
| Warehouse credentials | Database-specific connection secrets     |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment   | Protection Rules        | Use Case          |
| ------------- | ----------------------- | ----------------- |
| `development` | None                    | Local development |
| `staging`     | Optional reviewers      | Pre-production    |
| `production`  | Required reviewers      | Production deploy |

---

## Usage

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dbt
pip install dbt-${{ values.warehouse }}==${{ values.dbtVersion }}.*

# Configure profiles.yml
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your credentials

# Install dbt packages
dbt deps

# Verify setup
dbt debug
```

### Local Development

```bash
# Parse and validate project structure
dbt parse

# Compile SQL without executing
dbt compile

# Run all models
dbt run

# Run specific layer
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Run specific model and its dependencies
dbt run --select +fct_example

# Run model and all downstream models
dbt run --select stg_example+

# Run models with a specific tag
dbt run --select tag:daily

# Full refresh (rebuild incremental models)
dbt run --full-refresh
```

### Common dbt Commands

| Command                     | Description                              |
| --------------------------- | ---------------------------------------- |
| `dbt deps`                  | Install package dependencies             |
| `dbt debug`                 | Test database connection                 |
| `dbt parse`                 | Parse project and validate structure     |
| `dbt compile`               | Compile SQL without executing            |
| `dbt run`                   | Execute models                           |
| `dbt test`                  | Run data tests                           |
| `dbt build`                 | Run models + tests in DAG order          |
| `dbt docs generate`         | Generate documentation                   |
| `dbt docs serve`            | Serve documentation locally              |
| `dbt source freshness`      | Check source data freshness              |
| `dbt seed`                  | Load CSV seed files                      |
| `dbt snapshot`              | Execute snapshot (SCD Type 2)            |
| `dbt clean`                 | Remove compiled files                    |

### Model Selection Syntax

```bash
# Run single model
dbt run --select model_name

# Run model and all upstream dependencies
dbt run --select +model_name

# Run model and all downstream dependents
dbt run --select model_name+

# Run model with both upstream and downstream
dbt run --select +model_name+

# Run all models in a directory
dbt run --select staging.*

# Run models with intersection
dbt run --select staging.* marts.*

# Exclude specific models
dbt run --exclude model_to_skip

# Run by tag
dbt run --select tag:daily

# Run by materialization
dbt run --select config.materialized:table
```

---

## Model Documentation

### Source Configuration

Sources are defined in `models/sources.yml`:

```yaml
version: 2

sources:
  - name: raw
    description: Raw data source tables
    database: "{{ var('raw_database', 'raw') }}"
    schema: "{{ var('raw_schema', 'raw') }}"
    freshness:
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
    tables:
      - name: example_table
        description: Example source table
        columns:
          - name: id
            description: Primary key
            tests:
              - unique
              - not_null
```

### Staging Models

Staging models perform 1:1 transformation from sources:

```sql
-- models/staging/stg_example.sql
with source as (
    select * from {{ source('raw', 'example_table') }}
),

renamed as (
    select
        id,
        created_at,
        updated_at
    from source
)

select * from renamed
```

### Intermediate Models

Intermediate models contain reusable business logic:

```sql
-- models/intermediate/int_example_processed.sql
with staged as (
    select * from {{ ref('stg_example') }}
),

processed as (
    select
        id,
        created_at,
        updated_at,
        datediff('day', created_at, updated_at) as days_since_creation
    from staged
)

select * from processed
```

### Mart Models

Mart models are the final business entities:

```sql
-- models/marts/fct_example.sql
with intermediate as (
    select * from {{ ref('int_example_processed') }}
)

select
    id,
    created_at,
    updated_at,
    days_since_creation
from intermediate
```

---

## Testing Strategy

### Schema Tests

Define tests in YAML files alongside models:

```yaml
version: 2

models:
  - name: fct_example
    description: Fact table for example metrics
    columns:
      - name: id
        description: Primary key
        tests:
          - unique
          - not_null
      - name: created_at
        tests:
          - not_null
      - name: days_since_creation
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 365
```

### Custom Data Tests

Create SQL-based tests in `tests/` directory:

```sql
-- tests/assert_fct_dim_integrity.sql
-- Test that all IDs in fct_example exist in dim_example
select
    f.id
from {{ ref('fct_example') }} f
left join {{ ref('dim_example') }} d on f.id = d.id
where d.id is null
```

### Running Tests

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select fct_example

# Run only schema tests
dbt test --select test_type:schema

# Run only data tests
dbt test --select test_type:data

# Run tests for a model and its upstream
dbt test --select +fct_example

# Store test failures
dbt test --store-failures
```

### Testing Best Practices

| Test Type           | When to Use                                    |
| ------------------- | ---------------------------------------------- |
| `unique`            | Primary keys, natural keys                     |
| `not_null`          | Required fields, foreign keys                  |
| `accepted_values`   | Enums, status fields, categories               |
| `relationships`     | Foreign key references                         |
| `dbt_expectations`  | Complex data quality rules                     |
| Custom SQL tests    | Business logic validation, cross-model checks  |

### Included Packages

This project includes pre-configured testing packages:

| Package             | Version     | Purpose                              |
| ------------------- | ----------- | ------------------------------------ |
| `dbt_utils`         | >=1.0.0     | Common SQL utilities and macros      |
| `dbt_expectations`  | >=0.10.0    | Great Expectations-style tests       |
| `codegen`           | >=0.12.0    | Auto-generate model boilerplate      |

---

## Documentation Generation

### Generate Documentation

```bash
# Generate documentation
dbt docs generate

# Serve documentation locally (opens browser)
dbt docs serve

# Serve on specific port
dbt docs serve --port 8080
```

### Documentation Features

dbt generates comprehensive documentation including:

- **Model catalog**: All models with descriptions and columns
- **Data lineage**: Visual DAG of model dependencies
- **Source definitions**: External data sources
- **Test coverage**: Tests defined for each model
- **Column-level lineage**: Track data flow through columns

### Writing Good Documentation

Add descriptions to your models in YAML:

```yaml
version: 2

models:
  - name: fct_example
    description: |
      Fact table containing example metrics.
      
      **Grain**: One row per unique example event.
      
      **Update Frequency**: Daily
      
      **Primary Key**: `id`
    columns:
      - name: id
        description: Unique identifier for each example event
      - name: created_at
        description: Timestamp when the event occurred (UTC)
      - name: days_since_creation
        description: Number of days between creation and last update
```

### Docs Blocks

Create reusable documentation in `models/docs.md`:

```markdown
{% docs days_since_creation %}
The number of days elapsed between the record creation date
and the most recent update. Used to measure record age and
identify stale data.

**Calculation**: `datediff('day', created_at, updated_at)`
{% enddocs %}
```

Reference in YAML:

```yaml
columns:
  - name: days_since_creation
    description: '{{ doc("days_since_creation") }}'
```

---

## Troubleshooting

### Connection Issues

**Error: Database connection failed**

```
Runtime Error: Database Error
```

**Resolution:**

1. Verify credentials in `~/.dbt/profiles.yml`
2. Test connection: `dbt debug`
3. Check network access (VPN, firewall, IP allowlist)
4. Verify database/schema permissions

### Compilation Errors

**Error: Compilation Error - model not found**

```
Compilation Error: Model 'model_name' not found
```

**Resolution:**

1. Check model file exists in correct directory
2. Verify spelling matches exactly (case-sensitive)
3. Run `dbt parse` to validate project structure
4. Ensure model isn't excluded in `dbt_project.yml`

### Package Issues

**Error: Package installation failed**

```
ERROR: Could not find a version that satisfies the requirement
```

**Resolution:**

```bash
# Clear package cache
dbt clean

# Reinstall packages
dbt deps

# Check packages.yml for version conflicts
```

### Test Failures

**Error: Test failed**

```
Failure in test unique_fct_example_id
Got 5 results, configured to fail if != 0
```

**Resolution:**

1. Investigate failing records:
   ```bash
   dbt test --select fct_example --store-failures
   ```
2. Query the test results table in your warehouse
3. Fix source data or model logic
4. Re-run tests

### CI/CD Pipeline Failures

**Lint job failing**

```
L001: Unnecessary trailing whitespace
```

**Resolution:**

```bash
# Auto-fix SQL formatting
sqlfluff fix models/ --dialect ${{ values.warehouse }}

# Or configure rules in .sqlfluff
```

**Test job failing**

```
ERROR: Could not find profile named 'profile_name'
```

**Resolution:**

1. Ensure `DBT_PROFILES_DIR` is set correctly
2. Create CI-specific profile in repository
3. Verify environment variables are configured

### Performance Issues

**Models running slowly**

**Resolution:**

1. Check model materialization (table vs view vs incremental)
2. Review SQL for expensive operations
3. Add appropriate clustering/partitioning
4. Use `dbt run --threads N` to increase parallelism
5. Consider incremental models for large tables

---

## Related Templates

| Template                                                    | Description                           |
| ----------------------------------------------------------- | ------------------------------------- |
| [data-airflow](/docs/default/template/data-airflow)         | Apache Airflow DAGs for orchestration |
| [data-spark](/docs/default/template/data-spark)             | Apache Spark data processing          |
| [data-dagster](/docs/default/template/data-dagster)         | Dagster data orchestration            |
| [aws-redshift](/docs/default/template/aws-redshift)         | Amazon Redshift data warehouse        |
| [gcp-bigquery](/docs/default/template/gcp-bigquery)         | Google BigQuery data warehouse        |
| [snowflake-account](/docs/default/template/snowflake-account) | Snowflake account setup             |

---

## References

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md)
- [sqlfluff Documentation](https://docs.sqlfluff.com/)
- [dbt_utils Package](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
- [dbt_expectations Package](https://hub.getdbt.com/calogica/dbt_expectations/latest/)
- [Analytics Engineering Guide](https://www.getdbt.com/analytics-engineering/)
