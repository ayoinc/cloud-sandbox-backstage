# Datadog Integration Overview

## Architecture Deep Dive

### Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Datadog Agent 7                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Core Agent                           │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐            │    │
│  │  │ Collector │  │ Forwarder │  │ Aggregator│            │    │
│  │  └───────────┘  └───────────┘  └───────────┘            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Trace Agent  │  │ Process Agent│  │ Security Agt │           │
│  │   :8126      │  │              │  │              │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Integrations                          │    │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐        │    │
│  │  │nginx│ │redis│ │mysql│ │kafka│ │k8s  │ │docker│       │    │
│  │  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Application ──► APM Library ──► Trace Agent ──► Datadog
     │                              │
     ├──► StatsD ─────────────────►─┤
     │                              │
     └──► Log Files ──► Logs Agent ─┘
```

## Configuration

### Agent Configuration (datadog.yaml)

```yaml
# /etc/datadog-agent/datadog.yaml

# API Key (required)
api_key: <YOUR_API_KEY>

# Datadog site
site: datadoghq.com

# Hostname override
hostname: web-server-01

# Tags applied to all metrics
tags:
  - env:production
  - team:platform
  - service:api

# APM Configuration
apm_config:
  enabled: true
  env: production
  apm_dd_url: https://trace.agent.datadoghq.com
  receiver_port: 8126
  # Sampling
  max_traces_per_second: 100
  # Ignore specific resources
  ignore_resources:
    - "GET /health"
    - "GET /ready"

# Logs Configuration
logs_enabled: true
logs_config:
  container_collect_all: true
  processing_rules:
    - type: exclude_at_match
      name: exclude_healthchecks
      pattern: "health_check"

# Process Monitoring
process_config:
  enabled: "true"
  container_collection:
    enabled: true

# Network Performance Monitoring
network_config:
  enabled: true

# Security Monitoring
runtime_security_config:
  enabled: true

# Proxy configuration
proxy:
  https: http://proxy.example.com:3128
  no_proxy:
    - 169.254.169.254

# DogStatsD configuration
dogstatsd_port: 8125
dogstatsd_non_local_traffic: true
dogstatsd_origin_detection: true
```

### Integration Configuration

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
init_config:

instances:
  - nginx_status_url: http://localhost:8080/nginx_status
    tags:
      - role:webserver
      - cluster:production

# /etc/datadog-agent/conf.d/postgres.d/conf.yaml
init_config:

instances:
  - host: localhost
    port: 5432
    username: datadog
    password: <PASSWORD>
    dbname: postgres
    ssl: require
    tags:
      - db:postgres-primary
    # Query metrics
    collect_function_metrics: true
    collect_count_metrics: true
    collect_database_size_metrics: true
```

### Log Collection Configuration

```yaml
# /etc/datadog-agent/conf.d/python.d/conf.yaml
logs:
  - type: file
    path: /var/log/myapp/*.log
    service: myapp
    source: python
    sourcecategory: sourcecode
    tags:
      - env:production
    # Multi-line log handling
    log_processing_rules:
      - type: multi_line
        name: log_start_with_date
        pattern: \d{4}-\d{2}-\d{2}

  - type: docker
    image: myapp
    service: myapp
    source: python

  - type: tcp
    port: 10514
    service: syslog
    source: syslog
```

## APM Tracing Libraries

### Python

```python
# pip install ddtrace

# Auto-instrumentation
# ddtrace-run python app.py

# Or manual instrumentation
from ddtrace import tracer, patch_all

# Patch all supported libraries
patch_all()

# Configure tracer
tracer.configure(
    hostname='localhost',
    port=8126,
    env='production',
    service='my-python-app',
    version='1.0.0'
)

# Custom span
from ddtrace import tracer

@tracer.wrap(service='my-service', resource='process_order')
def process_order(order_id):
    # Add tags to current span
    span = tracer.current_span()
    span.set_tag('order.id', order_id)
    
    # Create child span
    with tracer.trace('database.query') as span:
        span.set_tag('db.type', 'postgresql')
        result = db.query(order_id)
    
    return result

# Flask example
from flask import Flask
from ddtrace import patch_all
from ddtrace.contrib.flask import TraceMiddleware

patch_all()

app = Flask(__name__)
TraceMiddleware(app, tracer, service='flask-app')

@app.route('/api/users/<user_id>')
def get_user(user_id):
    span = tracer.current_span()
    span.set_tag('user.id', user_id)
    return get_user_from_db(user_id)
```

### Node.js

```javascript
// npm install dd-trace

// Initialize tracer (must be first)
const tracer = require('dd-trace').init({
  env: 'production',
  service: 'my-node-app',
  version: '1.0.0',
  logInjection: true,
  runtimeMetrics: true
});

// Express example
const express = require('express');
const app = express();

app.get('/api/orders/:id', (req, res) => {
  const span = tracer.scope().active();
  span.setTag('order.id', req.params.id);
  
  // Custom span
  const childSpan = tracer.startSpan('database.query', {
    childOf: span,
    tags: { 'db.type': 'postgresql' }
  });
  
  const order = db.getOrder(req.params.id);
  childSpan.finish();
  
  res.json(order);
});

// Manual instrumentation
tracer.trace('custom.operation', { resource: 'process-data' }, (span) => {
  span.setTag('custom.tag', 'value');
  // Do work
  span.finish();
});
```

### Java

```java
// Add to build.gradle
// implementation 'com.datadoghq:dd-trace-api:1.29.0'

// JVM arguments
// -javaagent:/path/to/dd-java-agent.jar
// -Ddd.service=my-java-app
// -Ddd.env=production
// -Ddd.version=1.0.0

import datadog.trace.api.Trace;
import datadog.trace.api.DDTags;
import io.opentracing.Span;
import io.opentracing.util.GlobalTracer;

public class OrderService {
    
    @Trace(operationName = "process.order", resourceName = "OrderService.processOrder")
    public Order processOrder(String orderId) {
        Span span = GlobalTracer.get().activeSpan();
        span.setTag("order.id", orderId);
        span.setTag(DDTags.SERVICE_NAME, "order-service");
        
        try {
            Order order = orderRepository.findById(orderId);
            span.setTag("order.status", order.getStatus());
            return order;
        } catch (Exception e) {
            span.setTag(DDTags.ERROR_MSG, e.getMessage());
            throw e;
        }
    }
}
```

## Custom Metrics

### DogStatsD

```python
# pip install datadog

from datadog import DogStatsd

statsd = DogStatsd(host='localhost', port=8125)

# Counter
statsd.increment('page.views', tags=['page:home'])

# Gauge
statsd.gauge('queue.size', 42, tags=['queue:orders'])

# Histogram
statsd.histogram('request.latency', 0.5, tags=['endpoint:/api/users'])

# Distribution
statsd.distribution('request.duration', 0.123)

# Set (unique values)
statsd.set('users.unique', 'user123')

# Timing
with statsd.timed('database.query.time'):
    execute_query()

# Service check
statsd.service_check('database.health', 0, tags=['db:primary'])  # 0=OK
```

### API Submission

```python
from datadog_api_client import ApiClient, Configuration
from datadog_api_client.v1.api.metrics_api import MetricsApi
from datadog_api_client.v1.model.metrics_payload import MetricsPayload
from datadog_api_client.v1.model.series import Series
from datadog_api_client.v1.model.point import Point
import time

configuration = Configuration()
configuration.api_key['apiKeyAuth'] = '<API_KEY>'
configuration.api_key['appKeyAuth'] = '<APP_KEY>'

with ApiClient(configuration) as api_client:
    api = MetricsApi(api_client)
    
    body = MetricsPayload(
        series=[
            Series(
                metric="custom.business.metric",
                type="gauge",
                points=[Point([time.time(), 123.45])],
                tags=["env:production", "team:platform"]
            )
        ]
    )
    
    api.submit_metrics(body=body)
```

## Alerting and Monitors

### Monitor Types

| Type | Use Case | Example |
|------|----------|---------|
| Metric | Threshold alerting | CPU > 80% |
| APM | Latency, error rate | p99 > 500ms |
| Log | Log pattern matching | Error count > 10 |
| Composite | Multiple conditions | CPU high AND memory high |
| Anomaly | ML-based detection | Unusual traffic |
| Forecast | Predictive alerts | Disk full in 7 days |
| Outlier | Compare to peers | Host slower than others |
| Integration | Service-specific | Kafka lag > 1000 |

### Monitor API Example

```python
from datadog_api_client.v1.api.monitors_api import MonitorsApi
from datadog_api_client.v1.model.monitor import Monitor
from datadog_api_client.v1.model.monitor_type import MonitorType

body = Monitor(
    name="High CPU on web servers",
    type=MonitorType.METRIC_ALERT,
    query="avg(last_5m):avg:system.cpu.user{role:web} by {host} > 80",
    message="""
CPU is high on {{host.name}}

@slack-platform-alerts
@pagerduty-platform
    """,
    tags=["team:platform", "severity:high"],
    priority=2,
    options={
        "thresholds": {
            "critical": 80,
            "warning": 70
        },
        "notify_audit": True,
        "require_full_window": False,
        "notify_no_data": True,
        "renotify_interval": 60,
        "escalation_message": "CPU still high after 1 hour",
        "include_tags": True
    }
)

api = MonitorsApi(api_client)
response = api.create_monitor(body=body)
```

## Security Configuration

### API Key Management

```bash
# Environment variables
export DD_API_KEY=<API_KEY>
export DD_APP_KEY=<APP_KEY>

# Using secrets management
# AWS Secrets Manager
DD_API_KEY=$(aws secretsmanager get-secret-value --secret-id datadog/api-key --query SecretString --output text)

# Kubernetes secret
kubectl create secret generic datadog-secret \
  --from-literal=api-key=<API_KEY> \
  --from-literal=app-key=<APP_KEY>
```

### RBAC Configuration

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Standard | View/edit dashboards, monitors |
| Read-Only | View only |
| Custom | Granular permissions |

## Integrations

### Cloud Integrations

```yaml
# AWS Integration
- Automatic EC2, RDS, Lambda discovery
- CloudWatch metrics ingestion
- AWS-specific dashboards
- Resource tagging sync

# GCP Integration
- Compute Engine, GKE monitoring
- Cloud SQL, Pub/Sub metrics
- Stackdriver integration

# Azure Integration
- Virtual Machines, AKS
- Azure Monitor metrics
- App Service monitoring
```

### Common Integrations

| Category | Integrations |
|----------|--------------|
| Web Servers | nginx, Apache, HAProxy |
| Databases | PostgreSQL, MySQL, MongoDB, Redis |
| Message Queues | Kafka, RabbitMQ, SQS |
| Containers | Docker, Kubernetes, ECS |
| CI/CD | Jenkins, GitLab, CircleCI |
| Cloud | AWS, GCP, Azure |

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
