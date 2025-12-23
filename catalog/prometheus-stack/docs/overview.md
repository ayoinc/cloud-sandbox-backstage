# Overview

## Architecture

Prometheus uses a pull-based architecture where it periodically scrapes metrics from configured targets. Data is stored in a time-series database optimized for high cardinality.

### Data Model

```
# Metric format
<metric_name>{<label_name>=<label_value>, ...} <value> [<timestamp>]

# Example
http_requests_total{method="GET", endpoint="/api/users", status="200"} 1234 1699000000
```

### Metric Types

| Type | Description | Example |
|------|-------------|---------|
| **Counter** | Monotonically increasing | `http_requests_total` |
| **Gauge** | Can go up or down | `temperature_celsius` |
| **Histogram** | Bucketed observations | `http_request_duration_seconds` |
| **Summary** | Quantiles over sliding window | `http_request_duration_summary` |

## Components

### Prometheus Server

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "/etc/prometheus/rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

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
```

### Alertmanager

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/xxx'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-notifications'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
    - match:
        severity: warning
      receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
        title: '{{ .Status | toUpper }}: {{ .CommonLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'your-pagerduty-key'
        severity: critical

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

### Grafana

```yaml
# datasources.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Alertmanager
    type: alertmanager
    access: proxy
    url: http://alertmanager:9093
    jsonData:
      implementation: prometheus
```

## PromQL Reference

### Basic Queries

```promql
# Instant vector
http_requests_total

# Range vector (last 5 minutes)
http_requests_total[5m]

# Label matching
http_requests_total{job="api", status="200"}

# Regex matching
http_requests_total{status=~"2.."}

# Negative matching
http_requests_total{status!="500"}
```

### Aggregations

```promql
# Sum by label
sum by (job) (http_requests_total)

# Average
avg(node_cpu_seconds_total)

# Count
count(up == 1)

# Top 5
topk(5, http_requests_total)

# Quantile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Functions

```promql
# Rate (per-second increase)
rate(http_requests_total[5m])

# Increase (total increase)
increase(http_requests_total[1h])

# Delta (for gauges)
delta(temperature_celsius[1h])

# Predict linear
predict_linear(node_filesystem_free_bytes[1h], 4*3600)

# Absent (for alert on missing metric)
absent(up{job="important-service"})
```

### Common Patterns

```promql
# Request rate
sum(rate(http_requests_total[5m])) by (service)

# Error rate percentage
100 * sum(rate(http_requests_total{status=~"5.."}[5m])) 
    / sum(rate(http_requests_total[5m]))

# Latency percentiles
histogram_quantile(0.99, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)

# Saturation (CPU)
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)

# Memory usage percentage
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

## Configuration

### Environment Variables

```bash
# Prometheus
PROMETHEUS_STORAGE_TSDB_PATH=/prometheus
PROMETHEUS_STORAGE_TSDB_RETENTION_TIME=15d
PROMETHEUS_WEB_ENABLE_LIFECYCLE=true

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=secure_password
GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-clock-panel
GF_AUTH_ANONYMOUS_ENABLED=false
```

### Storage Configuration

```yaml
# prometheus.yml
storage:
  tsdb:
    path: /prometheus
    retention.time: 15d
    retention.size: 50GB
    wal-compression: true
```

### High Availability

```yaml
# For HA, run multiple Prometheus instances with same config
# Use Thanos or Cortex for long-term storage and global view

# Thanos sidecar configuration
thanos:
  sidecar:
    prometheus:
      url: http://localhost:9090
    grpc:
      port: 10901
    http:
      port: 10902
    objstore:
      type: S3
      config:
        bucket: thanos-metrics
        endpoint: s3.amazonaws.com
```

## Monitoring Best Practices

### The Four Golden Signals

| Signal | Description | Example Metric |
|--------|-------------|----------------|
| **Latency** | Time to serve requests | `http_request_duration_seconds` |
| **Traffic** | Request rate | `http_requests_total` |
| **Errors** | Error rate | `http_requests_total{status=~"5.."}` |
| **Saturation** | Resource utilization | `node_cpu_seconds_total` |

### USE Method (for resources)

| Metric | Description |
|--------|-------------|
| **Utilization** | % time resource was busy |
| **Saturation** | Work queued |
| **Errors** | Error events |

### RED Method (for services)

| Metric | Description |
|--------|-------------|
| **Rate** | Requests per second |
| **Errors** | Failed requests per second |
| **Duration** | Request latency |
