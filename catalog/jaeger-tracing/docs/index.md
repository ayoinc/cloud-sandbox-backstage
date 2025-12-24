# Jaeger Distributed Tracing

Open-source distributed tracing platform for monitoring and troubleshooting microservices-based architectures, providing end-to-end request tracing and performance analysis.

## Quick Start

```bash
# Run Jaeger all-in-one (development)
docker run -d --name jaeger \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 14250:14250 \
  -p 14268:14268 \
  -p 14269:14269 \
  jaegertracing/all-in-one:1.54

# Access Jaeger UI
open http://localhost:16686

# Test with hotrod sample app
docker run --rm -it \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318 \
  -p 8080:8080 \
  jaegertracing/example-hotrod:1.54 all

# Generate traces
curl http://localhost:8080/dispatch?customer=123
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Distributed Tracing** | End-to-end request tracking | Debug latency issues |
| **Root Cause Analysis** | Identify failing services | Incident investigation |
| **Service Dependencies** | Auto-discovered topology | Architecture visualization |
| **Performance Optimization** | Latency breakdown | Bottleneck identification |
| **OpenTelemetry Native** | OTLP protocol support | Vendor-neutral instrumentation |
| **Adaptive Sampling** | Intelligent trace selection | Production cost control |
| **Span Analytics** | Aggregated span metrics | SLO monitoring |
| **Compare Traces** | Side-by-side analysis | Regression detection |
| **Multi-Tenancy** | Tenant isolation | SaaS deployments |

## Architecture

```d2
direction: down

services: Instrumented Applications {
  direction: right
  service-a: Service A\n+ OTEL SDK
  service-b: Service B\n+ OTEL SDK
  service-c: Service C\n+ OTEL SDK
  service-d: Service D\n+ OTEL SDK
}

collector: Jaeger Collector {
  receivers: Receivers {
    direction: right
    otlp: OTLP\n:4317/4318
    jaeger: Jaeger\n:14250
    zipkin: Zipkin\n:9411
  }
  
  sampling: Sampling Engine
  
  receivers.otlp -> sampling
  receivers.jaeger -> sampling
  receivers.zipkin -> sampling
}

storage: Storage Backend {
  direction: right
  elasticsearch: Elasticsearch
  cassandra: Cassandra
  kafka: Kafka
  badger: Badger
}

query: Jaeger Query {
  ui: Jaeger UI\n:16686
  api: Query API\n:16685
}

services.service-a -> collector.receivers.otlp: OTLP/gRPC
services.service-b -> collector.receivers.otlp: OTLP/gRPC
services.service-c -> collector.receivers.otlp: OTLP/gRPC
services.service-d -> collector.receivers.otlp: OTLP/gRPC

collector.sampling -> storage.elasticsearch: Write Spans
collector.sampling -> storage.cassandra: Write Spans {
  style.stroke-dash: 3
}
collector.sampling -> storage.kafka: Buffer {
  style.stroke-dash: 3
}

storage.elasticsearch -> query.api: Read Spans
query.api -> query.ui
```

## Trace Anatomy

```
Trace (end-to-end request)
├── Span A: HTTP GET /api/orders (root span)
│   ├── Span B: Database query
│   │   └── Duration: 50ms
│   ├── Span C: HTTP POST /inventory-service/check
│   │   ├── Span D: Redis cache lookup
│   │   │   └── Duration: 2ms
│   │   └── Span E: Database query
│   │       └── Duration: 30ms
│   └── Span F: HTTP POST /payment-service/charge
│       ├── Span G: External API call
│       │   └── Duration: 200ms
│       └── Duration: 250ms
└── Total Duration: 400ms
```

## Component Ports

| Port | Protocol | Component | Purpose |
|------|----------|-----------|---------|
| 4317 | gRPC | Collector | OTLP gRPC receiver |
| 4318 | HTTP | Collector | OTLP HTTP receiver |
| 6831 | UDP | Agent | Thrift compact (deprecated) |
| 6832 | UDP | Agent | Thrift binary (deprecated) |
| 14250 | gRPC | Collector | Jaeger gRPC receiver |
| 14268 | HTTP | Collector | Jaeger HTTP receiver |
| 14269 | HTTP | Collector | Admin/health |
| 16686 | HTTP | Query | Jaeger UI |
| 16685 | gRPC | Query | Query gRPC API |
| 5778 | HTTP | Agent | Sampling config (deprecated) |

## Version Information

| Component | Version | Release Date |
|-----------|---------|--------------|
| Jaeger | 1.54.0 | 2024 |
| OpenTelemetry SDK | 1.33.0 | 2024 |
| OTLP Protocol | 1.1.0 | 2024 |

## Sampling Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| **Const** | Sample all or none | Development, low traffic |
| **Probabilistic** | Random percentage | General production |
| **Rate Limiting** | Traces per second | High traffic control |
| **Remote** | Server-controlled | Dynamic adjustment |
| **Adaptive** | Automatic optimization | Large scale systems |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and monitoring
- [Usage](usage.md) - Deployment examples, instrumentation, and troubleshooting
