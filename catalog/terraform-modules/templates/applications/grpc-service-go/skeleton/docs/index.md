# ${{ values.serviceName }}

${{ values.description }}

`${{ values.serviceName }}` is a gRPC service written in Go. It exposes
`${{ values.pkg }}.v1.${{ values.serviceType }}` on port 50051.

## Features

| Feature | State |
| --- | --- |
| Unary calls | ${{ 'Yes' if values.enableUnary else 'No' }} |
| Server streaming | ${{ 'Yes' if values.enableServerStreaming else 'No' }} |
| Client streaming | ${{ 'Yes' if values.enableClientStreaming else 'No' }} |
| Bidirectional streaming | ${{ 'Yes' if values.enableBidirectional else 'No' }} |
| TLS | ${{ 'Yes, when a certificate is configured' if values.enableAuth else 'No' }} |
| Mutual TLS | ${{ 'Yes, when a client CA is configured' if values.enableMTLS else 'No' }} |
| Interceptors (logging, recovery, bearer token) | ${{ 'Yes' if values.enableInterceptors else 'No' }} |
| Prometheus metrics | ${{ 'Yes, on :9090/metrics' if values.enableMetrics else 'No' }} |
| OpenTelemetry tracing | ${{ 'Yes, when an OTLP endpoint is configured' if values.enableTracing else 'No' }} |
| gRPC health checks | ${{ 'Yes' if values.enableHealthChecks else 'No' }} |
| Service mesh | ${{ 'Istio' if values.serviceMesh == 'istio' else ('Linkerd' if values.serviceMesh == 'linkerd' else 'None') }} |

## Run it

```sh
make test   # generate the Go code of the proto files and run the tests
make run    # serve on :50051
```

You need Go and [buf](https://buf.build/docs/installation). The code generated
from the proto files lives in `gen/` and is not committed: `make` targets
generate it when needed.

## Where to go next

- [API](api.md): the methods and how to call them.
- [Operations](operations.md): configuration, pipeline and deployment.
