# Jaeger Distributed Tracing Overview

## Architecture Deep Dive

### Jaeger V2 Architecture (OpenTelemetry Collector)

```d2
direction: down

otel-collector: Jaeger V2 (OTEL Collector Based) {
  receivers: Receivers {
    direction: right
    otlp: OTLP\ngRPC/HTTP
    jaeger: Jaeger\ngRPC
    zipkin: Zipkin\nHTTP
    kafka: Kafka\nConsumer
  }

  processors: Processors {
    direction: right
    batch: Batch
    sampling: Sampling
    tail: Tail-Based\nSampling
    attributes: Attribute\nProcessor
    
    batch -> sampling -> tail -> attributes
  }

  exporters: Exporters {
    direction: right
    jaeger-storage: Jaeger\nStorage
    otlp-export: OTLP
    kafka-producer: Kafka\nProducer
    prometheus: Prometheus
  }

  receivers.otlp -> processors.batch
  receivers.jaeger -> processors.batch
  receivers.zipkin -> processors.batch
  receivers.kafka -> processors.batch
  
  processors.attributes -> exporters.jaeger-storage
  processors.attributes -> exporters.otlp-export
  processors.attributes -> exporters.kafka-producer
  processors.attributes -> exporters.prometheus
}
```

### Deployment Modes

| Mode | Components | Use Case |
|------|------------|----------|
| **All-in-one** | Single binary | Development, testing |
| **Collector + Query** | Separate binaries | Small production |
| **Distributed** | Collectors, Query, Storage | Large scale |
| **Streaming** | + Kafka ingestion | High throughput |

### Storage Backend Comparison

| Backend | Pros | Cons | Best For |
|---------|------|------|----------|
| **Elasticsearch** | Mature, scalable, analytics | Resource intensive | Large scale, analytics |
| **Cassandra** | High write throughput | Complex operations | High cardinality |
| **ClickHouse** | Fast queries, compression | Newer integration | Analytics focus |
| **Badger** | Simple, embedded | Single node only | Small deployments |
| **Kafka** | Buffering, reprocessing | Adds complexity | High throughput ingestion |

## Configuration

### Collector Configuration (OTEL Collector format)

```yaml
# jaeger-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
      thrift_http:
        endpoint: 0.0.0.0:14268

processors:
  batch:
    timeout: 1s
    send_batch_size: 10000
    send_batch_max_size: 11000
  
  memory_limiter:
    check_interval: 1s
    limit_mib: 2000
    spike_limit_mib: 500
  
  probabilistic_sampler:
    sampling_percentage: 10

exporters:
  jaeger_storage_exporter:
    trace_storage: elasticsearch-main
  
  prometheus:
    endpoint: 0.0.0.0:8889

extensions:
  jaeger_storage:
    elasticsearch-main:
      server_urls: http://elasticsearch:9200
      index_prefix: jaeger
      tags_as_fields:
        all: true
      
  jaeger_query:
    trace_storage: elasticsearch-main
    grpc:
      endpoint: 0.0.0.0:16685
    http:
      endpoint: 0.0.0.0:16686

service:
  extensions: [jaeger_storage, jaeger_query]
  pipelines:
    traces:
      receivers: [otlp, jaeger]
      processors: [memory_limiter, batch]
      exporters: [jaeger_storage_exporter]
```

### Sampling Configuration

```yaml
# sampling.yaml
service_strategies:
  - service: "api-gateway"
    type: probabilistic
    param: 0.5  # 50% sampling
    
  - service: "payment-service"
    type: const
    param: 1  # Sample all traces (critical service)
    
  - service: "logging-service"
    type: ratelimiting
    param: 100  # 100 traces per second

default_strategy:
  type: probabilistic
  param: 0.1  # 10% default sampling

# Per-operation strategies
per_operation_strategies:
  - service: "api-gateway"
    per_operation_strategies:
      - operation: "GET /health"
        type: const
        param: 0  # Never sample health checks
      - operation: "POST /api/orders"
        type: const
        param: 1  # Always sample orders
```

### Environment Variables

```bash
# Collector
COLLECTOR_OTLP_ENABLED=true
COLLECTOR_ZIPKIN_HOST_PORT=:9411
SPAN_STORAGE_TYPE=elasticsearch
ES_SERVER_URLS=http://elasticsearch:9200
ES_INDEX_PREFIX=jaeger
ES_USERNAME=elastic
ES_PASSWORD=changeme

# Query
QUERY_BASE_PATH=/jaeger
QUERY_UI_CONFIG=/etc/jaeger/ui-config.json

# Sampling
SAMPLING_STRATEGIES_FILE=/etc/jaeger/sampling.yaml

# TLS
COLLECTOR_OTLP_GRPC_TLS_ENABLED=true
COLLECTOR_OTLP_GRPC_TLS_CERT=/etc/jaeger/tls/server.crt
COLLECTOR_OTLP_GRPC_TLS_KEY=/etc/jaeger/tls/server.key
```

### UI Configuration

```json
{
  "dependencies": {
    "dagMaxNumServices": 200,
    "menuEnabled": true
  },
  "archiveEnabled": true,
  "tracking": {
    "gaID": "UA-XXXXXXXX-X"
  },
  "menu": [
    {
      "label": "Documentation",
      "url": "/docs",
      "anchorTarget": "_blank"
    }
  ],
  "linkPatterns": [
    {
      "type": "logs",
      "key": "traceID",
      "url": "http://kibana:5601/app/discover#/?_g=()&_a=(query:(match:(trace.id:'#{traceID}')))",
      "text": "View logs"
    }
  ]
}
```

## Elasticsearch Storage Configuration

### Index Settings

```bash
# Create index template for Jaeger
PUT _index_template/jaeger-span
{
  "index_patterns": ["jaeger-span-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "jaeger-ilm-policy",
      "index.lifecycle.rollover_alias": "jaeger-span"
    }
  }
}

# ILM policy
PUT _ilm/policy/jaeger-ilm-policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "1d"
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
          }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

## Monitoring

### Prometheus Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'jaeger'
    static_configs:
      - targets: ['jaeger-collector:14269', 'jaeger-query:16687']
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `jaeger_collector_spans_received_total` | Total spans received | Rate drop > 50% |
| `jaeger_collector_spans_dropped_total` | Dropped spans | > 0 sustained |
| `jaeger_collector_queue_length` | Queue size | > 80% capacity |
| `jaeger_collector_save_latency_bucket` | Storage latency | p99 > 500ms |
| `jaeger_query_latency_bucket` | Query latency | p99 > 2s |
| `jaeger_agent_reporter_batches_failures_total` | Agent failures | > 0 |

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Jaeger Tracing",
    "panels": [
      {
        "title": "Spans Received Rate",
        "targets": [{
          "expr": "rate(jaeger_collector_spans_received_total[5m])"
        }]
      },
      {
        "title": "Spans Dropped",
        "targets": [{
          "expr": "rate(jaeger_collector_spans_dropped_total[5m])"
        }]
      },
      {
        "title": "Save Latency p99",
        "targets": [{
          "expr": "histogram_quantile(0.99, rate(jaeger_collector_save_latency_bucket[5m]))"
        }]
      },
      {
        "title": "Queue Length",
        "targets": [{
          "expr": "jaeger_collector_queue_length"
        }]
      }
    ]
  }
}
```

### Health Check Endpoints

```bash
# Collector health
curl http://jaeger-collector:14269/

# Query health
curl http://jaeger-query:16687/

# Metrics
curl http://jaeger-collector:14269/metrics
```

## Security Configuration

### TLS Configuration

```yaml
# Collector with TLS
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        tls:
          cert_file: /etc/jaeger/tls/server.crt
          key_file: /etc/jaeger/tls/server.key
          ca_file: /etc/jaeger/tls/ca.crt
          client_ca_file: /etc/jaeger/tls/ca.crt
```

### Authentication

```yaml
# Bearer token authentication
extensions:
  bearertokenauth:
    token: ${JAEGER_AUTH_TOKEN}

receivers:
  otlp:
    protocols:
      grpc:
        auth:
          authenticator: bearertokenauth
```

## Span Data Model

```json
{
  "traceID": "abc123def456",
  "spanID": "span789",
  "operationName": "HTTP GET /api/users",
  "references": [
    {
      "refType": "CHILD_OF",
      "traceID": "abc123def456",
      "spanID": "parent123"
    }
  ],
  "startTime": 1705312800000000,
  "duration": 150000,
  "tags": [
    {"key": "http.method", "value": "GET"},
    {"key": "http.status_code", "value": 200},
    {"key": "span.kind", "value": "server"},
    {"key": "component", "value": "net/http"}
  ],
  "logs": [
    {
      "timestamp": 1705312800050000,
      "fields": [
        {"key": "event", "value": "cache.miss"},
        {"key": "cache.key", "value": "user:123"}
      ]
    }
  ],
  "process": {
    "serviceName": "user-service",
    "tags": [
      {"key": "hostname", "value": "user-service-pod-abc"},
      {"key": "ip", "value": "10.0.0.42"}
    ]
  }
}
```

## Performance Tuning

### Collector Tuning

```yaml
processors:
  batch:
    timeout: 200ms
    send_batch_size: 8192
    send_batch_max_size: 10000
  
  memory_limiter:
    check_interval: 1s
    limit_mib: 4000
    spike_limit_mib: 800

# Multiple queue consumers
exporters:
  jaeger_storage_exporter:
    sending_queue:
      enabled: true
      num_consumers: 10
      queue_size: 5000
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s
```

### Elasticsearch Tuning for Jaeger

```yaml
# Bulk indexing optimization
ES_BULK_SIZE: 5000000  # 5MB
ES_BULK_WORKERS: 3
ES_BULK_ACTIONS: 1000
ES_BULK_FLUSH_INTERVAL: 200ms

# Connection pool
ES_NUM_SHARDS: 5
ES_NUM_REPLICAS: 1
ES_MAX_NUM_SPANS: 10000
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
