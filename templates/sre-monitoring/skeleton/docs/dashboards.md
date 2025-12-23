# Grafana Dashboards

This document describes the Grafana dashboards included in this monitoring stack.

## Available Dashboards

### System Overview Dashboard

**File**: `dashboards/overview.json`

Provides a high-level view of system health:

- **Service Status**: Up/down status of all monitored services
- **Request Rate**: Requests per second across all services
- **Error Rate**: Percentage of failed requests
- **Latency**: P50, P95, P99 response times
- **Resource Usage**: CPU, memory, disk utilization

### Application Metrics Dashboard

**File**: `dashboards/application.json`

Detailed application performance metrics:

- **Request Volume**: Breakdown by endpoint and method
- **Response Codes**: Distribution of HTTP status codes
- **Latency Histogram**: Response time distribution
- **Active Connections**: Current connection count
- **Queue Depth**: Background job queue sizes

### SLO Dashboard

**File**: `dashboards/slo.json`

Service Level Objective tracking:

- **Error Budget**: Remaining error budget for the period
- **Burn Rate**: Current error budget consumption rate
- **SLI Trends**: Historical SLI performance
- **Availability**: Rolling availability percentage

## Dashboard Variables

All dashboards support the following template variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `$environment` | Filter by environment | `production` |
| `$service` | Filter by service name | `All` |
| `$interval` | Aggregation interval | `1m` |

## Importing Dashboards

### Via Grafana UI

1. Navigate to Dashboards > Import
2. Upload the JSON file or paste contents
3. Select the Prometheus data source
4. Click Import

### Via API

```bash
./scripts/import-dashboards.sh
```

### Via Kubernetes ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  labels:
    grafana_dashboard: "1"
data:
  overview.json: |
    <dashboard json content>
```

## Customizing Dashboards

1. Edit the dashboard in Grafana UI
2. Export as JSON (Share > Export > Save to file)
3. Replace the file in `dashboards/`
4. Commit and push changes

## Dashboard Best Practices

1. **Use template variables** for filtering and drill-down
2. **Set appropriate time ranges** for each panel
3. **Include documentation links** in panel descriptions
4. **Use consistent color schemes** across dashboards
5. **Add threshold lines** for SLO targets
