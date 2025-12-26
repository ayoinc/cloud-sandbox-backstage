# Prometheus Monitoring Stack

A complete observability stack featuring Prometheus for metrics collection, Grafana for visualization, and Alertmanager for alerting and notifications.

## Quick Start

```bash
# Run Prometheus with Docker
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v ./prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.48.0

# Run Grafana
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:10.2.0

# Run Alertmanager
docker run -d \
  --name alertmanager \
  -p 9093:9093 \
  -v ./alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  prom/alertmanager:v0.26.0
```

## Stack Components

| Component             | Purpose                         | Port |
| --------------------- | ------------------------------- | ---- |
| **Prometheus**        | Metrics collection and storage  | 9090 |
| **Grafana**           | Dashboards and visualization    | 3000 |
| **Alertmanager**      | Alert routing and notifications | 9093 |
| **Node Exporter**     | Host metrics                    | 9100 |
| **Blackbox Exporter** | Probe monitoring                | 9115 |
| **Pushgateway**       | Batch job metrics               | 9091 |

## Features

- **Pull-based Metrics**: Prometheus scrapes targets at configured intervals
- **PromQL**: Powerful query language for metrics analysis
- **Service Discovery**: Auto-discover targets in Kubernetes, AWS, etc.
- **Alerting**: Multi-channel alerting with silencing and inhibition
- **Long-term Storage**: Integration with Thanos, Cortex, or Mimir

## Architecture Overview

```d2
direction: down

monitoring-stack: Monitoring Stack {
  grafana: Grafana {
    shape: rectangle
    label: "Grafana\n(Visualization)"
  }

  prometheus: Prometheus {
    shape: rectangle
    label: "Prometheus\n(Metrics Storage & Query)"
  }

  exporters: Exporters {
    node: Node Exporter
    app: App Metrics
    blackbox: Blackbox Exporter
  }

  grafana -> prometheus: Query
  prometheus -> exporters.node: Scrape
  prometheus -> exporters.app: Scrape
  prometheus -> exporters.blackbox: Scrape
}

alertmanager: Alertmanager {
  shape: rectangle
  label: "Alertmanager\n(Alert Routing)"
}

notifications: Notification Channels {
  slack: Slack
  email: Email
  pagerduty: PagerDuty
}

monitoring-stack.prometheus -> alertmanager: Alerts
alertmanager -> notifications.slack
alertmanager -> notifications.email
alertmanager -> notifications.pagerduty
```

## Related Documentation

- [Overview](overview.md) - Architecture, PromQL, and configuration
- [Usage](usage.md) - Practical examples and alerting rules
