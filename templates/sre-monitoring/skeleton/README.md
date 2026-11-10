# ${{ values.name }}

${{ values.description }}

## Overview

Monitoring stack for ${{ values.targetType }} targets: Prometheus with alerting rules, Alertmanager and Grafana with provisioned dashboards.

## Getting Started

```bash
docker compose up -d
```

Access:

- Grafana: [http://localhost:3000](http://localhost:3000) (admin / admin)
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Alertmanager: [http://localhost:9093](http://localhost:9093)

## Project Structure

```
├── alerts/                 # Prometheus alerting and recording rules
├── dashboards/             # Grafana dashboards (JSON)
├── grafana/provisioning/   # Grafana data source and dashboard provisioning
├── scripts/
│   ├── validate-config.sh      # promtool, amtool and Compose checks
│   ├── validate-dashboards.sh  # Dashboard JSON checks
│   ├── smoke-test.sh           # Checks a running stack
│   └── import-dashboards.sh    # Imports dashboards through the Grafana API
├── alertmanager.yml        # Alert routing and receivers
├── prometheus.yml          # Scrape configuration
├── docker-compose.yaml     # Local stack
├── docs/                   # TechDocs documentation
├── catalog-info.yaml
└── mkdocs.yml
```

## Configuration

### Adding Targets

Edit `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['host:port']
```

### Creating Alerts

Add a rules file to `alerts/` (`*.yaml`):

```yaml
groups:
  - name: example
    rules:
      - alert: HighErrorRate
        expr: error_rate > 0.05
        for: 5m
```

### Notifications

Receivers are defined in `alertmanager.yml`. Slack and PagerDuty receivers are configured when a webhook URL or integration key is given at creation time; add or change them there.

## Validation

```bash
bash scripts/validate-config.sh      # Compose file, Prometheus config and rules, Alertmanager config
bash scripts/validate-dashboards.sh  # Dashboard JSON
docker compose up -d && bash scripts/smoke-test.sh
```

## Continuous Integration

The `Monitoring CI` workflow runs on every push and pull request:

| Job | What it does |
| --- | --- |
| Security Scan | Scans the repository for misconfigurations and committed secrets |
| Validate Configuration | Runs `scripts/validate-config.sh` |
| Lint Grafana Dashboards | Runs `scripts/validate-dashboards.sh` |
| Test Monitoring Stack | Starts the stack, runs `scripts/smoke-test.sh` and imports the dashboards through the Grafana API |
| Build Documentation | Builds the TechDocs documentation with `mkdocs build --strict` |
| Deploy Dashboards | Imports the dashboards into your Grafana from `main` |

## Deployment

The deploy job imports `dashboards/` into a Grafana instance. It is skipped until both repository secrets are set under **Settings > Secrets and variables > Actions**:

| Secret | Description |
| --- | --- |
| `GRAFANA_URL` | Base URL of the Grafana instance |
| `GRAFANA_API_KEY` | Grafana service account token allowed to edit dashboards |

Prometheus loads the rule files in `alerts/` from its rules directory, as `docker-compose.yaml` shows; see the documentation for Kubernetes options.

## Owner

${{ values.owner }}
