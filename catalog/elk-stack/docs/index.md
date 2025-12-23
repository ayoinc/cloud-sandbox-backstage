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

| Feature | Component | Description | Use Case |
|---------|-----------|-------------|----------|
| **Full-Text Search** | Elasticsearch | Inverted index search engine | Log searching, analytics |
| **Log Ingestion** | Logstash | Data pipeline with filters | Parse, transform, enrich |
| **Visualization** | Kibana | Dashboards and analytics | Monitoring, reporting |
| **Beats Agents** | Filebeat, Metricbeat | Lightweight data shippers | Edge collection |
| **Machine Learning** | Elasticsearch ML | Anomaly detection | Proactive alerting |
| **Alerting** | Kibana Alerting | Rule-based notifications | Incident response |
| **Security** | X-Pack Security | RBAC, encryption, audit | Compliance |
| **APM** | Elastic APM | Application performance | Tracing, profiling |
| **SIEM** | Elastic Security | Security analytics | Threat detection |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ELK Stack Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Data Sources                                                  │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐              │
│   │ App Logs│ │ Metrics │ │ Syslogs │ │ Events  │              │
│   └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘              │
│        │           │           │           │                    │
│        ▼           ▼           ▼           ▼                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                     Beats Agents                        │   │
│   │  Filebeat   Metricbeat   Packetbeat   Heartbeat         │   │
│   └────────────────────────┬────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                      Logstash                           │   │
│   │  ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│   │  │  Input  │───►│ Filter  │───►│ Output  │              │   │
│   │  └─────────┘    └─────────┘    └─────────┘              │   │
│   └────────────────────────┬────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              Elasticsearch Cluster                      │   │
│   │  ┌─────────┐  ┌─────────┐  ┌─────────┐                  │   │
│   │  │ Node 1  │  │ Node 2  │  │ Node 3  │                  │   │
│   │  │ Master  │  │  Data   │  │  Data   │                  │   │
│   │  └─────────┘  └─────────┘  └─────────┘                  │   │
│   │         Primary + Replica Shards                        │   │
│   └────────────────────────┬────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                       Kibana                            │   │
│   │  Discover │ Dashboard │ Visualize │ Dev Tools │ Alerts  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│                      Users / API                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Overview

| Component | Port | Purpose |
|-----------|------|---------|
| Elasticsearch | 9200 (HTTP), 9300 (Transport) | Search and analytics engine |
| Logstash | 5044 (Beats), 9600 (API) | Data processing pipeline |
| Kibana | 5601 | Visualization and management |
| Filebeat | - | Log file shipping |
| Metricbeat | - | Metrics collection |
| APM Server | 8200 | Application performance monitoring |

## Version Information

| Component | Version | Release Date |
|-----------|---------|--------------|
| Elasticsearch | 8.12.0 | 2024 |
| Logstash | 8.12.0 | 2024 |
| Kibana | 8.12.0 | 2024 |
| Filebeat | 8.12.0 | 2024 |
| Metricbeat | 8.12.0 | 2024 |
| APM Server | 8.12.0 | 2024 |

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
