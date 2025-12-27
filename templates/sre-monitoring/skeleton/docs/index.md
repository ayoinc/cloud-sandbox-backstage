# ${{ values.name }}

${{ values.description }}

## Overview

This SRE monitoring stack provides production-ready observability for **${{ values.targetType }}** infrastructure. Built on industry-standard tools, it delivers comprehensive metrics collection, intelligent alerting with SLO-based burn rates, and rich visualization dashboards.

The stack includes:

- **Prometheus**: Time-series metrics collection and alerting engine
- **Grafana**: Visualization and dashboarding platform
- **Alertmanager**: Alert routing, grouping, and notification management
- **Node Exporter**: Host-level metrics collection for infrastructure monitoring
- **SLO-based Alerting**: Multi-window, multi-burn-rate alerts based on Google SRE best practices

```d2
direction: right

title: {
  label: Monitoring Stack Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

targets: Monitoring Targets {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  apps: Applications {
    shape: rectangle
    style.fill: "#BBDEFB"
    label: "/metrics endpoints"
  }

  nodes: Infrastructure {
    shape: rectangle
    style.fill: "#BBDEFB"
    label: "Node Exporters"
  }

  k8s: Kubernetes {
    shape: rectangle
    style.fill: "#BBDEFB"
    label: "kube-state-metrics"
  }
}

prometheus: Prometheus {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  tsdb: TSDB {
    shape: cylinder
    style.fill: "#C8E6C9"
    label: "Time Series\nDatabase"
  }

  rules: Alert Rules {
    shape: document
    style.fill: "#C8E6C9"
  }
}

alertmanager: Alertmanager {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"

  routing: Routing {
    shape: document
    style.fill: "#FFEBEE"
    label: "Route by\nSeverity"
  }

  inhibit: Inhibition {
    shape: document
    style.fill: "#FFEBEE"
    label: "Suppress\nDuplicates"
  }
}

notifications: Notification Channels {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  slack: Slack {
    shape: rectangle
    style.fill: "#FFECB3"
  }

  pagerduty: PagerDuty {
    shape: rectangle
    style.fill: "#FFECB3"
  }

  email: Email {
    shape: rectangle
    style.fill: "#FFECB3"
  }
}

grafana: Grafana {
  shape: hexagon
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"

  dashboards: Dashboards {
    shape: document
    style.fill: "#F3E5F5"
  }

  datasource: Data Sources {
    shape: cylinder
    style.fill: "#F3E5F5"
  }
}

users: Users/SRE Team {
  shape: person
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

targets.apps -> prometheus: scrape
targets.nodes -> prometheus: scrape
targets.k8s -> prometheus: scrape

prometheus.rules -> alertmanager: firing alerts
prometheus.tsdb -> grafana.datasource: PromQL queries

alertmanager.routing -> notifications.slack
alertmanager.routing -> notifications.pagerduty
alertmanager.routing -> notifications.email

grafana.dashboards -> users: visualize
notifications -> users: notify
```

---

## Configuration Summary

| Setting                | Value                                   |
| ---------------------- | --------------------------------------- |
| Stack Name             | `${{ values.name }}`                    |
| Target Infrastructure  | `${{ values.targetType }}`              |
| Owner                  | `${{ values.owner }}`                   |
| Prometheus URL         | `${{ values.prometheusUrl }}`           |
| Grafana URL            | `${{ values.grafanaUrl }}`              |
| Alertmanager URL       | `${{ values.alertmanagerUrl }}`         |
| Warning Threshold      | `${{ values.warningThreshold }}%`       |
| Critical Threshold     | `${{ values.criticalThreshold }}%`      |

---

## Infrastructure Components

### Prometheus

The central metrics collection and alerting engine. Prometheus scrapes metrics from configured targets at regular intervals and stores them in its time-series database (TSDB).

| Configuration      | Value                              |
| ------------------ | ---------------------------------- |
| Version            | v2.48.0                            |
| Scrape Interval    | 15 seconds                         |
| Evaluation Interval| 15 seconds                         |
| Retention          | Default (15 days)                  |
| Port               | 9090                               |

**Key Features:**
- Pull-based metrics collection
- Powerful PromQL query language
- Built-in alerting rules evaluation
- Service discovery for dynamic targets

### Grafana

Visualization platform for creating and sharing dashboards. Pre-configured with Prometheus as a data source and includes ready-to-use dashboards.

| Configuration      | Value                              |
| ------------------ | ---------------------------------- |
| Version            | v10.2.2                            |
| Port               | 3000                               |
| Default Credentials| admin/admin                        |
| Provisioning       | Automatic via ConfigMaps           |

**Included Dashboards:**
- System Overview - Infrastructure health at a glance
- Application Metrics - Service-level metrics and performance
- SLO Dashboard - Error budget tracking and burn rate visualization

### Alertmanager

Handles alert routing, grouping, deduplication, and notification delivery. Configured with severity-based routing to appropriate channels.

| Configuration      | Value                              |
| ------------------ | ---------------------------------- |
| Version            | v0.26.0                            |
| Port               | 9093                               |
| Resolve Timeout    | 5 minutes                          |
| Group Wait         | 10 seconds (0s for critical)       |

**Routing Strategy:**
- **Critical**: Immediate notification (0s wait), 5-minute repeat
- **Warning**: 10s group wait, 4-hour repeat interval
- **Info**: 5-minute batch, 24-hour repeat interval

### Node Exporter

Collects hardware and OS metrics from host machines. Essential for infrastructure monitoring.

| Configuration      | Value                              |
| ------------------ | ---------------------------------- |
| Version            | v1.7.0                             |
| Port               | 9100                               |
| Metrics            | CPU, Memory, Disk, Network         |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline that validates configurations, tests the monitoring stack, and deploys changes.

### Pipeline Stages

| Stage              | Trigger            | Description                                    |
| ------------------ | ------------------ | ---------------------------------------------- |
| Validate           | PR, Push           | Prometheus rules and config validation         |
| Lint Dashboards    | PR, Push           | JSON syntax and structure validation           |
| Test Stack         | PR, Push           | Spin up full stack and health checks           |
| Deploy             | Push to main       | Deploy rules and dashboards to production      |

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
  label: "promtool check\namtool check\nConfig validation"
}

lint: Lint Dashboards {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "JSON syntax\nSchema validation"
}

test: Test Stack {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Docker Compose\nHealth checks\nRules loaded"
}

review: Review {
  shape: diamond
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "Manual\nApproval"
}

deploy: Deploy {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Apply rules\nImport dashboards"
}

pr -> validate
pr -> lint
validate -> test
lint -> test
test -> review -> deploy
```

### Validation Tools

| Tool       | Purpose                                           |
| ---------- | ------------------------------------------------- |
| promtool   | Validate Prometheus configuration and rules       |
| amtool     | Validate Alertmanager configuration               |
| jq         | Validate Grafana dashboard JSON structure         |

---

## Prerequisites

### 1. Kubernetes Cluster

A running Kubernetes cluster with sufficient resources:

| Resource           | Minimum              | Recommended          |
| ------------------ | -------------------- | -------------------- |
| Nodes              | 1                    | 3+                   |
| CPU (per node)     | 2 cores              | 4+ cores             |
| Memory (per node)  | 4 GB                 | 8+ GB                |

```bash
# Verify cluster connectivity
kubectl cluster-info
kubectl get nodes
```

### 2. Helm (Package Manager)

Helm v3.x is required for deploying the Prometheus stack.

```bash
# Install Helm (macOS)
brew install helm

# Install Helm (Linux)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### 3. Required Helm Repositories

```bash
# Add Prometheus community charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Add Grafana charts
helm repo add grafana https://grafana.github.io/helm-charts

# Update repositories
helm repo update
```

### 4. Namespace Setup

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Set as default context (optional)
kubectl config set-context --current --namespace=monitoring
```

### 5. GitHub Repository Secrets

Configure these secrets in **Settings > Secrets and variables > Actions**:

| Secret             | Description                                    | Required |
| ------------------ | ---------------------------------------------- | -------- |
| `KUBECONFIG`       | Base64-encoded kubeconfig for cluster access   | Yes      |
| `GRAFANA_API_KEY`  | API key for Grafana dashboard provisioning     | Optional |
| `GRAFANA_URL`      | Grafana instance URL for API access            | Optional |
| `SLACK_WEBHOOK`    | Slack webhook URL for alert notifications      | Optional |
| `PAGERDUTY_KEY`    | PagerDuty service key for escalations          | Optional |

### 6. Local Development Requirements

For local development with Docker Compose:

| Tool               | Minimum Version      |
| ------------------ | -------------------- |
| Docker             | 20.10+               |
| Docker Compose     | 2.0+                 |

---

## Usage

### Local Development

Start the full monitoring stack locally using Docker Compose:

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Start the monitoring stack
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

Access the services:

| Service      | URL                       | Credentials       |
| ------------ | ------------------------- | ----------------- |
| Prometheus   | http://localhost:9090     | None              |
| Grafana      | http://localhost:3000     | admin / admin     |
| Alertmanager | http://localhost:9093     | None              |

### Kubernetes Deployment

#### Option 1: Using kube-prometheus-stack (Recommended)

```bash
# Create values override file
cat > values-override.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 30d
    resources:
      requests:
        memory: 1Gi
        cpu: 500m
      limits:
        memory: 2Gi
        cpu: 1000m

grafana:
  adminPassword: "your-secure-password"
  persistence:
    enabled: true
    size: 10Gi

alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'severity']
      receiver: 'default-receiver'
EOF

# Install the stack
helm install ${{ values.name }} prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values-override.yaml

# Verify deployment
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

#### Option 2: Apply Custom Resources

```bash
# Apply Prometheus rules
kubectl apply -f alerts/

# Apply Grafana dashboards as ConfigMaps
for dashboard in dashboards/*.json; do
  name=$(basename "$dashboard" .json)
  kubectl create configmap "grafana-dashboard-${name}" \
    --from-file="${dashboard}" \
    --namespace monitoring \
    -o yaml --dry-run=client | kubectl apply -f -
done
```

### Accessing Dashboards

#### Port Forwarding

```bash
# Prometheus
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring

# Grafana
kubectl port-forward svc/grafana 3000:80 -n monitoring

# Alertmanager
kubectl port-forward svc/alertmanager-operated 9093:9093 -n monitoring
```

#### Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - grafana.example.com
        - prometheus.example.com
      secretName: monitoring-tls
  rules:
    - host: grafana.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 80
    - host: prometheus.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-operated
                port:
                  number: 9090
```

---

## Adding Custom Metrics

### Application Instrumentation

Add Prometheus client libraries to your applications:

#### Python (prometheus-client)

```python
from prometheus_client import Counter, Histogram, start_http_server

# Define metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# Instrument your code
@REQUEST_LATENCY.labels(method='GET', endpoint='/api/users').time()
def get_users():
    # Your code here
    REQUEST_COUNT.labels(method='GET', endpoint='/api/users', status='200').inc()
    return users

# Start metrics server
start_http_server(8080)
```

#### Go (prometheus/client_golang)

```go
package main

import (
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    requestCount = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
)

func init() {
    prometheus.MustRegister(requestCount)
}

func main() {
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

### Configuring Prometheus Scrape Targets

Add new scrape configurations to `prometheus.yml`:

```yaml
scrape_configs:
  # Scrape your application
  - job_name: 'my-application'
    static_configs:
      - targets: ['my-app:8080']
    metrics_path: /metrics
    scrape_interval: 15s

  # Kubernetes pod auto-discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

### Pod Annotations for Auto-Discovery

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

---

## Adding Custom Dashboards

### Dashboard Structure

Create new dashboard JSON files in the `dashboards/` directory:

```json
{
  "title": "My Custom Dashboard",
  "uid": "my-custom-dashboard",
  "tags": ["custom", "${{ values.name }}"],
  "timezone": "browser",
  "schemaVersion": 38,
  "version": 1,
  "refresh": "30s",
  "panels": [
    {
      "id": 1,
      "title": "Request Rate",
      "type": "timeseries",
      "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 },
      "targets": [
        {
          "expr": "rate(http_requests_total[5m])",
          "legendFormat": "{{method}} {{endpoint}}"
        }
      ]
    }
  ]
}
```

### Importing Dashboards

```bash
# Using the provided script
./scripts/import-dashboards.sh

# Or manually via Grafana API
curl -X POST \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @dashboards/my-dashboard.json \
  "${GRAFANA_URL}/api/dashboards/db"
```

### Grafana Dashboard Best Practices

| Practice                     | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| Use variables                | Template dashboards with `$namespace`, `$pod`  |
| Set appropriate time ranges  | Default to 1h, allow user override             |
| Include documentation        | Add text panels explaining metrics             |
| Use consistent colors        | Green=good, Yellow=warning, Red=critical       |
| Group related panels         | Use rows to organize by category               |

---

## Alert Configuration

### Alert Thresholds

This stack comes pre-configured with the following alert thresholds:

| Severity   | Threshold                      | Response Time      |
| ---------- | ------------------------------ | ------------------ |
| Critical   | `${{ values.criticalThreshold }}%` | Immediate      |
| Warning    | `${{ values.warningThreshold }}%`  | Within 1 hour  |
| Info       | N/A                            | Next business day  |

### Pre-configured Alerts

#### Infrastructure Alerts

| Alert                    | Condition                           | Severity   |
| ------------------------ | ----------------------------------- | ---------- |
| HighCPUUsage             | CPU > ${{ values.warningThreshold }}% for 5m  | Warning    |
| HighCPUUsageCritical     | CPU > ${{ values.criticalThreshold }}% for 5m | Critical   |
| HighMemoryUsage          | Memory > ${{ values.warningThreshold }}% for 5m | Warning  |
| HighMemoryUsageCritical  | Memory > ${{ values.criticalThreshold }}% for 5m | Critical |
| DiskSpaceLow             | Disk > ${{ values.warningThreshold }}% for 10m | Warning   |
| DiskSpaceCritical        | Disk > ${{ values.criticalThreshold }}% for 5m | Critical  |
| HostDown                 | Target unreachable for 1m           | Critical   |

#### SLO-based Alerts

| Alert                    | Burn Rate | Time Window | Severity   |
| ------------------------ | --------- | ----------- | ---------- |
| SLOBurnRateCritical      | 14.4x     | 1 hour      | Critical   |
| SLOBurnRateHigh          | 6x        | 6 hours     | Warning    |
| SLOBurnRateSlow          | 1x        | 1 day       | Info       |
| SLOLatencyBudgetBurn     | N/A       | 1 hour      | Warning    |

### Adding Custom Alerts

Create new alert rule files in the `alerts/` directory:

```yaml
# alerts/custom.yaml
groups:
  - name: custom-alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
          /
          sum(rate(http_requests_total[5m])) by (service)
          > 0.05
        for: 5m
        labels:
          severity: warning
          team: ${{ values.owner }}
        annotations:
          summary: "High error rate detected"
          description: "Service {{ $labels.service }} error rate is {{ $value | humanizePercentage }}"
          runbook_url: "https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/blob/main/docs/runbooks.md#high-error-rate"
```

### Validating Alert Rules

```bash
# Validate rule syntax
promtool check rules alerts/*.yaml

# Test rule evaluation (requires running Prometheus)
promtool test rules tests/alerts_test.yaml
```

### Notification Channels

Configure notification receivers in `alertmanager.yml`:

#### Slack Integration

```yaml
receivers:
  - name: 'slack-critical'
    slack_configs:
      - api_url: '${{ values.slackWebhook }}'
        channel: '#alerts-critical'
        title: '{{ template "slack.default.title" . }}'
        text: '{{ template "slack.default.text" . }}'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
```

#### PagerDuty Integration

```yaml
receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: '${{ values.pagerdutyKey }}'
        severity: critical
        description: '{{ .CommonAnnotations.summary }}'
        details:
          firing: '{{ template "pagerduty.default.instances" .Alerts.Firing }}'
          resolved: '{{ template "pagerduty.default.instances" .Alerts.Resolved }}'
```

---

## Troubleshooting

### Prometheus Issues

**Prometheus not scraping targets**

```bash
# Check target status
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'

# Verify configuration
promtool check config prometheus.yml
```

**Resolution:**
1. Verify target is reachable: `curl http://target:port/metrics`
2. Check network policies allow Prometheus to reach targets
3. Verify service discovery configuration

---

**High memory usage in Prometheus**

```bash
# Check current memory usage
curl -s http://localhost:9090/api/v1/status/tsdb | jq '.data'

# Check cardinality
curl -s http://localhost:9090/api/v1/label/__name__/values | jq '. | length'
```

**Resolution:**
1. Reduce retention period: `--storage.tsdb.retention.time=15d`
2. Add metric relabeling to drop high-cardinality metrics
3. Increase memory limits

---

### Grafana Issues

**Dashboards not loading**

```bash
# Check Grafana logs
docker-compose logs grafana | tail -100

# Verify datasource connectivity
curl -u admin:admin http://localhost:3000/api/datasources
```

**Resolution:**
1. Verify Prometheus datasource URL is correct
2. Check provisioning directory permissions
3. Validate dashboard JSON syntax: `python3 -m json.tool dashboard.json`

---

**Dashboard variables not working**

**Resolution:**
1. Ensure variable queries use valid PromQL: `label_values(up, instance)`
2. Check variable refresh settings (On Dashboard Load)
3. Verify time range includes data for variable queries

---

### Alertmanager Issues

**Alerts not being sent**

```bash
# Check Alertmanager status
curl http://localhost:9093/api/v2/status | jq .

# List active alerts
curl http://localhost:9093/api/v2/alerts | jq .

# Check silences
curl http://localhost:9093/api/v2/silences | jq '.[] | select(.status.state == "active")'
```

**Resolution:**
1. Verify receiver configuration (webhooks, API keys)
2. Check for active silences that may be suppressing alerts
3. Review inhibition rules for conflicts
4. Validate configuration: `amtool check-config alertmanager.yml`

---

**Duplicate alerts**

**Resolution:**
1. Verify `group_by` labels are consistent
2. Check `repeat_interval` settings
3. Review inhibition rules

---

### Common Docker Compose Issues

**Services failing to start**

```bash
# Check all container statuses
docker-compose ps

# View specific service logs
docker-compose logs prometheus
docker-compose logs grafana
docker-compose logs alertmanager

# Restart specific service
docker-compose restart prometheus
```

---

**Volume permission issues**

```bash
# Fix permissions (Linux)
sudo chown -R 65534:65534 ./data/prometheus
sudo chown -R 472:472 ./data/grafana
```

---

### Pipeline Failures

**promtool validation failures**

```
Error: 1 error(s) found in rules
```

**Resolution:**
1. Check PromQL syntax in alert expressions
2. Verify label values are valid
3. Use `promtool check rules alerts/file.yaml` locally before pushing

---

**Health checks failing in CI**

```bash
# Increase sleep time before health checks
sleep 60  # Give services more time to initialize

# Check container health
docker inspect --format='{{.State.Health.Status}}' prometheus
```

---

## Directory Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── monitoring.yaml      # CI/CD pipeline
├── alerts/
│   ├── general.yaml             # Infrastructure alerts
│   ├── application.yaml         # Application-specific alerts
│   └── slo.yaml                 # SLO-based alerts
├── dashboards/
│   ├── overview.json            # System overview dashboard
│   └── slo.json                 # SLO dashboard
├── grafana/
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboards.yaml  # Dashboard provisioning config
│       └── datasources/
│           └── datasources.yaml # Datasource provisioning config
├── scripts/
│   ├── import-dashboards.sh     # Dashboard import script
│   └── validate-rules.sh        # Rule validation script
├── docs/
│   ├── index.md                 # This documentation
│   ├── alerts.md                # Alert documentation
│   ├── dashboards.md            # Dashboard documentation
│   └── runbooks.md              # Incident runbooks
├── alertmanager.yml             # Alertmanager configuration
├── prometheus.yml               # Prometheus configuration
├── docker-compose.yaml          # Local development stack
├── catalog-info.yaml            # Backstage catalog entry
└── mkdocs.yml                   # Documentation configuration
```

---

## Related Templates

| Template                                                        | Description                                    |
| --------------------------------------------------------------- | ---------------------------------------------- |
| [aws-eks](/docs/default/template/aws-eks)                       | Amazon EKS Kubernetes cluster                  |
| [gcp-gke](/docs/default/template/gcp-gke)                       | Google Kubernetes Engine cluster               |
| [azure-aks](/docs/default/template/azure-aks)                   | Azure Kubernetes Service cluster               |
| [sre-oncall](/docs/default/template/sre-oncall)                 | On-call rotation and escalation policies       |
| [sre-slo](/docs/default/template/sre-slo)                       | SLO definitions and error budget tracking      |
| [logging-stack](/docs/default/template/logging-stack)           | ELK/Loki logging infrastructure                |
| [tracing-stack](/docs/default/template/tracing-stack)           | Jaeger/Tempo distributed tracing               |

---

## References

### Official Documentation

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Node Exporter Documentation](https://prometheus.io/docs/guides/node-exporter/)

### Best Practices

- [Google SRE Workbook - Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [Prometheus Recording Rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)

### Helm Charts

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

### PromQL Resources

- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Prometheus Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [PromQL Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

### Community Resources

- [Awesome Prometheus Alerts](https://awesome-prometheus-alerts.grep.to/)
- [Grafana Dashboard Repository](https://grafana.com/grafana/dashboards/)
- [Prometheus Exporters](https://prometheus.io/docs/instrumenting/exporters/)
