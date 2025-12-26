# New Relic Integration Usage Guide

## Docker Compose Deployment

### Infrastructure Agent

```yaml
# docker-compose.yml
version: '3.8'

services:
  newrelic-infra:
    image: newrelic/infrastructure:latest
    container_name: newrelic-infra
    privileged: true
    pid: host
    network_mode: host
    cap_add:
      - SYS_PTRACE
    environment:
      - NRIA_LICENSE_KEY=${NEW_RELIC_LICENSE_KEY}
      - NRIA_DISPLAY_NAME=docker-host
      - NRIA_CUSTOM_ATTRIBUTES={"environment":"production","team":"platform"}
    volumes:
      - /:/host:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - newrelic-data:/var/db/newrelic-infra

  # Application with APM
  web-app:
    build: .
    environment:
      - NEW_RELIC_LICENSE_KEY=${NEW_RELIC_LICENSE_KEY}
      - NEW_RELIC_APP_NAME=My Web App
      - NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true
      - NEW_RELIC_LOG_LEVEL=info
      - NEW_RELIC_LABELS=Environment:production;Team:platform
    labels:
      com.newrelic.display_name: web-app
      com.newrelic.environment: production

volumes:
  newrelic-data:
```

### OpenTelemetry Collector

```yaml
# docker-compose.yml
version: '3.8'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ['--config=/etc/otel-collector-config.yaml']
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - '4317:4317' # OTLP gRPC
      - '4318:4318' # OTLP HTTP
```

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1000

exporters:
  otlp:
    endpoint: otlp.nr-data.net:4317
    headers:
      api-key: ${NEW_RELIC_LICENSE_KEY}

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp]
```

## Kubernetes Deployment

### Helm Installation

```bash
# Add New Relic Helm repo
helm repo add newrelic https://helm-charts.newrelic.com
helm repo update

# Create namespace and secret
kubectl create namespace newrelic
kubectl create secret generic newrelic-license-key \
  --namespace newrelic \
  --from-literal=license-key=<LICENSE_KEY>

# Install New Relic bundle
helm install newrelic-bundle newrelic/nri-bundle \
  --namespace newrelic \
  --set global.licenseKey=<LICENSE_KEY> \
  --set global.cluster=production-k8s \
  --set newrelic-infrastructure.enabled=true \
  --set kube-state-metrics.enabled=true \
  --set nri-metadata-injection.enabled=true \
  --set nri-kube-events.enabled=true \
  --set newrelic-logging.enabled=true \
  --set nri-prometheus.enabled=true
```

### Helm Values File

```yaml
# values.yaml
global:
  licenseKey: '' # Set via --set or secret
  cluster: production-k8s

newrelic-infrastructure:
  enabled: true
  privileged: true
  config:
    custom_attributes:
      environment: production
      team: platform

kube-state-metrics:
  enabled: true

nri-metadata-injection:
  enabled: true

nri-kube-events:
  enabled: true

newrelic-logging:
  enabled: true
  lowDataMode: false
  fluentBit:
    config:
      inputs: |
        [INPUT]
            Name tail
            Tag kube.*
            Path /var/log/containers/*.log
            Parser docker
            DB /var/log/fluentbit-state.db
            Mem_Buf_Limit 5MB
            Skip_Long_Lines On
      filters: |
        [FILTER]
            Name kubernetes
            Match kube.*
            Merge_Log On
            Keep_Log Off

nri-prometheus:
  enabled: true
  config:
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels:
              [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
```

### Application Pod with APM

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8080'
    spec:
      containers:
        - name: my-app
          image: my-app:1.0.0
          env:
            - name: NEW_RELIC_LICENSE_KEY
              valueFrom:
                secretKeyRef:
                  name: newrelic-license-key
                  key: license-key
            - name: NEW_RELIC_APP_NAME
              value: 'my-app'
            - name: NEW_RELIC_DISTRIBUTED_TRACING_ENABLED
              value: 'true'
            - name: NEW_RELIC_LOG_LEVEL
              value: 'info'
            - name: NEW_RELIC_LABELS
              value: 'Environment:production;Team:platform;Cluster:$(CLUSTER_NAME)'
            - name: CLUSTER_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['cluster']
```

## API Usage

### NerdGraph (GraphQL API)

```bash
# Query example
curl -X POST 'https://api.newrelic.com/graphql' \
  -H 'Content-Type: application/json' \
  -H 'API-Key: <USER_KEY>' \
  -d '{
    "query": "{
      actor {
        account(id: <ACCOUNT_ID>) {
          nrql(query: \"SELECT count(*) FROM Transaction SINCE 1 hour ago\") {
            results
          }
        }
      }
    }"
  }'
```

### Python SDK

```python
# pip install newrelic-telemetry-sdk

from newrelic_telemetry_sdk import MetricClient, GaugeMetric, CountMetric

# Initialize client
metric_client = MetricClient(license_key='<LICENSE_KEY>')

# Send metrics
batch = [
    GaugeMetric('custom.temperature', 72.5, {'location': 'office'}),
    CountMetric('custom.requests', 100, interval_ms=60000)
]

response = metric_client.send_batch(batch)
```

### Event API

```python
import requests
import json

url = 'https://insights-collector.newrelic.com/v1/accounts/<ACCOUNT_ID>/events'
headers = {
    'Content-Type': 'application/json',
    'Api-Key': '<INSERT_KEY>'
}

events = [
    {
        'eventType': 'OrderCreated',
        'orderId': '12345',
        'customerId': 'cust_001',
        'amount': 99.99,
        'status': 'pending'
    }
]

response = requests.post(url, headers=headers, data=json.dumps(events))
print(f"Status: {response.status_code}")
```

## Dashboard Creation

### Dashboard API

```python
import requests

url = 'https://api.newrelic.com/graphql'
headers = {
    'Content-Type': 'application/json',
    'API-Key': '<USER_KEY>'
}

mutation = """
mutation {
  dashboardCreate(
    accountId: <ACCOUNT_ID>,
    dashboard: {
      name: "Application Performance",
      pages: [
        {
          name: "Overview",
          widgets: [
            {
              title: "Requests per Minute",
              visualization: { id: "viz.line" },
              rawConfiguration: {
                nrqlQueries: [
                  {
                    accountId: <ACCOUNT_ID>,
                    query: "SELECT rate(count(*), 1 minute) FROM Transaction TIMESERIES"
                  }
                ]
              }
            },
            {
              title: "Error Rate",
              visualization: { id: "viz.billboard" },
              rawConfiguration: {
                nrqlQueries: [
                  {
                    accountId: <ACCOUNT_ID>,
                    query: "SELECT percentage(count(*), WHERE error IS true) FROM Transaction"
                  }
                ],
                thresholds: [
                  { value: 1, alertSeverity: "WARNING" },
                  { value: 5, alertSeverity: "CRITICAL" }
                ]
              }
            }
          ]
        }
      ]
    }
  ) {
    entityResult {
      guid
    }
    errors {
      description
    }
  }
}
"""

response = requests.post(url, headers=headers, json={'query': mutation})
print(response.json())
```

## Troubleshooting

### Common Issues

| Issue                     | Cause                     | Solution                     |
| ------------------------- | ------------------------- | ---------------------------- |
| No data in New Relic      | Invalid license key       | Verify key format and region |
| APM traces missing        | Agent not initialized     | Check agent startup logs     |
| Container metrics missing | Docker socket not mounted | Mount /var/run/docker.sock   |
| High agent memory         | Too many integrations     | Reduce collection frequency  |
| NRQL timeout              | Query too complex         | Add LIMIT, reduce time range |
| Labels not appearing      | Wrong format              | Use key:value format         |

### Diagnostic Commands

```bash
# Infrastructure agent status
sudo systemctl status newrelic-infra
sudo newrelic-infra -validate

# View agent logs
tail -f /var/log/newrelic-infra/newrelic-infra.log

# Docker agent logs
docker logs newrelic-infra

# Test connectivity
curl -I https://infra-api.newrelic.com

# Validate configuration
newrelic-infra -config_path /etc/newrelic-infra.yml -validate

# Python agent debug
NEW_RELIC_LOG_LEVEL=debug newrelic-admin run-program python app.py

# List running integrations
sudo ls -la /var/db/newrelic-infra/newrelic-integrations/
```

### Debug Logging

```yaml
# /etc/newrelic-infra.yml
log:
  level: debug
  file: /var/log/newrelic-infra/newrelic-infra.log

# Environment variable
NRIA_LOG_LEVEL=debug
```

## Best Practices

### Tagging Strategy

```yaml
# Consistent labels across all agents
labels:
  Environment: production
  Team: platform
  Service: api-gateway
  Region: us-east-1
  CostCenter: '12345'
```

### Query Optimization

1. **Add time constraints** - Always use SINCE/UNTIL
2. **Limit results** - Use LIMIT for large result sets
3. **Use facets wisely** - Limit FACET cardinality
4. **Avoid wildcards** - Be specific with WHERE clauses
5. **Use sampling** - EXTRAPOLATE for high-volume data

### Security Checklist

- [ ] Use environment variables for keys
- [ ] Rotate license keys periodically
- [ ] Enable SSO/SAML for user access
- [ ] Set up RBAC for team access
- [ ] Audit API key usage
- [ ] Encrypt high security data
- [ ] Review data retention policies

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Configuration and NRQL
