# Apache Airflow Overview

## Architecture Deep Dive

### Component Interaction

```d2
direction: down

dag_file: DAG File (.py) {
  shape: document
  style: {
    fill: "#fff9c4"
    stroke: "#f9a825"
  }
  label: "DAG File (.py)\n/dags/"
}

scheduler: Scheduler {
  style: {
    fill: "#e3f2fd"
    stroke: "#1976d2"
    border-radius: 8
  }

  dag_parser: DAG Parser {
    shape: rectangle
    style: {
      fill: "#bbdefb"
      stroke: "#1565c0"
    }
    desc: |md
      - Parse DAGs
      - Serialize
      - Store in DB
    |
  }

  task_scheduler: Task Instance Scheduler {
    shape: rectangle
    style: {
      fill: "#c8e6c9"
      stroke: "#388e3c"
    }
    desc: |md
      - Check deps
      - Update state
    |
  }

  executor: Executor Interface {
    shape: rectangle
    style: {
      fill: "#fff3e0"
      stroke: "#ef6c00"
    }
    desc: |md
      - Queue tasks
      - Track status
    |
  }

  dag_parser -> task_scheduler: parsed DAGs
  task_scheduler -> executor: ready tasks
}

celery_workers: Celery Workers {
  style: {
    fill: "#fce4ec"
    stroke: "#c2185b"
    border-radius: 8
  }

  worker1: Worker 1 {
    shape: rectangle
    style.fill: "#f8bbd9"
  }
  worker2: Worker 2 {
    shape: rectangle
    style.fill: "#f8bbd9"
  }
  worker_n: "..." {
    shape: rectangle
    style.fill: "#f8bbd9"
  }
}

k8s_pods: Kubernetes Pods {
  style: {
    fill: "#e8eaf6"
    stroke: "#3f51b5"
    border-radius: 8
  }

  pod1: Pod 1 (task) {
    shape: rectangle
    style.fill: "#c5cae9"
  }
  pod2: Pod 2 (task) {
    shape: rectangle
    style.fill: "#c5cae9"
  }
  pod_n: "..." {
    shape: rectangle
    style.fill: "#c5cae9"
  }
}

dag_file -> scheduler: Parse
scheduler.executor -> celery_workers: CeleryExecutor
scheduler.executor -> k8s_pods: KubernetesExecutor
```

### DAG Execution Lifecycle

```d2
direction: right

none: None {
  shape: rectangle
  style: {
    fill: "#eceff1"
    stroke: "#607d8b"
    border-radius: 4
  }
}

scheduled: Scheduled {
  shape: rectangle
  style: {
    fill: "#e3f2fd"
    stroke: "#1976d2"
    border-radius: 4
  }
}

queued: Queued {
  shape: rectangle
  style: {
    fill: "#fff3e0"
    stroke: "#f57c00"
    border-radius: 4
  }
}

running: Running {
  shape: rectangle
  style: {
    fill: "#e1f5fe"
    stroke: "#0288d1"
    border-radius: 4
  }
}

success: Success {
  shape: rectangle
  style: {
    fill: "#c8e6c9"
    stroke: "#388e3c"
    border-radius: 4
  }
}

upstream_failed: Upstream Failed {
  shape: rectangle
  style: {
    fill: "#ffccbc"
    stroke: "#e64a19"
    border-radius: 4
  }
}

failed: Failed {
  shape: rectangle
  style: {
    fill: "#ffcdd2"
    stroke: "#d32f2f"
    border-radius: 4
  }
}

up_for_retry: Up for Retry {
  shape: rectangle
  style: {
    fill: "#fff9c4"
    stroke: "#fbc02d"
    border-radius: 4
  }
}

none -> scheduled: trigger
scheduled -> queued: executor ready
scheduled -> upstream_failed: dependency failed
queued -> running: worker picks up
running -> success: task completes
running -> failed: task errors
failed -> up_for_retry: retries remaining
up_for_retry -> queued: retry attempt
```

## Configuration

### airflow.cfg

```ini
[core]
dags_folder = /opt/airflow/dags
executor = CeleryExecutor
parallelism = 32
max_active_tasks_per_dag = 16
max_active_runs_per_dag = 16
load_examples = False
default_timezone = UTC

[database]
sql_alchemy_conn = postgresql+psycopg2://airflow:airflow@postgres/airflow
sql_alchemy_pool_size = 5
sql_alchemy_pool_recycle = 1800

[webserver]
web_server_host = 0.0.0.0
web_server_port = 8080
rbac = True
authenticate = True
auth_backends = airflow.providers.fab.auth_manager.fab_auth_manager
secret_key = your-secret-key-here

[scheduler]
min_file_process_interval = 30
dag_dir_list_interval = 300
parsing_processes = 2
scheduler_heartbeat_sec = 5

[celery]
broker_url = redis://redis:6379/0
result_backend = db+postgresql://airflow:airflow@postgres/airflow
worker_concurrency = 16
worker_prefetch_multiplier = 1
task_acks_late = True

[kubernetes]
namespace = airflow
worker_container_repository = apache/airflow
worker_container_tag = 2.8.0
delete_worker_pods = True
delete_worker_pods_on_failure = False

[logging]
base_log_folder = /opt/airflow/logs
remote_logging = True
remote_log_conn_id = aws_default
remote_base_log_folder = s3://airflow-logs/

[metrics]
statsd_on = True
statsd_host = statsd-exporter
statsd_port = 9125
statsd_prefix = airflow

[smtp]
smtp_host = smtp.gmail.com
smtp_port = 587
smtp_starttls = True
smtp_user = airflow@example.com
smtp_password = your-password
smtp_mail_from = airflow@example.com
```

### Environment Variables

```bash
# Core settings
AIRFLOW__CORE__EXECUTOR=CeleryExecutor
AIRFLOW__CORE__FERNET_KEY=your-fernet-key
AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=True
AIRFLOW__CORE__LOAD_EXAMPLES=False

# Database
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow

# Celery
AIRFLOW__CELERY__BROKER_URL=redis://redis:6379/0
AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@postgres/airflow

# Webserver
AIRFLOW__WEBSERVER__SECRET_KEY=your-secret-key
AIRFLOW__WEBSERVER__RBAC=True

# Logging
AIRFLOW__LOGGING__REMOTE_LOGGING=True
AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER=s3://airflow-logs/
```

## Connections and Variables

### Managing Connections

```bash
# Add connection via CLI
airflow connections add 'postgres_default' \
    --conn-type 'postgres' \
    --conn-host 'postgres.example.com' \
    --conn-port 5432 \
    --conn-login 'user' \
    --conn-password 'password' \
    --conn-schema 'database'

# Add AWS connection
airflow connections add 'aws_default' \
    --conn-type 'aws' \
    --conn-extra '{"region_name": "us-east-1"}'

# Add connection via URI
airflow connections add 'my_conn' \
    --conn-uri 'postgresql://user:password@host:5432/database'
```

### Connection Types

| Type | URI Format | Example |
|------|------------|---------|
| PostgreSQL | `postgresql://user:pass@host:5432/db` | Database operations |
| MySQL | `mysql://user:pass@host:3306/db` | Database operations |
| AWS | `aws://?region_name=us-east-1` | S3, EMR, Lambda |
| GCP | `google-cloud-platform://?project=my-project` | BigQuery, GCS |
| HTTP | `http://user:pass@api.example.com` | REST APIs |
| Slack | `slack://:token@` | Notifications |

### Variables

```python
from airflow.models import Variable

# Set variable
Variable.set("my_config", {"key": "value"}, serialize_json=True)

# Get variable
config = Variable.get("my_config", deserialize_json=True)

# With default
value = Variable.get("missing_key", default_var="default")
```

## Security

### RBAC Configuration

```python
# webserver_config.py
AUTH_ROLE_ADMIN = 'Admin'
AUTH_ROLE_PUBLIC = 'Public'

AUTH_TYPE = AUTH_DB

AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = "Viewer"

# OAuth configuration
from flask_appbuilder.security.manager import AUTH_OAUTH

AUTH_TYPE = AUTH_OAUTH
OAUTH_PROVIDERS = [{
    'name': 'google',
    'token_key': 'access_token',
    'icon': 'fa-google',
    'remote_app': {
        'client_id': 'YOUR_CLIENT_ID',
        'client_secret': 'YOUR_CLIENT_SECRET',
        'api_base_url': 'https://www.googleapis.com/oauth2/v2/',
        'client_kwargs': {'scope': 'email profile'},
        'access_token_url': 'https://oauth2.googleapis.com/token',
        'authorize_url': 'https://accounts.google.com/o/oauth2/auth',
    }
}]
```

### Built-in Roles

| Role | Permissions |
|------|-------------|
| **Admin** | Full access to all features |
| **Op** | Operations access, no configuration |
| **User** | DAG access, no admin features |
| **Viewer** | Read-only access |
| **Public** | No access (for unauthenticated) |

### Secrets Backend

```python
# Use AWS Secrets Manager
AIRFLOW__SECRETS__BACKEND = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
AIRFLOW__SECRETS__BACKEND_KWARGS = '{"connections_prefix": "airflow/connections", "variables_prefix": "airflow/variables"}'

# Use HashiCorp Vault
AIRFLOW__SECRETS__BACKEND = "airflow.providers.hashicorp.secrets.vault.VaultBackend"
AIRFLOW__SECRETS__BACKEND_KWARGS = '{"url": "http://vault:8200", "token": "your-token", "connections_path": "airflow/connections", "variables_path": "airflow/variables"}'
```

## Monitoring

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `dag_processing.total_parse_time` | Time to parse all DAGs | > 60 seconds |
| `scheduler.tasks.running` | Currently running tasks | Capacity limit |
| `scheduler.tasks.starving` | Tasks waiting for slots | > 0 sustained |
| `executor.queued_tasks` | Tasks in queue | Growing unbounded |
| `executor.running_tasks` | Tasks being executed | Near capacity |
| `pool.open_slots` | Available pool slots | < 10% |
| `dag_run.duration` | DAG run duration | 2x normal |

### StatsD / Prometheus

```yaml
# docker-compose.yml
statsd-exporter:
  image: prom/statsd-exporter:latest
  ports:
    - "9102:9102"  # Prometheus metrics
    - "9125:9125/udp"  # StatsD input
  volumes:
    - ./statsd-mapping.yml:/tmp/statsd-mapping.yml
  command:
    - "--statsd.mapping-config=/tmp/statsd-mapping.yml"
```

### Health Checks

```bash
# Scheduler health
curl http://localhost:8974/health

# Web server health  
curl http://localhost:8080/health

# Database connectivity
airflow db check
```

## Scaling Considerations

### Celery Workers

```yaml
# Scale workers
docker-compose up -d --scale worker=5

# Worker resource limits
worker:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
```

### Kubernetes Executor Scaling

```yaml
# Pod template for workers
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: base
      image: apache/airflow:2.8.0
      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
        limits:
          cpu: "2"
          memory: "4Gi"
  nodeSelector:
    workload-type: airflow-worker
```

### Database Optimization

```sql
-- Increase connection limits
ALTER SYSTEM SET max_connections = 200;

-- Add indexes for performance
CREATE INDEX CONCURRENTLY idx_task_instance_state 
ON task_instance (state, dag_id, task_id);

-- Regular cleanup
DELETE FROM task_instance 
WHERE execution_date < NOW() - INTERVAL '90 days';
```
