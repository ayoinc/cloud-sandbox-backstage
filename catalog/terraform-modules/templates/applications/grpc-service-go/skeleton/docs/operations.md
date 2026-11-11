# Operations

## Configuration

The server is configured with environment variables.

| Variable | Default | Meaning |
| --- | --- | --- |
| `GRPC_ADDR` | `:50051` | Address the gRPC server listens on. |
| `GRPC_REFLECTION` | `true` | Serve the reflection API used by grpcurl and similar tools. |
{% if values.enableAuth %}
| `TLS_CERT_FILE` | | PEM file with the server certificate. TLS is on when this and the key are set. |
| `TLS_KEY_FILE` | | PEM file with the private key of the certificate. |
{% endif %}
{% if values.enableMTLS %}
| `TLS_CLIENT_CA_FILE` | | PEM file with the CA of the client certificates. When set, clients must present a certificate signed by it. |
{% endif %}
{% if values.enableInterceptors %}
| `AUTH_TOKEN` | | When set, every call except health checks must send `authorization: Bearer <token>`. |
{% endif %}
{% if values.enableMetrics %}
| `METRICS_ADDR` | `:9090` | Address of the Prometheus endpoint (`/metrics`). Empty turns it off. |
{% endif %}
{% if values.enableTracing %}
| `OTEL_EXPORTER_OTLP_ENDPOINT` | | OTLP/gRPC collector, for example `http://otel-collector:4317`. Tracing is off without it. The other `OTEL_EXPORTER_OTLP_*` variables apply too. |
{% endif %}
{% if values.enableAuth %}

## TLS

Without `TLS_CERT_FILE` and `TLS_KEY_FILE` the server logs a warning and serves
plaintext, which is meant for local development only.

```sh
make certs     # write a development CA and certificates to certs/
make run-tls   # serve with them
{% if values.enableMTLS %}
grpcurl -cacert certs/ca.crt -cert certs/client.crt -key certs/client.key localhost:50051 list
{% else %}
grpcurl -cacert certs/ca.crt localhost:50051 list
{% endif %}
```
{% endif %}
{% if values.enableInterceptors %}

## Interceptors

Every call passes through these interceptors, in this order:

1. Logging: one JSON log line per call with the method, status code and duration.
2. Recovery: a panic in a handler becomes an `Internal` error instead of a crash.
3. Authentication, only when `AUTH_TOKEN` is set.
{% endif %}
{% if values.enableMetrics or values.enableTracing %}

## Observability

{% if values.enableMetrics %}
`/metrics` on port 9090 serves the `grpc_server_*` counters and the handling
time histogram for every method, with the Go runtime and process metrics.
{% endif %}
{% if values.enableTracing %}
Every call produces an OpenTelemetry span, and the W3C trace context of the
caller is continued. Spans are exported once an OTLP endpoint is configured.
{% endif %}
{% endif %}

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests:

| Job | What it checks |
| --- | --- |
| Lint and test | `buf lint`, `buf format`, breaking API changes (pull requests), `go mod tidy`, golangci-lint, `go test -race`, `go build`. |
| Validate Kubernetes manifests | `deploy/k8s` against the Kubernetes${{ ' and Istio' if values.serviceMesh == 'istio' }} schemas. |
| Build and smoke-test the image | Builds the image, starts it and calls it over gRPC. |

The pipeline needs no secrets. `.github/workflows/release.yaml` publishes the
image to `ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` when a tag such as
`v${{ values.serviceVersion }}` is pushed.

## Deployment

`deploy/k8s` holds a Deployment and a Service, tied together with Kustomize:

```sh
kubectl apply -k deploy/k8s
```

{% if values.enableAuth %}
The Deployment mounts the secret `${{ values.serviceName }}-tls` (type
`kubernetes.io/tls`${{ ', with the client CA in `ca.crt`' if values.enableMTLS }}) on `/etc/tls`. Create it before the first rollout, for
example with cert-manager.

{% endif %}
{% if values.enableInterceptors %}
To require a bearer token, create the secret `${{ values.serviceName }}-auth` with
the key `token`.

{% endif %}
{% if values.serviceMesh == 'istio' %}
`deploy/k8s/istio.yaml` puts the pods in the Istio mesh: only workloads in the
mesh may call the service, over mutual TLS, and requests are balanced per
request.
{% elif values.serviceMesh == 'linkerd' %}
The pods carry the `linkerd.io/inject: enabled` annotation, so Linkerd adds its
proxy and secures and balances the calls between meshed workloads.
{% else %}
gRPC keeps connections open, so a plain Kubernetes Service balances per
connection, not per request. Use client-side balancing or a service mesh when
that matters.
{% endif %}
