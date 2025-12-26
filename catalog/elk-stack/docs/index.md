# ELK Stack

Centralized logging and observability platform using Elasticsearch, Logstash, and Kibana for log aggregation, search, analysis, and visualization.

## Quick Start

```bash
# Pull ELK images
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.12.0
docker pull docker.elastic.co/logstash/logstash:8.12.0
docker pull docker.elastic.co/kibana/kibana:8.12.0

# Run Elasticsearch (single node)
docker run -d --name elasticsearch \
  -p 9200:9200 -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  -e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0

# Run Kibana
docker run -d --name kibana \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  --link elasticsearch \
  docker.elastic.co/kibana/kibana:8.12.0

# Access Kibana
open http://localhost:5601

# Test Elasticsearch
curl -X GET "localhost:9200/_cluster/health?pretty"

# Index a document
curl -X POST "localhost:9200/logs/_doc" \
  -H "Content-Type: application/json" \
  -d '{"timestamp": "2024-01-15T10:30:00Z", "level": "INFO", "message": "Application started"}'

# Search logs
curl -X GET "localhost:9200/logs/_search?q=level:INFO&pretty"
```

## Features

| Feature              | Component            | Description                  | Use Case                 |
| -------------------- | -------------------- | ---------------------------- | ------------------------ |
| **Full-Text Search** | Elasticsearch        | Inverted index search engine | Log searching, analytics |
| **Log Ingestion**    | Logstash             | Data pipeline with filters   | Parse, transform, enrich |
| **Visualization**    | Kibana               | Dashboards and analytics     | Monitoring, reporting    |
| **Beats Agents**     | Filebeat, Metricbeat | Lightweight data shippers    | Edge collection          |
| **Machine Learning** | Elasticsearch ML     | Anomaly detection            | Proactive alerting       |
| **Alerting**         | Kibana Alerting      | Rule-based notifications     | Incident response        |
| **Security**         | X-Pack Security      | RBAC, encryption, audit      | Compliance               |
| **APM**              | Elastic APM          | Application performance      | Tracing, profiling       |
| **SIEM**             | Elastic Security     | Security analytics           | Threat detection         |

## Architecture

```d2
direction: down

title: ELK Stack Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

sources: Data Sources {
  shape: rectangle
  style.fill: "#E3F2FD"

  apps: App Logs {
    shape: document
    style.fill: "#BBDEFB"
  }
  metrics: Metrics {
    shape: document
    style.fill: "#BBDEFB"
  }
  syslogs: Syslogs {
    shape: document
    style.fill: "#BBDEFB"
  }
  events: Events {
    shape: document
    style.fill: "#BBDEFB"
  }
}

beats: Beats Agents {
  shape: rectangle
  style.fill: "#FFF3E0"

  filebeat: Filebeat {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
  metricbeat: Metricbeat {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
  packetbeat: Packetbeat {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
  heartbeat: Heartbeat {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }
}

logstash: Logstash {
  shape: rectangle
  style.fill: "#C8E6C9"

  input: Input {
    shape: rectangle
    style.fill: "#4CAF50"
    style.font-color: white
  }
  filter: Filter {
    shape: rectangle
    style.fill: "#4CAF50"
    style.font-color: white
    label: "Parse, Transform, Enrich"
  }
  output: Output {
    shape: rectangle
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

elasticsearch: Elasticsearch Cluster {
  shape: rectangle
  style.fill: "#FFCDD2"

  node1: Node 1 (Master) {
    shape: cylinder
    style.fill: "#F44336"
    style.font-color: white
  }
  node2: Node 2 (Data) {
    shape: cylinder
    style.fill: "#F44336"
    style.font-color: white
  }
  node3: Node 3 (Data) {
    shape: cylinder
    style.fill: "#F44336"
    style.font-color: white
  }

  shards: Primary + Replica Shards
}

kibana: Kibana {
  shape: rectangle
  style.fill: "#E1BEE7"

  discover: Discover
  dashboard: Dashboard
  visualize: Visualize
  devtools: Dev Tools
  alerts: Alerts
}

users: Users / API {
  shape: person
  style.fill: "#E3F2FD"
}

sources -> beats: collect
beats -> logstash: ship
logstash.input -> logstash.filter -> logstash.output
logstash.output -> elasticsearch: index
elasticsearch -> kibana: query
kibana -> users: visualize
```

## Component Overview

| Component     | Port                          | Purpose                            |
| ------------- | ----------------------------- | ---------------------------------- |
| Elasticsearch | 9200 (HTTP), 9300 (Transport) | Search and analytics engine        |
| Logstash      | 5044 (Beats), 9600 (API)      | Data processing pipeline           |
| Kibana        | 5601                          | Visualization and management       |
| Filebeat      | -                             | Log file shipping                  |
| Metricbeat    | -                             | Metrics collection                 |
| APM Server    | 8200                          | Application performance monitoring |

## Version Information

| Component     | Version | Release Date |
| ------------- | ------- | ------------ |
| Elasticsearch | 8.12.0  | 2024         |
| Logstash      | 8.12.0  | 2024         |
| Kibana        | 8.12.0  | 2024         |
| Filebeat      | 8.12.0  | 2024         |
| Metricbeat    | 8.12.0  | 2024         |
| APM Server    | 8.12.0  | 2024         |

## Data Flow Patterns

```
Pattern 1: Direct to Elasticsearch
App ──► Filebeat ──► Elasticsearch ──► Kibana

Pattern 2: With Logstash Processing
App ──► Filebeat ──► Logstash ──► Elasticsearch ──► Kibana

Pattern 3: Multi-Tier
App ──► Filebeat ──► Kafka ──► Logstash ──► Elasticsearch ──► Kibana

Pattern 4: APM Tracing
App + APM Agent ──► APM Server ──► Elasticsearch ──► Kibana APM
```

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, security, and monitoring
- [Usage](usage.md) - Deployment examples, queries, and troubleshooting
