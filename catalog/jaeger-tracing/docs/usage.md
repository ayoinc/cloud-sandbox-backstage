# Jaeger Distributed Tracing Usage Guide

## Docker Compose Deployment

### Development (All-in-One)

```yaml
# docker-compose.yml
version: '3.8'

services:
  jaeger:
    image: jaegertracing/all-in-one:1.54
    container_name: jaeger
    ports:
      - "4317:4317"    # OTLP gRPC
      - "4318:4318"    # OTLP HTTP
      - "16686:16686"  # Jaeger UI
      - "14250:14250"  # Jaeger gRPC
      - "14268:14268"  # Jaeger HTTP
      - "9411:9411"    # Zipkin
    environment:
      - COLLECTOR_OTLP_ENABLED=true
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:14269/"]
      interval: 5s
      timeout: 3s
      retries: 3
```

### Production (with Elasticsearch)

```yaml
# docker-compose.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"
    volumes:
      - esdata:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q 'green\\|yellow'"]
      interval: 10s
      timeout: 5s
      retries: 10

  jaeger-collector:
    image: jaegertracing/jaeger-collector:1.54
    container_name: jaeger-collector
    ports:
      - "4317:4317"
      - "4318:4318"
      - "14250:14250"
      - "14268:14268"
      - "14269:14269"
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=http://elasticsearch:9200
      - ES_INDEX_PREFIX=jaeger
      - COLLECTOR_OTLP_ENABLED=true
    depends_on:
      elasticsearch:
        condition: service_healthy

  jaeger-query:
    image: jaegertracing/jaeger-query:1.54
    container_name: jaeger-query
    ports:
      - "16686:16686"
      - "16687:16687"
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=http://elasticsearch:9200
      - ES_INDEX_PREFIX=jaeger
    depends_on:
      - jaeger-collector

volumes:
  esdata:
```

### Production (with Kafka Buffering)

```yaml
# docker-compose.yml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  jaeger-collector:
    image: jaegertracing/jaeger-collector:1.54
    ports:
      - "4317:4317"
      - "14250:14250"
    environment:
      - SPAN_STORAGE_TYPE=kafka
      - KAFKA_PRODUCER_BROKERS=kafka:9092
      - KAFKA_TOPIC=jaeger-spans
      - COLLECTOR_OTLP_ENABLED=true

  jaeger-ingester:
    image: jaegertracing/jaeger-ingester:1.54
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=http://elasticsearch:9200
      - KAFKA_CONSUMER_BROKERS=kafka:9092
      - KAFKA_CONSUMER_TOPIC=jaeger-spans
      - KAFKA_CONSUMER_GROUP=jaeger-ingester

  jaeger-query:
    image: jaegertracing/jaeger-query:1.54
    ports:
      - "16686:16686"
    environment:
      - SPAN_STORAGE_TYPE=elasticsearch
      - ES_SERVER_URLS=http://elasticsearch:9200
```

## Kubernetes Deployment

### Jaeger Operator

```bash
# Install cert-manager (required)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# Install Jaeger Operator
kubectl create namespace observability
kubectl apply -n observability -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.54.0/jaeger-operator.yaml
```

### Jaeger Instance (Production)

```yaml
# jaeger.yaml
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: production
  namespace: observability
spec:
  strategy: production
  
  collector:
    replicas: 3
    maxReplicas: 5
    resources:
      requests:
        memory: 512Mi
        cpu: 500m
      limits:
        memory: 1Gi
        cpu: 1000m
    options:
      collector:
        num-workers: 100
        queue-size: 10000
  
  query:
    replicas: 2
    resources:
      requests:
        memory: 256Mi
        cpu: 250m
      limits:
        memory: 512Mi
        cpu: 500m
    metricsStorage:
      type: prometheus
  
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: https://elasticsearch:9200
        index-prefix: jaeger
        tls:
          ca: /es/certificates/ca.crt
        num-shards: 5
        num-replicas: 1
    secretName: jaeger-es-secret
    esIndexCleaner:
      enabled: true
      numberOfDays: 14
      schedule: "55 23 * * *"
    esRollover:
      enabled: true
      schedule: "0 0 * * *"
  
  sampling:
    options:
      default_strategy:
        type: probabilistic
        param: 0.1
---
apiVersion: v1
kind: Secret
metadata:
  name: jaeger-es-secret
  namespace: observability
type: Opaque
stringData:
  ES_PASSWORD: changeme
  ES_USERNAME: elastic
```

### OpenTelemetry Collector Sidecar

```yaml
# otel-sidecar.yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: sidecar
spec:
  mode: sidecar
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
          http:
    processors:
      batch:
        timeout: 1s
      memory_limiter:
        check_interval: 1s
        limit_mib: 256
    exporters:
      otlp:
        endpoint: jaeger-collector.observability:4317
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp]
```

## Instrumentation Examples

### Python (OpenTelemetry)

```python
# pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp
# pip install opentelemetry-instrumentation-flask opentelemetry-instrumentation-requests

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from flask import Flask

# Configure tracer
resource = Resource.create({
    "service.name": "order-service",
    "service.version": "1.0.0",
    "deployment.environment": "production"
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(
    OTLPSpanExporter(
        endpoint="jaeger-collector:4317",
        insecure=True
    )
)
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

# Auto-instrument Flask and requests
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route('/orders/<order_id>')
def get_order(order_id):
    # Create custom span
    with tracer.start_as_current_span("fetch_order") as span:
        span.set_attribute("order.id", order_id)
        
        # Nested span
        with tracer.start_as_current_span("database_query"):
            order = db.query(f"SELECT * FROM orders WHERE id = {order_id}")
        
        # Add event
        span.add_event("order_fetched", {"order.status": order.status})
        
        return order

@app.route('/orders', methods=['POST'])
def create_order():
    with tracer.start_as_current_span("create_order") as span:
        try:
            # Business logic
            order = process_order(request.json)
            span.set_attribute("order.id", order.id)
            span.set_status(trace.StatusCode.OK)
            return order
        except Exception as e:
            span.set_status(trace.StatusCode.ERROR, str(e))
            span.record_exception(e)
            raise
```

### Node.js (OpenTelemetry)

```javascript
// npm install @opentelemetry/api @opentelemetry/sdk-node
// npm install @opentelemetry/exporter-trace-otlp-grpc
// npm install @opentelemetry/auto-instrumentations-node

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Initialize SDK
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'user-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: 'production'
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'grpc://jaeger-collector:4317'
  }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();

// Manual instrumentation
const { trace, SpanStatusCode } = require('@opentelemetry/api');
const tracer = trace.getTracer('user-service');

const express = require('express');
const app = express();

app.get('/users/:id', async (req, res) => {
  const span = tracer.startSpan('get_user');
  
  try {
    span.setAttribute('user.id', req.params.id);
    
    // Nested span
    const dbSpan = tracer.startSpan('database_query', {
      parent: trace.setSpan(trace.context(), span)
    });
    const user = await db.findUser(req.params.id);
    dbSpan.end();
    
    span.addEvent('user_found', { 'user.email': user.email });
    span.setStatus({ code: SpanStatusCode.OK });
    
    res.json(user);
  } catch (error) {
    span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    span.recordException(error);
    res.status(500).send(error.message);
  } finally {
    span.end();
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown().then(() => process.exit(0));
});
```

### Go (OpenTelemetry)

```go
package main

import (
    "context"
    "log"
    "net/http"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
    "go.opentelemetry.io/otel/trace"
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

var tracer trace.Tracer

func initTracer() func() {
    ctx := context.Background()
    
    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("jaeger-collector:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        log.Fatalf("failed to create exporter: %v", err)
    }
    
    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceName("payment-service"),
            semconv.ServiceVersion("1.0.0"),
            semconv.DeploymentEnvironment("production"),
        ),
    )
    if err != nil {
        log.Fatalf("failed to create resource: %v", err)
    }
    
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(sdktrace.AlwaysSample()),
    )
    
    otel.SetTracerProvider(tp)
    tracer = tp.Tracer("payment-service")
    
    return func() {
        if err := tp.Shutdown(ctx); err != nil {
            log.Printf("Error shutting down tracer provider: %v", err)
        }
    }
}

func processPayment(ctx context.Context, orderID string, amount float64) error {
    ctx, span := tracer.Start(ctx, "process_payment")
    defer span.End()
    
    span.SetAttributes(
        attribute.String("order.id", orderID),
        attribute.Float64("payment.amount", amount),
    )
    
    // Nested span for external API call
    ctx, apiSpan := tracer.Start(ctx, "payment_gateway_call")
    result, err := callPaymentGateway(ctx, amount)
    if err != nil {
        apiSpan.RecordError(err)
        apiSpan.SetStatus(codes.Error, err.Error())
        return err
    }
    apiSpan.SetAttributes(attribute.String("gateway.transaction_id", result.ID))
    apiSpan.End()
    
    span.AddEvent("payment_processed", trace.WithAttributes(
        attribute.String("transaction.id", result.ID),
    ))
    
    return nil
}

func main() {
    cleanup := initTracer()
    defer cleanup()
    
    // Wrap HTTP handler with tracing
    handler := otelhttp.NewHandler(http.HandlerFunc(paymentHandler), "payment")
    http.Handle("/pay", handler)
    
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Java (OpenTelemetry)

```java
// build.gradle
// implementation 'io.opentelemetry:opentelemetry-api:1.33.0'
// implementation 'io.opentelemetry:opentelemetry-sdk:1.33.0'
// implementation 'io.opentelemetry:opentelemetry-exporter-otlp:1.33.0'
// implementation 'io.opentelemetry.instrumentation:opentelemetry-instrumentation-annotations:1.33.0'

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.context.Scope;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.semconv.resource.attributes.ResourceAttributes;

public class TracingExample {
    private static final Tracer tracer;
    
    static {
        Resource resource = Resource.getDefault()
            .merge(Resource.create(Attributes.of(
                ResourceAttributes.SERVICE_NAME, "inventory-service",
                ResourceAttributes.SERVICE_VERSION, "1.0.0"
            )));
        
        OtlpGrpcSpanExporter exporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://jaeger-collector:4317")
            .build();
        
        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .addSpanProcessor(BatchSpanProcessor.builder(exporter).build())
            .setResource(resource)
            .build();
        
        OpenTelemetry openTelemetry = OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .build();
        
        tracer = openTelemetry.getTracer("inventory-service");
    }
    
    public void checkInventory(String productId, int quantity) {
        Span span = tracer.spanBuilder("check_inventory").startSpan();
        
        try (Scope scope = span.makeCurrent()) {
            span.setAttribute("product.id", productId);
            span.setAttribute("quantity.requested", quantity);
            
            // Database query span
            Span dbSpan = tracer.spanBuilder("database_query").startSpan();
            try (Scope dbScope = dbSpan.makeCurrent()) {
                int available = database.getStock(productId);
                dbSpan.setAttribute("quantity.available", available);
            } finally {
                dbSpan.end();
            }
            
            span.addEvent("inventory_checked");
            span.setStatus(StatusCode.OK);
            
        } catch (Exception e) {
            span.setStatus(StatusCode.ERROR, e.getMessage());
            span.recordException(e);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No traces in UI | SDK not sending | Check collector endpoint, firewall |
| Missing spans | Sampling too aggressive | Increase sampling rate |
| High latency | Storage backend slow | Scale Elasticsearch, add replicas |
| Collector OOM | Queue overflow | Increase memory, add collectors |
| Broken traces | Context not propagated | Check propagator configuration |
| UI shows errors | Query service issues | Check ES connectivity |

### Diagnostic Commands

```bash
# Check collector health
curl http://jaeger-collector:14269/

# Check query health  
curl http://jaeger-query:16687/

# View collector metrics
curl http://jaeger-collector:14269/metrics | grep jaeger_collector

# Check Elasticsearch indices
curl http://elasticsearch:9200/_cat/indices/jaeger*?v

# View trace by ID via API
curl "http://jaeger-query:16686/api/traces/abc123def456"

# Search traces via API
curl "http://jaeger-query:16686/api/traces?service=user-service&limit=10"

# Get services list
curl http://jaeger-query:16686/api/services
```

### Debug Logging

```bash
# Enable debug logging
JAEGER_COLLECTOR_LOG_LEVEL=debug

# Python SDK debug
OTEL_LOG_LEVEL=debug

# Node.js SDK debug
OTEL_LOG_LEVEL=debug

# Go SDK debug
OTEL_LOG_LEVEL=debug
```

## Best Practices

### Instrumentation Guidelines

1. **Use semantic conventions** - Follow OpenTelemetry naming standards
2. **Add meaningful attributes** - Include business context
3. **Record errors properly** - Use recordException() and set error status
4. **Propagate context** - Ensure trace context crosses service boundaries
5. **Keep spans focused** - One span per logical operation
6. **Use span events** - For significant milestones within a span

### Sampling Strategy

1. **Development** - Sample 100% (`AlwaysSample`)
2. **Staging** - Sample 50-100%
3. **Production** - Sample 1-10% or use adaptive sampling
4. **Critical paths** - Always sample (payments, errors)
5. **Health checks** - Never sample

### Security Checklist

- [ ] Enable TLS for collector endpoints
- [ ] Use authentication for collector
- [ ] Sanitize PII from span attributes
- [ ] Limit trace retention period
- [ ] Restrict Jaeger UI access
- [ ] Enable audit logging

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
