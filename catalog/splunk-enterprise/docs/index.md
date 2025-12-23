# Splunk Enterprise

Industry-leading platform for machine data analytics, log management, security information and event management (SIEM), IT operations, and business intelligence.

## Quick Start

```bash
# Run Splunk Enterprise in Docker
docker run -d --name splunk \
  -p 8000:8000 \
  -p 8088:8088 \
  -p 8089:8089 \
  -p 9997:9997 \
  -e SPLUNK_START_ARGS="--accept-license" \
  -e SPLUNK_PASSWORD="changeme123" \
  splunk/splunk:latest

# Access Splunk Web
open http://localhost:8000
# Login: admin / changeme123

# Install Universal Forwarder (Linux)
wget -O splunkforwarder.tgz "https://download.splunk.com/products/universalforwarder/releases/9.2.0/linux/splunkforwarder-9.2.0-linux-x86_64.tgz"
tar -xzf splunkforwarder.tgz -C /opt
/opt/splunkforwarder/bin/splunk start --accept-license

# Add forward server
/opt/splunkforwarder/bin/splunk add forward-server splunk-indexer:9997

# Monitor log file
/opt/splunkforwarder/bin/splunk add monitor /var/log/syslog

# Send data via HTTP Event Collector (HEC)
curl -k https://localhost:8088/services/collector/event \
  -H "Authorization: Splunk <HEC_TOKEN>" \
  -d '{"event": "Hello, Splunk!", "sourcetype": "manual"}'
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Search & Investigation** | SPL query language | Log analysis, troubleshooting |
| **Dashboards & Reports** | Visualizations and alerts | Monitoring, reporting |
| **SIEM** | Security monitoring | Threat detection |
| **SOAR** | Security orchestration | Incident response |
| **IT Service Intelligence** | ITSI | Service health monitoring |
| **Observability** | APM, infrastructure | Full-stack visibility |
| **Machine Learning** | MLTK | Anomaly detection |
| **Data Streams** | Real-time processing | Streaming analytics |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Splunk Architecture                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Data Sources                                                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │  Logs   │ │ Metrics │ │ Events  │ │  APIs   │               │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘               │
│       │           │           │           │                     │
│       ▼           ▼           ▼           ▼                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │               Data Collection Tier                      │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐  │    │
│  │  │  Universal    │  │  Heavy        │  │    HEC      │  │    │
│  │  │  Forwarder    │  │  Forwarder    │  │  Endpoint   │  │    │
│  │  └───────────────┘  └───────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                             │                                   │
│                             ▼ Port 9997                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Indexing Tier                        │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐            │    │
│  │  │ Indexer 1 │  │ Indexer 2 │  │ Indexer 3 │            │    │
│  │  └───────────┘  └───────────┘  └───────────┘            │    │
│  │                 Clustered Indexers                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Search Tier                          │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────────────┐    │    │
│  │  │Search Head│  │Search Head│  │ Search Head       │    │    │
│  │  │    1      │  │    2      │  │ Cluster Captain   │    │    │
│  │  └───────────┘  └───────────┘  └───────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                             │                                   │
│                             ▼ Port 8000                         │
│                      Users / API                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Types

| Component | Purpose | Typical Port |
|-----------|---------|--------------|
| Search Head | Search, dashboards, alerts | 8000 (Web), 8089 (API) |
| Indexer | Data storage and retrieval | 9997 (Receiving), 8089 |
| Universal Forwarder | Lightweight log shipping | 8089 (Management) |
| Heavy Forwarder | Parsing, filtering | 9997, 8089 |
| Cluster Manager | Indexer cluster management | 8089 |
| Deployment Server | Forwarder management | 8089 |
| License Manager | License management | 8089 |

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Splunk Enterprise | 9.2.x | Current |
| Universal Forwarder | 9.2.x | Matches Enterprise |
| Splunk Cloud | Latest | SaaS offering |

## Index Types

| Type | Description | Use Case |
|------|-------------|----------|
| Events | Timestamped log data | Logs, events |
| Metrics | Numeric time-series | Performance data |
| Summary | Pre-aggregated data | Accelerated reports |

## Related Documentation

- [Overview](overview.md) - Configuration, SPL, and clustering
- [Usage](usage.md) - Deployment examples and troubleshooting
