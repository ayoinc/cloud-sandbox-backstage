# ELK Stack Overview

## Architecture Deep Dive

### Elasticsearch Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Elasticsearch Cluster                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  Master-Eligible Nodes                  │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐            │    │
│  │  │  Master 1 │  │  Master 2 │  │  Master 3 │            │    │
│  │  │ (Active)  │  │ (Standby) │  │ (Standby) │            │    │
│  │  └───────────┘  └───────────┘  └───────────┘            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                      Data Nodes                         │    │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐            │    │
│  │  │  Data 1   │  │  Data 2   │  │  Data 3   │            │    │
│  │  │ Shards:   │  │ Shards:   │  │ Shards:   │            │    │
│  │  │ P0,R1,P2  │  │ R0,P1,R2  │  │ P3,R3,P4  │            │    │
│  │  └───────────┘  └───────────┘  └───────────┘            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  Coordinating Nodes                     │    │
│  │  ┌───────────┐  ┌───────────┐                           │    │
│  │  │  Coord 1  │  │  Coord 2  │   (Query routing)         │    │
│  │  └───────────┘  └───────────┘                           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Node Roles

| Role | Description | Use Case |
|------|-------------|----------|
| master | Cluster coordination | Cluster state management |
| data | Store and search data | Primary workload |
| data_content | Non-time series data | Catalog, reference data |
| data_hot | Recent, frequently queried | Last 24-48 hours |
| data_warm | Less frequent access | 1-30 days old |
| data_cold | Rarely accessed | > 30 days |
| data_frozen | Archival, searchable | Long-term retention |
| ingest | Pre-process documents | Enrichment, transforms |
| ml | Machine learning | Anomaly detection |
| coordinating | Query routing only | Load balancing |

### Shard Allocation

```
Index: logs-2024.01.15
├── Primary Shard 0 (Node: data-1)
│   └── Replica Shard 0 (Node: data-2)
├── Primary Shard 1 (Node: data-2)
│   └── Replica Shard 1 (Node: data-3)
├── Primary Shard 2 (Node: data-3)
│   └── Replica Shard 2 (Node: data-1)
```

## Configuration

### Elasticsearch Configuration

```yaml
# elasticsearch.yml
cluster.name: production-elk
node.name: es-node-1
node.roles: [master, data]

path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

discovery.seed_hosts:
  - es-node-1:9300
  - es-node-2:9300
  - es-node-3:9300

cluster.initial_master_nodes:
  - es-node-1
  - es-node-2
  - es-node-3

# Memory settings
bootstrap.memory_lock: true

# X-Pack Security
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12

# Index Lifecycle Management
xpack.ilm.enabled: true

# Monitoring
xpack.monitoring.collection.enabled: true
```

### JVM Settings

```bash
# jvm.options
-Xms4g
-Xmx4g

# GC settings (G1GC is default in ES 8.x)
-XX:+UseG1GC
-XX:G1HeapRegionSize=32m
-XX:MaxGCPauseMillis=200
-XX:InitiatingHeapOccupancyPercent=30

# Heap dump on OOM
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/lib/elasticsearch

# GC logging
-Xlog:gc*,gc+age=trace,safepoint:file=/var/log/elasticsearch/gc.log:utctime,pid,tags:filecount=32,filesize=64m
```

### Logstash Configuration

```ruby
# logstash.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/logstash/certs/logstash.crt"
    ssl_key => "/etc/logstash/certs/logstash.key"
  }
  
  kafka {
    bootstrap_servers => "kafka:9092"
    topics => ["application-logs"]
    codec => json
    group_id => "logstash-consumers"
  }
}

filter {
  # Parse JSON logs
  if [message] =~ /^\{/ {
    json {
      source => "message"
      target => "parsed"
    }
  }
  
  # Parse standard log format
  grok {
    match => { 
      "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{DATA:logger} - %{GREEDYDATA:log_message}"
    }
  }
  
  # Parse timestamp
  date {
    match => ["timestamp", "ISO8601", "yyyy-MM-dd HH:mm:ss,SSS"]
    target => "@timestamp"
  }
  
  # GeoIP lookup
  if [client_ip] {
    geoip {
      source => "client_ip"
      target => "geoip"
    }
  }
  
  # Add environment metadata
  mutate {
    add_field => {
      "environment" => "${ENVIRONMENT:production}"
      "cluster" => "${CLUSTER_NAME:default}"
    }
    remove_field => ["message", "timestamp"]
  }
  
  # Drop debug logs in production
  if [level] == "DEBUG" and [environment] == "production" {
    drop {}
  }
}

output {
  elasticsearch {
    hosts => ["https://elasticsearch:9200"]
    user => "${ES_USER}"
    password => "${ES_PASSWORD}"
    ssl => true
    cacert => "/etc/logstash/certs/ca.crt"
    index => "logs-%{[environment]}-%{+YYYY.MM.dd}"
    ilm_enabled => true
    ilm_rollover_alias => "logs"
    ilm_policy => "logs-policy"
  }
  
  # Dead letter queue for failures
  if "_grokparsefailure" in [tags] or "_jsonparsefailure" in [tags] {
    file {
      path => "/var/log/logstash/failed-%{+YYYY-MM-dd}.log"
    }
  }
}
```

### Kibana Configuration

```yaml
# kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.name: "kibana"

elasticsearch.hosts: ["https://elasticsearch:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "${KIBANA_PASSWORD}"
elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/certs/ca.crt"]

# Encryption keys
xpack.security.encryptionKey: "32-character-string-for-security"
xpack.encryptedSavedObjects.encryptionKey: "32-character-string-for-objects"
xpack.reporting.encryptionKey: "32-character-string-for-reports"

# Session
xpack.security.session.idleTimeout: "1h"
xpack.security.session.lifespan: "24h"

# Monitoring
monitoring.ui.enabled: true
monitoring.ui.ccs.enabled: true

# Logging
logging.appenders.file:
  type: file
  fileName: /var/log/kibana/kibana.log
  layout:
    type: json
```

### Filebeat Configuration

```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/app/*.log
    fields:
      app: myapp
      environment: production
    fields_under_root: true
    multiline:
      pattern: '^\d{4}-\d{2}-\d{2}'
      negate: true
      match: after

  - type: container
    paths:
      - /var/lib/docker/containers/*/*.log
    processors:
      - add_kubernetes_metadata:
          host: ${NODE_NAME}
          matchers:
            - logs_path:
                logs_path: "/var/lib/docker/containers/"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - drop_fields:
      fields: ["agent.ephemeral_id", "agent.hostname"]

output.elasticsearch:
  hosts: ["https://elasticsearch:9200"]
  username: "${ES_USER}"
  password: "${ES_PASSWORD}"
  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]
  index: "filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"

setup.kibana:
  host: "https://kibana:5601"
  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]

setup.ilm.enabled: true
setup.ilm.rollover_alias: "filebeat"
setup.ilm.pattern: "{now/d}-000001"
```

## Security Configuration

### Built-in Users

```bash
# Reset passwords for built-in users
bin/elasticsearch-reset-password -u elastic
bin/elasticsearch-reset-password -u kibana_system
bin/elasticsearch-reset-password -u logstash_system
bin/elasticsearch-reset-password -u beats_system

# Create API key
POST /_security/api_key
{
  "name": "filebeat-api-key",
  "role_descriptors": {
    "filebeat_writer": {
      "cluster": ["monitor", "read_ilm"],
      "index": [
        {
          "names": ["filebeat-*"],
          "privileges": ["create_index", "write", "manage"]
        }
      ]
    }
  }
}
```

### Role-Based Access Control

```bash
# Create role via API
PUT /_security/role/logs_reader
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read", "view_index_metadata"],
      "field_security": {
        "grant": ["*"],
        "except": ["password", "secret"]
      }
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["feature_discover.read", "feature_dashboard.read"],
      "resources": ["space:default"]
    }
  ]
}

# Create user
PUT /_security/user/log_viewer
{
  "password": "secure_password",
  "roles": ["logs_reader"],
  "full_name": "Log Viewer",
  "email": "viewer@example.com"
}
```

### TLS/SSL Configuration

```bash
# Generate certificates
bin/elasticsearch-certutil ca --out ca.p12 --pass ""
bin/elasticsearch-certutil cert --ca ca.p12 --out certs.p12 --pass ""

# For HTTP layer
bin/elasticsearch-certutil http

# Verify certificates
openssl pkcs12 -in certs.p12 -info -nokeys
```

## Index Lifecycle Management (ILM)

```bash
# Create ILM policy
PUT _ilm/policy/logs-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
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
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "searchable_snapshot": {
            "snapshot_repository": "my-repo"
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

# Create index template
PUT _index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy",
      "index.lifecycle.rollover_alias": "logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "level": { "type": "keyword" },
        "message": { "type": "text" },
        "host": { "type": "keyword" },
        "service": { "type": "keyword" }
      }
    }
  }
}
```

## Monitoring

### Cluster Health

```bash
# Cluster health
GET /_cluster/health?pretty

# Node stats
GET /_nodes/stats

# Index stats
GET /_stats

# Pending tasks
GET /_cluster/pending_tasks

# Shard allocation
GET /_cat/shards?v

# Thread pools
GET /_cat/thread_pool?v&h=node_name,name,active,rejected,completed
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Cluster health | green/yellow/red | != green |
| JVM heap used | Memory usage | > 75% |
| CPU usage | Node CPU | > 80% |
| Disk usage | Data directory | > 85% |
| Search latency | Query response time | > 500ms |
| Indexing rate | Documents/sec | Drop > 50% |
| Rejected threads | Thread pool rejections | > 0 |
| GC time | Garbage collection | > 5s |

### Prometheus Exporter

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'elasticsearch'
    static_configs:
      - targets: ['es-exporter:9114']
    
  - job_name: 'logstash'
    static_configs:
      - targets: ['logstash:9600']
    metrics_path: /metrics
```

## Performance Tuning

### Elasticsearch Tuning

```yaml
# Indexing performance
index.refresh_interval: 30s
index.number_of_replicas: 0  # For bulk indexing, restore after
index.translog.durability: async
index.translog.sync_interval: 30s

# Search performance
index.max_result_window: 10000
search.max_buckets: 10000

# Thread pools
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000
```

### Logstash Tuning

```yaml
# logstash.yml
pipeline.workers: 4
pipeline.batch.size: 125
pipeline.batch.delay: 50

# JVM
-Xms2g
-Xmx2g
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
