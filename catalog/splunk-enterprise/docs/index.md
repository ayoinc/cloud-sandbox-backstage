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

| Feature                     | Description               | Use Case                      |
| --------------------------- | ------------------------- | ----------------------------- |
| **Search & Investigation**  | SPL query language        | Log analysis, troubleshooting |
| **Dashboards & Reports**    | Visualizations and alerts | Monitoring, reporting         |
| **SIEM**                    | Security monitoring       | Threat detection              |
| **SOAR**                    | Security orchestration    | Incident response             |
| **IT Service Intelligence** | ITSI                      | Service health monitoring     |
| **Observability**           | APM, infrastructure       | Full-stack visibility         |
| **Machine Learning**        | MLTK                      | Anomaly detection             |
| **Data Streams**            | Real-time processing      | Streaming analytics           |

## Architecture

```d2
direction: down

title: Splunk Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

sources: Data Sources {
  style.fill: "#E3F2FD"

  logs: Logs {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }

  metrics: Metrics {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }

  events: Events {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }

  apis: APIs {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }
}

collection: Data Collection Tier {
  style.fill: "#E8F5E9"

  uf: Universal\nForwarder {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  hf: Heavy\nForwarder {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  hec: HEC\nEndpoint {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

indexing: Indexing Tier {
  style.fill: "#FFF3E0"

  idx1: Indexer 1 {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }

  idx2: Indexer 2 {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }

  idx3: Indexer 3 {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }

  cluster_label: Clustered Indexers {
    shape: text
    style.font-size: 12
  }
}

search: Search Tier {
  style.fill: "#FCE4EC"

  sh1: Search Head\n1 {
    shape: hexagon
    style.fill: "#E91E63"
    style.font-color: white
  }

  sh2: Search Head\n2 {
    shape: hexagon
    style.fill: "#E91E63"
    style.font-color: white
  }

  captain: Search Head\nCluster Captain {
    shape: hexagon
    style.fill: "#AD1457"
    style.font-color: white
  }
}

users: Users / API (Port 8000) {
  shape: rectangle
  style.fill: "#9C27B0"
  style.font-color: white
}

sources -> collection: Collect
collection -> indexing: Port 9997
indexing -> search: Query
search -> users: Results
```

## Component Types

| Component           | Purpose                    | Typical Port           |
| ------------------- | -------------------------- | ---------------------- |
| Search Head         | Search, dashboards, alerts | 8000 (Web), 8089 (API) |
| Indexer             | Data storage and retrieval | 9997 (Receiving), 8089 |
| Universal Forwarder | Lightweight log shipping   | 8089 (Management)      |
| Heavy Forwarder     | Parsing, filtering         | 9997, 8089             |
| Cluster Manager     | Indexer cluster management | 8089                   |
| Deployment Server   | Forwarder management       | 8089                   |
| License Manager     | License management         | 8089                   |

## Version Information

| Component           | Version | Notes              |
| ------------------- | ------- | ------------------ |
| Splunk Enterprise   | 9.2.x   | Current            |
| Universal Forwarder | 9.2.x   | Matches Enterprise |
| Splunk Cloud        | Latest  | SaaS offering      |

## Index Types

| Type    | Description          | Use Case            |
| ------- | -------------------- | ------------------- |
| Events  | Timestamped log data | Logs, events        |
| Metrics | Numeric time-series  | Performance data    |
| Summary | Pre-aggregated data  | Accelerated reports |

## Related Documentation

- [Overview](overview.md) - Configuration, SPL, and clustering
- [Usage](usage.md) - Deployment examples and troubleshooting
