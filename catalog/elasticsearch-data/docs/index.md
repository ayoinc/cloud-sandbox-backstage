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

```
                                    ┌──────────────────────────────────────────────┐
                                    │           Elasticsearch Cluster              │
                                    └──────────────────────────────────────────────┘
                                                         │
                    ┌────────────────────────────────────┼────────────────────────────────────┐
                    │                                    │                                    │
            ┌───────▼───────┐                    ┌───────▼───────┐                    ┌───────▼───────┐
            │    Node 1     │                    │    Node 2     │                    │    Node 3     │
            │ Master-eligible│                    │ Master-eligible│                    │ Master-eligible│
            │   Data Node   │                    │   Data Node   │                    │   Data Node   │
            └───────┬───────┘                    └───────┬───────┘                    └───────┬───────┘
                    │                                    │                                    │
    ┌───────────────┴───────────────┐    ┌───────────────┴───────────────┐    ┌───────────────┴───────────────┐
    │  Primary Shard 0              │    │  Primary Shard 1              │    │  Primary Shard 2              │
    │  Replica Shard 1              │    │  Replica Shard 2              │    │  Replica Shard 0              │
    │  Replica Shard 2              │    │  Replica Shard 0              │    │  Replica Shard 1              │
    └───────────────────────────────┘    └───────────────────────────────┘    └───────────────────────────────┘

                                         ┌─────────────────────────────┐
                                         │     Index: logs-2024.01     │
                                         │  5 Primary + 1 Replica each │
                                         │     = 10 total shards       │
                                         └─────────────────────────────┘
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
