# Elasticsearch Overview

## Architecture Deep Dive

### Cluster Topology

```
                              ┌─────────────────────────────────────────────────────────────┐
                              │                    Production Cluster                       │
                              └─────────────────────────────────────────────────────────────┘
                                                          │
        ┌─────────────────────────────────────────────────┼─────────────────────────────────────────────────┐
        │                                                 │                                                 │
        ▼                                                 ▼                                                 ▼
┌───────────────┐                               ┌───────────────┐                               ┌───────────────┐
│ Master Node 1 │                               │ Master Node 2 │                               │ Master Node 3 │
│  (Dedicated)  │◀─────────────────────────────▶│  (Dedicated)  │◀─────────────────────────────▶│  (Dedicated)  │
│ 2 CPU, 4GB RAM│                               │ 2 CPU, 4GB RAM│                               │ 2 CPU, 4GB RAM│
└───────────────┘                               └───────────────┘                               └───────────────┘
        │                                                 │                                                 │
        └─────────────────────────────────────────────────┼─────────────────────────────────────────────────┘
                                                          │
        ┌─────────────────────────────────────────────────┼─────────────────────────────────────────────────┐
        │                                                 │                                                 │
        ▼                                                 ▼                                                 ▼
┌───────────────┐                               ┌───────────────┐                               ┌───────────────┐
│  Hot Node 1   │                               │  Hot Node 2   │                               │  Hot Node 3   │
│   (NVMe SSD)  │                               │   (NVMe SSD)  │                               │   (NVMe SSD)  │
│ 16 CPU, 64GB  │                               │ 16 CPU, 64GB  │                               │ 16 CPU, 64GB  │
│    1TB SSD    │                               │    1TB SSD    │                               │    1TB SSD    │
└───────────────┘                               └───────────────┘                               └───────────────┘
        │                                                 │                                                 │
        └─────────────────────────────────────────────────┼─────────────────────────────────────────────────┘
                                                          │
        ┌─────────────────────────────────────────────────┼─────────────────────────────────────────────────┐
        │                                                 │                                                 │
        ▼                                                 ▼                                                 ▼
┌───────────────┐                               ┌───────────────┐                               ┌───────────────┐
│  Warm Node 1  │                               │  Warm Node 2  │                               │  Warm Node 3  │
│   (SATA SSD)  │                               │   (SATA SSD)  │                               │   (SATA SSD)  │
│ 8 CPU, 32GB   │                               │ 8 CPU, 32GB   │                               │ 8 CPU, 32GB   │
│    4TB SSD    │                               │    4TB SSD    │                               │    4TB SSD    │
└───────────────┘                               └───────────────┘                               └───────────────┘
```

### Sharding Strategy

```
Index: logs-2024.01.15
├── Primary Shard 0 ──────▶ Replica 0 (on different node)
├── Primary Shard 1 ──────▶ Replica 1 (on different node)
├── Primary Shard 2 ──────▶ Replica 2 (on different node)
├── Primary Shard 3 ──────▶ Replica 3 (on different node)
└── Primary Shard 4 ──────▶ Replica 4 (on different node)

Shard Sizing Guidelines:
- Target: 10-50 GB per shard
- Maximum: ~65 GB per shard
- Minimum shards: Number of data nodes
- Formula: (Total data size × 1.1) / 50GB = Number of shards
```

## Mappings and Schema

### Mapping Definition

```json
PUT /products
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "analysis": {
      "analyzer": {
        "custom_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "snowball"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "analyzer": "custom_analyzer",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "description": {
        "type": "text"
      },
      "price": {
        "type": "float"
      },
      "category": {
        "type": "keyword"
      },
      "tags": {
        "type": "keyword"
      },
      "created_at": {
        "type": "date",
        "format": "strict_date_optional_time||epoch_millis"
      },
      "location": {
        "type": "geo_point"
      },
      "attributes": {
        "type": "nested",
        "properties": {
          "name": { "type": "keyword" },
          "value": { "type": "keyword" }
        }
      },
      "embedding": {
        "type": "dense_vector",
        "dims": 768,
        "index": true,
        "similarity": "cosine"
      }
    }
  }
}
```

### Field Types

| Type | Use Case | Example |
|------|----------|---------|
| `text` | Full-text search | Product descriptions |
| `keyword` | Exact matching, aggregations | Status, category |
| `long`, `integer`, `float` | Numeric values | Prices, counts |
| `date` | Timestamps | Created, updated |
| `boolean` | True/false flags | Is_active |
| `geo_point` | Latitude/longitude | Locations |
| `nested` | Arrays of objects | Attributes, variants |
| `dense_vector` | ML embeddings | Semantic search |
| `object` | JSON objects | Metadata |

## Configuration

### elasticsearch.yml

```yaml
# Cluster settings
cluster.name: production-cluster
node.name: node-1

# Node roles
node.roles: [master, data_hot, ingest]

# Network
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery
discovery.seed_hosts:
  - es-master-1:9300
  - es-master-2:9300
  - es-master-3:9300
cluster.initial_master_nodes:
  - es-master-1
  - es-master-2
  - es-master-3

# Paths
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

# Memory
bootstrap.memory_lock: true

# Security
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elastic-certificates.p12

xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/http.p12

# Allocation awareness
node.attr.zone: us-east-1a
cluster.routing.allocation.awareness.attributes: zone
```

### JVM Settings (jvm.options)

```bash
# Heap size (50% of RAM, max 31GB)
-Xms16g
-Xmx16g

# GC settings (G1GC is default in ES 8.x)
-XX:+UseG1GC
-XX:G1ReservePercent=25
-XX:InitiatingHeapOccupancyPercent=30

# Disable swapping
-XX:+AlwaysPreTouch
-Xss1m

# Crash dump
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/lib/elasticsearch
```

## Index Lifecycle Management (ILM)

### ILM Policy

```json
PUT _ilm/policy/logs-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_primary_shard_size": "50gb"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "allocate": {
            "require": {
              "data": "warm"
            }
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "require": {
              "data": "cold"
            }
          },
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Data Stream Setup

```json
// Create index template
PUT _index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "data_stream": {},
  "priority": 200,
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text" },
        "level": { "type": "keyword" },
        "service": { "type": "keyword" },
        "host": { "type": "keyword" }
      }
    }
  }
}

// Create data stream
PUT _data_stream/logs-production
```

## Security Configuration

### Built-in Users

| User | Purpose |
|------|---------|
| `elastic` | Superuser |
| `kibana_system` | Kibana to ES communication |
| `logstash_system` | Logstash monitoring |
| `beats_system` | Beats monitoring |
| `apm_system` | APM server |

### Role-Based Access Control

```json
// Create role
PUT _security/role/logs_reader
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ]
}

// Create user
PUT _security/user/log_viewer
{
  "password": "secure-password",
  "roles": ["logs_reader"],
  "full_name": "Log Viewer",
  "email": "logs@example.com"
}

// Create API key
POST _security/api_key
{
  "name": "app-api-key",
  "role_descriptors": {
    "logs_writer": {
      "cluster": ["monitor"],
      "index": [
        {
          "names": ["logs-*"],
          "privileges": ["write", "create_index"]
        }
      ]
    }
  },
  "expiration": "30d"
}
```

## Monitoring

### Key Metrics

| Metric | Healthy Range | Alert Threshold |
|--------|---------------|-----------------|
| Cluster status | Green | Yellow/Red |
| JVM heap used | < 75% | > 85% |
| CPU usage | < 80% | > 90% |
| Disk usage | < 80% | > 85% |
| Search latency (p99) | < 500ms | > 1000ms |
| Indexing rate | Stable | Sudden drops |
| Pending tasks | 0 | > 100 |
| Unassigned shards | 0 | > 0 |

### Cluster Health API

```bash
# Cluster health
GET _cluster/health?pretty

# Node stats
GET _nodes/stats?pretty

# Index stats
GET logs-*/_stats?pretty

# Shard allocation
GET _cat/shards?v&h=index,shard,prirep,state,docs,store,node

# Pending tasks
GET _cluster/pending_tasks
```

### Prometheus Exporter

```yaml
# docker-compose.yml
elasticsearch-exporter:
  image: quay.io/prometheuscommunity/elasticsearch-exporter:latest
  command:
    - '--es.uri=http://elastic:password@elasticsearch:9200'
    - '--es.all'
    - '--es.indices'
    - '--es.cluster_settings'
  ports:
    - "9114:9114"
```

## Backup and Restore

### Snapshot Repository

```json
// Register S3 repository
PUT _snapshot/s3-backups
{
  "type": "s3",
  "settings": {
    "bucket": "elasticsearch-snapshots",
    "region": "us-east-1",
    "base_path": "production",
    "compress": true,
    "server_side_encryption": true
  }
}

// Create snapshot
PUT _snapshot/s3-backups/snapshot-2024-01-15
{
  "indices": "logs-*",
  "ignore_unavailable": true,
  "include_global_state": false
}

// Restore snapshot
POST _snapshot/s3-backups/snapshot-2024-01-15/_restore
{
  "indices": "logs-2024.01.*",
  "rename_pattern": "logs-(.+)",
  "rename_replacement": "restored-logs-$1"
}
```

### Snapshot Lifecycle Management

```json
PUT _slm/policy/daily-snapshots
{
  "schedule": "0 30 1 * * ?",
  "name": "<daily-snap-{now/d}>",
  "repository": "s3-backups",
  "config": {
    "indices": ["*"],
    "ignore_unavailable": true,
    "include_global_state": false
  },
  "retention": {
    "expire_after": "30d",
    "min_count": 5,
    "max_count": 50
  }
}
```
