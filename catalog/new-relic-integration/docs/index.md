# New Relic Monitoring

Full-stack observability platform providing APM, infrastructure monitoring, log management, browser monitoring, and AIOps capabilities with unified telemetry data.

## Quick Start

```bash
# Install New Relic Infrastructure Agent (Linux)
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
sudo NEW_RELIC_API_KEY=<API_KEY> NEW_RELIC_ACCOUNT_ID=<ACCOUNT_ID> /usr/local/bin/newrelic install

# Docker Agent
docker run -d --name newrelic-infra \
  -e NRIA_LICENSE_KEY=<LICENSE_KEY> \
  -v /:/host:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --privileged \
  --pid=host \
  --network=host \
  newrelic/infrastructure:latest

# Python APM
pip install newrelic
newrelic-admin generate-config <LICENSE_KEY> newrelic.ini
NEW_RELIC_CONFIG_FILE=newrelic.ini newrelic-admin run-program python app.py

# Send custom event via API
curl -X POST "https://insights-collector.newrelic.com/v1/accounts/<ACCOUNT_ID>/events" \
  -H "Content-Type: application/json" \
  -H "Api-Key: <INSERT_KEY>" \
  -d '[{"eventType": "CustomEvent", "attribute1": "value1"}]'
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **APM** | Application performance monitoring | Code-level visibility |
| **Infrastructure** | Host, container, cloud monitoring | Capacity planning |
| **Logs** | Log management and analytics | Centralized logging |
| **Browser** | Real user monitoring (RUM) | Frontend performance |
| **Mobile** | iOS/Android monitoring | Mobile app performance |
| **Synthetics** | Proactive monitoring | Uptime, API testing |
| **Serverless** | Lambda, Functions monitoring | Serverless debugging |
| **NRQL** | Query language for telemetry | Custom analytics |
| **Alerts** | AI-powered alerting | Incident detection |
| **Dashboards** | Custom visualizations | Business metrics |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   New Relic Architecture                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Your Infrastructure                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │    │
│  │  │   APM   │  │  Infra  │  │  Logs   │  │ Browser │     │    │
│  │  │  Agent  │  │  Agent  │  │Forwarder│  │  Agent  │     │    │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘     │    │
│  │       │            │            │            │          │    │
│  └───────┴────────────┴────────────┴────────────┴──────────┘    │
│                             │                                   │
│                             ▼ HTTPS                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  New Relic Platform                     │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │              Telemetry Data Platform            │    │    │
│  │  │  (NRDB - New Relic Database)                    │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  │                          │                              │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │    │
│  │  │   APM   │ │ Infra   │ │  Logs   │ │ Alerts  │        │    │
│  │  │   UI    │ │   UI    │ │   UI    │ │   UI    │        │    │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │    │
│  │  │Dashboard│ │ Service │ │Workloads│ │ Errors  │        │    │
│  │  │ Builder │ │  Maps   │ │         │ │  Inbox  │        │    │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Data Types

| Type | Description | Retention |
|------|-------------|-----------|
| Metrics | Time-series numerical data | 13 months |
| Events | Discrete occurrences | 8 days (extendable) |
| Logs | Log messages | 30 days (configurable) |
| Traces | Distributed traces | 8 days |
| Spans | Individual trace segments | 8 days |

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Infrastructure Agent | 1.49+ | Current |
| APM Agents | Language-specific | Various |
| Browser Agent | 1.x | Loader script |
| OpenTelemetry | 1.x | Native support |

## API Endpoints

| Region | Endpoint |
|--------|----------|
| US | api.newrelic.com |
| EU | api.eu.newrelic.com |
| Metrics | metric-api.newrelic.com |
| Events | insights-collector.newrelic.com |
| Logs | log-api.newrelic.com |
| Traces | trace-api.newrelic.com |

## Related Documentation

- [Overview](overview.md) - Configuration, NRQL, and integrations
- [Usage](usage.md) - Deployment examples and troubleshooting
