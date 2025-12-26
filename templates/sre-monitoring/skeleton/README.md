# ${{ values.name }}

${{ values.description }}

## Overview

SRE monitoring stack with Prometheus, Grafana, and alerting.

## Getting Started

```bash
docker-compose up -d
```

Access:
- Grafana: [http://localhost:3000](http://localhost:3000)
- Prometheus: [http://localhost:9090](http://localhost:9090)
- Alertmanager: [http://localhost:9093](http://localhost:9093)

## Project Structure

```
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── alerts/
├── grafana/
│   ├── dashboards/
│   └── provisioning/
└── alertmanager/
    └── alertmanager.yml
```

## Configuration

### Adding Targets

Edit `prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['host:port']
```

### Creating Alerts

Add rules to `prometheus/alerts/`:

```yaml
groups:
  - name: example
    rules:
      - alert: HighErrorRate
        expr: error_rate > 0.05
        for: 5m
```

## License

MIT

## Author

${{ values.owner }}
