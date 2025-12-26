# Datadog Integration Usage Guide

## Docker Compose Deployment

### Development Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  datadog-agent:
    image: gcr.io/datadoghq/agent:7
    container_name: datadog-agent
    environment:
      - DD_API_KEY=${DD_API_KEY}
      - DD_SITE=datadoghq.com
      - DD_APM_ENABLED=true
      - DD_APM_NON_LOCAL_TRAFFIC=true
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_CONTAINER_EXCLUDE="name:datadog-agent"
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    ports:
      - '8126:8126' # APM
      - '8125:8125/udp' # DogStatsD

  # Example application with APM
  web-app:
    build: .
    environment:
      - DD_AGENT_HOST=datadog-agent
      - DD_TRACE_AGENT_PORT=8126
      - DD_ENV=development
      - DD_SERVICE=web-app
      - DD_VERSION=1.0.0
    labels:
      com.datadoghq.ad.logs: '[{"source": "python", "service": "web-app"}]'
    depends_on:
      - datadog-agent
```

### Production with Custom Config

```yaml
# docker-compose.yml
version: '3.8'

services:
  datadog-agent:
    image: gcr.io/datadoghq/agent:7
    container_name: datadog-agent
    environment:
      - DD_API_KEY=${DD_API_KEY}
      - DD_SITE=datadoghq.com
      - DD_ENV=production
      - DD_APM_ENABLED=true
      - DD_LOGS_ENABLED=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_SYSTEM_PROBE_ENABLED=true
      - DD_RUNTIME_SECURITY_CONFIG_ENABLED=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /sys/kernel/debug:/sys/kernel/debug
      - ./datadog.yaml:/etc/datadog-agent/datadog.yaml:ro
      - ./conf.d:/etc/datadog-agent/conf.d:ro
    ports:
      - '8126:8126'
      - '8125:8125/udp'
    cap_add:
      - SYS_ADMIN
      - SYS_RESOURCE
      - SYS_PTRACE
      - NET_ADMIN
      - NET_BROADCAST
      - NET_RAW
      - IPC_LOCK
      - CHOWN
    security_opt:
      - apparmor:unconfined
```

## Kubernetes Deployment

### Helm Installation

```bash
# Add Datadog Helm repo
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Create namespace
kubectl create namespace datadog

# Create secrets
kubectl create secret generic datadog-secret \
  --namespace datadog \
  --from-literal=api-key=<API_KEY> \
  --from-literal=app-key=<APP_KEY>

# Install Datadog Agent
helm install datadog-agent datadog/datadog \
  --namespace datadog \
  --set datadog.apiKeyExistingSecret=datadog-secret \
  --set datadog.appKeyExistingSecret=datadog-secret \
  --set datadog.site=datadoghq.com \
  --set datadog.apm.portEnabled=true \
  --set datadog.logs.enabled=true \
  --set datadog.logs.containerCollectAll=true \
  --set datadog.processAgent.enabled=true \
  --set datadog.networkMonitoring.enabled=true \
  --set clusterAgent.enabled=true \
  --set clusterAgent.metricsProvider.enabled=true
```

### Helm Values File

```yaml
# values.yaml
datadog:
  apiKeyExistingSecret: datadog-secret
  appKeyExistingSecret: datadog-secret
  site: datadoghq.com

  clusterName: production-k8s

  tags:
    - env:production
    - team:platform

  apm:
    portEnabled: true
    socketEnabled: true

  logs:
    enabled: true
    containerCollectAll: true
    containerCollectUsingFiles: true

  processAgent:
    enabled: true
    processCollection: true

  networkMonitoring:
    enabled: true

  securityAgent:
    runtime:
      enabled: true
    compliance:
      enabled: true

  prometheusScrape:
    enabled: true
    serviceEndpoints: true

clusterAgent:
  enabled: true
  replicas: 2
  metricsProvider:
    enabled: true
  admissionController:
    enabled: true
    mutateUnlabelled: true

agents:
  tolerations:
    - operator: Exists

  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

  podAnnotations:
    ad.datadoghq.com/agent.logs: '[{"source":"datadog-agent","service":"datadog-agent"}]'
```

### Application Pod Configuration

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    tags.datadoghq.com/env: production
    tags.datadoghq.com/service: my-app
    tags.datadoghq.com/version: '1.0.0'
spec:
  template:
    metadata:
      labels:
        tags.datadoghq.com/env: production
        tags.datadoghq.com/service: my-app
        tags.datadoghq.com/version: '1.0.0'
      annotations:
        ad.datadoghq.com/my-app.logs: |
          [{
            "source": "python",
            "service": "my-app",
            "log_processing_rules": [{
              "type": "exclude_at_match",
              "name": "exclude_healthcheck",
              "pattern": "GET /health"
            }]
          }]
    spec:
      containers:
        - name: my-app
          image: my-app:1.0.0
          env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DD_ENV
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/env']
            - name: DD_SERVICE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/service']
            - name: DD_VERSION
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/version']
            - name: DD_LOGS_INJECTION
              value: 'true'
            - name: DD_TRACE_SAMPLE_RATE
              value: '1'
```

## Dashboard and Visualization

### Dashboard API

```python
from datadog_api_client.v1.api.dashboards_api import DashboardsApi
from datadog_api_client.v1.model.dashboard import Dashboard
from datadog_api_client.v1.model.dashboard_layout_type import DashboardLayoutType

dashboard = Dashboard(
    title="Application Performance",
    layout_type=DashboardLayoutType.ORDERED,
    widgets=[
        {
            "definition": {
                "type": "timeseries",
                "title": "Request Rate",
                "requests": [{
                    "q": "sum:trace.flask.request.hits{env:production}.as_rate()",
                    "display_type": "line"
                }]
            }
        },
        {
            "definition": {
                "type": "timeseries",
                "title": "Error Rate",
                "requests": [{
                    "q": "sum:trace.flask.request.errors{env:production}.as_rate()",
                    "display_type": "bars",
                    "style": {"palette": "warm"}
                }]
            }
        },
        {
            "definition": {
                "type": "timeseries",
                "title": "P99 Latency",
                "requests": [{
                    "q": "p99:trace.flask.request.duration{env:production}",
                    "display_type": "line"
                }]
            }
        },
        {
            "definition": {
                "type": "toplist",
                "title": "Slowest Endpoints",
                "requests": [{
                    "q": "avg:trace.flask.request.duration{env:production} by {resource_name}",
                    "conditional_formats": [{
                        "comparator": ">",
                        "value": 500,
                        "palette": "white_on_red"
                    }]
                }]
            }
        }
    ]
)

api = DashboardsApi(api_client)
response = api.create_dashboard(body=dashboard)
print(f"Dashboard URL: https://app.datadoghq.com{response.url}")
```

## Log Management

### Log Pipeline Configuration

```yaml
# Log parsing pipeline (via API or UI)
pipeline:
  name: 'Python Application Logs'
  filter:
    query: 'source:python'
  processors:
    - grok_parser:
        source: message
        samples:
          - '2024-01-15 10:30:00,123 INFO [module] - User login successful'
        grok:
          match_rules: |
            rule %{date("yyyy-MM-dd HH:mm:ss,SSS"):timestamp} %{word:level} \[%{word:module}\] - %{data:message}

    - status_remapper:
        sources:
          - level

    - date_remapper:
        sources:
          - timestamp

    - attribute_remapper:
        source: module
        target: logger.name

    - category_processor:
        categories:
          - filter:
              query: '@level:ERROR'
            name: 'Error'
          - filter:
              query: '@level:WARN'
            name: 'Warning'
        target: severity
```

### Log Queries

```bash
# Search examples
service:web-app status:error
service:api-gateway @http.status_code:>=500
@duration:>1000 env:production
host:web-* source:nginx @http.url:/api/*
@user.id:12345 -status:info
```

## Troubleshooting

### Common Issues

| Issue                  | Cause                     | Solution                     |
| ---------------------- | ------------------------- | ---------------------------- |
| No data in Datadog     | Invalid API key           | Verify key in agent status   |
| Missing APM traces     | Agent not reachable       | Check network, port 8126     |
| Container logs missing | Docker socket not mounted | Mount /var/run/docker.sock   |
| High agent CPU         | Too many checks           | Reduce check frequency       |
| Metrics delayed        | Clock skew                | Sync NTP on hosts            |
| Tags not appearing     | Env vars not set          | Verify DD_TAGS configuration |

### Diagnostic Commands

```bash
# Agent status
datadog-agent status
docker exec datadog-agent agent status

# Check configuration
datadog-agent configcheck
datadog-agent check <integration_name>

# Flare (support bundle)
datadog-agent flare

# APM troubleshooting
curl http://localhost:8126/info

# List enabled integrations
datadog-agent integration list

# Test connectivity
datadog-agent diagnose

# View logs
tail -f /var/log/datadog/agent.log
docker logs datadog-agent
```

### Agent Debug Mode

```yaml
# datadog.yaml
log_level: debug

# Or via environment
DD_LOG_LEVEL=debug
```

## Best Practices

### Tagging Strategy

```yaml
# Recommended tags
tags:
  - env:production # Environment
  - service:api-gateway # Service name
  - version:1.2.3 # Version
  - team:platform # Owner team
  - cost-center:12345 # Cost allocation
  - region:us-east-1 # Region
```

### Cost Optimization

1. **Sampling** - Use intelligent sampling for high-volume traces
2. **Log exclusion** - Filter out noisy logs (health checks)
3. **Metric aggregation** - Use distributions over histograms
4. **Custom metrics** - Monitor cardinality
5. **Retention** - Set appropriate retention periods

### Security Checklist

- [ ] Rotate API keys regularly
- [ ] Use app keys for read-only access
- [ ] Enable RBAC for team access
- [ ] Audit API key usage
- [ ] Encrypt secrets in deployment
- [ ] Use network segmentation for agent
- [ ] Enable SSO/SAML for user access

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Configuration and integrations
