# Elasticsearch Data Cluster

Distributed search and analytics engine for log analytics, full-text search, security intelligence, and observability at scale.

## Quick Start

### Start Elasticsearch with Docker

```bash
# Create network
docker network create elastic

# Start single-node cluster (development)
docker run -d --name elasticsearch --network elastic \
  -p 9200:9200 -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=true" \
  -e "ELASTIC_PASSWORD=changeme" \
  -e "xpack.security.http.ssl.enabled=false" \
  -v es-data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0

# Verify cluster health
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty
```

### Multi-Node Cluster with Docker Compose

```bash
# Start 3-node cluster
docker-compose up -d

# Check cluster status
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v
```

## Features

| Feature | Description |
|---------|-------------|
| **Full-Text Search** | Inverted index with BM25 scoring, analyzers, and tokenizers |
| **Distributed Architecture** | Automatic sharding and replication across nodes |
| **Near Real-Time** | Documents searchable within ~1 second of indexing |
| **Aggregations** | Bucket, metric, and pipeline aggregations for analytics |
| **Machine Learning** | Anomaly detection, forecasting, and NLP (with subscription) |
| **Vector Search** | kNN search for embeddings and similarity matching |
| **Data Streams** | Append-only time-series data with automatic rollover |
| **Index Lifecycle Management** | Automated hot-warm-cold-delete data tiering |

## Architecture

```d2
direction: down

title: Elasticsearch Cluster Architecture {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

cluster: Elasticsearch Cluster {
  style.fill: "#e8f4f8"
  style.stroke: "#1a73e8"
  style.stroke-width: 2

  nodes: Cluster Nodes {
    style.fill: "#ffffff"
    
    node1: Node 1 {
      style.fill: "#4285f4"
      style.font-color: "#ffffff"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg
      
      roles: "Master-eligible\nData Node" {
        style.fill: "#e3f2fd"
        style.font-size: 12
      }
      
      shards: Shards {
        style.fill: "#bbdefb"
        p0: "Primary 0" {style.fill: "#2196f3"; style.font-color: white}
        r1: "Replica 1" {style.fill: "#90caf9"}
        r2: "Replica 2" {style.fill: "#90caf9"}
      }
    }
    
    node2: Node 2 {
      style.fill: "#34a853"
      style.font-color: "#ffffff"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg
      
      roles: "Master-eligible\nData Node" {
        style.fill: "#e8f5e9"
        style.font-size: 12
      }
      
      shards: Shards {
        style.fill: "#c8e6c9"
        p1: "Primary 1" {style.fill: "#4caf50"; style.font-color: white}
        r2: "Replica 2" {style.fill: "#a5d6a7"}
        r0: "Replica 0" {style.fill: "#a5d6a7"}
      }
    }
    
    node3: Node 3 {
      style.fill: "#fbbc04"
      style.font-color: "#000000"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg
      
      roles: "Master-eligible\nData Node" {
        style.fill: "#fff8e1"
        style.font-size: 12
      }
      
      shards: Shards {
        style.fill: "#ffecb3"
        p2: "Primary 2" {style.fill: "#ffc107"; style.font-color: black}
        r0: "Replica 0" {style.fill: "#ffe082"}
        r1: "Replica 1" {style.fill: "#ffe082"}
      }
    }
  }
  
  index: "Index: logs-2024.01\n5 Primary + 1 Replica each\n= 10 total shards" {
    style.fill: "#f3e5f5"
    style.stroke: "#9c27b0"
    shape: document
  }
}

clients: Client Applications {
  style.fill: "#fce4ec"
  style.stroke: "#e91e63"
  app1: App 1 {shape: rectangle}
  app2: App 2 {shape: rectangle}
}

clients -> cluster.nodes.node1: "REST API\nPort 9200" {style.stroke: "#e91e63"}
clients -> cluster.nodes.node2: "REST API\nPort 9200" {style.stroke: "#e91e63"}
clients -> cluster.nodes.node3: "REST API\nPort 9200" {style.stroke: "#e91e63"}

cluster.nodes.node1 <-> cluster.nodes.node2: "Transport\nPort 9300" {style.stroke: "#666"; style.stroke-dash: 3}
cluster.nodes.node2 <-> cluster.nodes.node3: "Transport\nPort 9300" {style.stroke: "#666"; style.stroke-dash: 3}
cluster.nodes.node1 <-> cluster.nodes.node3: "Transport\nPort 9300" {style.stroke: "#666"; style.stroke-dash: 3}
```

## Node Roles

| Role | Description | Use Case |
|------|-------------|----------|
| `master` | Cluster management, index metadata | Dedicated masters for large clusters |
| `data` | Store data, execute searches | General data nodes |
| `data_content` | Content/product data | Search-heavy workloads |
| `data_hot` | Recent, frequently queried data | Time-series hot tier |
| `data_warm` | Less frequent queries | Time-series warm tier |
| `data_cold` | Infrequent access, searchable | Cost-optimized storage |
| `data_frozen` | Rarely accessed, searchable snapshots | Archive tier |
| `ingest` | Pre-process documents | Pipeline transformations |
| `ml` | Machine learning jobs | Anomaly detection |
| `coordinating` | Route requests, reduce results | Query-heavy workloads |

## Version Information

- **Elasticsearch**: 8.12.x (current stable)
- **Kibana**: 8.12.x
- **Elastic Stack**: 8.x (unified versioning)

## Related Documentation

- [Overview](overview.md) - Architecture, mappings, and configuration
- [Usage](usage.md) - Queries, aggregations, and best practices
