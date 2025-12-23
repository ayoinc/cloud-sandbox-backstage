# ${{ values.name }}

${{ values.description }}

## Overview

This monitoring stack provides comprehensive observability for **${{ values.targetType }}** infrastructure using Prometheus for metrics collection and alerting, and Grafana for visualization.

## Components

| Component | URL | Purpose |
|-----------|-----|---------|
| Prometheus | ${{ values.prometheusUrl }} | Metrics collection and alerting |
| Grafana | ${{ values.grafanaUrl }} | Dashboards and visualization |
| Alertmanager | ${{ values.alertmanagerUrl }} | Alert routing and notifications |

## Quick Start

### Local Development

Start the monitoring stack locally using Docker Compose:

```bash
docker-compose up -d
```

Access the services:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)
- Alertmanager: http://localhost:9093

### Deploying Alert Rules

Apply Prometheus alerting rules:

```bash
# Validate rules
promtool check rules alerts/*.yaml

# Apply to Prometheus (if using Prometheus Operator)
kubectl apply -f alerts/
```

### Importing Dashboards

Import Grafana dashboards:

```bash
# Using Grafana API
./scripts/import-dashboards.sh
```

## Directory Structure

```
.
├── alerts/                 # Prometheus alerting rules
│   ├── general.yaml       # General infrastructure alerts
│   ├── application.yaml   # Application-specific alerts
│   └── slo.yaml          # SLO-based alerts
├── dashboards/            # Grafana dashboard JSON files
│   ├── overview.json     # System overview dashboard
│   ├── application.json  # Application metrics dashboard
│   └── slo.json         # SLO dashboard
├── scripts/              # Utility scripts
│   └── import-dashboards.sh
└── docker-compose.yaml   # Local development stack
```

## Alert Thresholds

| Severity | Threshold | Response Time |
|----------|-----------|---------------|
| Critical | ${{ values.criticalThreshold }}% | Immediate |
| Warning | ${{ values.warningThreshold }}% | Within 1 hour |
| Info | N/A | Next business day |

## Notification Channels

Alerts are routed to the following channels:

- **Slack**: Real-time notifications for all alert severities
- **PagerDuty**: Critical alerts for on-call escalation
- **Email**: Daily summary reports

## Related Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
