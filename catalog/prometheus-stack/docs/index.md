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

| Component | Purpose | Port |
|-----------|---------|------|
| **Prometheus** | Metrics collection and storage | 9090 |
| **Grafana** | Dashboards and visualization | 3000 |
| **Alertmanager** | Alert routing and notifications | 9093 |
| **Node Exporter** | Host metrics | 9100 |
| **Blackbox Exporter** | Probe monitoring | 9115 |
| **Pushgateway** | Batch job metrics | 9091 |

## Features

- **Pull-based Metrics**: Prometheus scrapes targets at configured intervals
- **PromQL**: Powerful query language for metrics analysis
- **Service Discovery**: Auto-discover targets in Kubernetes, AWS, etc.
- **Alerting**: Multi-channel alerting with silencing and inhibition
- **Long-term Storage**: Integration with Thanos, Cortex, or Mimir

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Monitoring Stack                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     Grafana                          │   │
│  │                  (Visualization)                     │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │                    Prometheus                        │   │
│  │            (Metrics Storage & Query)                 │   │
│  └──────┬────────────────┬────────────────┬────────────┘   │
│         │                │                │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐        │
│  │   Scrape    │  │   Scrape    │  │   Scrape    │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐        │
│  │    Node     │  │  App        │  │  Blackbox   │        │
│  │  Exporter   │  │  Metrics    │  │  Exporter   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │    Alertmanager     │
              │  (Alert Routing)    │
              └──────────┬──────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐    ┌─────▼────┐   ┌──────▼─────┐
    │  Slack  │    │  Email   │   │ PagerDuty  │
    └─────────┘    └──────────┘   └────────────┘
```

## Related Documentation

- [Overview](overview.md) - Architecture, PromQL, and configuration
- [Usage](usage.md) - Practical examples and alerting rules
