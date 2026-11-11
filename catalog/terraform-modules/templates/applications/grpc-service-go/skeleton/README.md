# ${{ values.serviceName }}

${{ values.description }}

A gRPC service written in Go. The API is defined in
[`proto/${{ values.pkg }}/v1/service.proto`](proto/${{ values.pkg }}/v1/service.proto).

## Quick start

You need Go (the version in `go.mod`) and [buf](https://buf.build/docs/installation).

```sh
make test   # generate the Go code of the proto files and run the tests
make run    # serve on :50051
```

Call the running server with [grpcurl](https://github.com/fullstorydev/grpcurl):

```sh
grpcurl -plaintext localhost:50051 list
{% if values.enableUnary %}
grpcurl -plaintext -d '{"name": "widget"}' localhost:50051 ${{ values.pkg }}.v1.${{ values.serviceType }}/CreateItem
{% endif %}
{% if values.enableServerStreaming %}
grpcurl -plaintext localhost:50051 ${{ values.pkg }}.v1.${{ values.serviceType }}/ListItems
{% endif %}
```

Run `make` to list every target.

## What is in the repository

| Path | Content |
| --- | --- |
| `proto/` | The API definition. `make generate` writes its Go code to `gen/`, which is not committed. |
| `cmd/server` | The entry point. |
| `internal/app` | Builds the gRPC server from the parts below and runs it. |
| `internal/server` | The service implementation and its in-memory store. |
{% if values.enableInterceptors %}
| `internal/interceptors` | Request logging, panic recovery and bearer token authentication. |
{% endif %}
{% if values.enableAuth %}
| `internal/tlsconfig` | TLS${{ ' and mutual TLS' if values.enableMTLS }} for the server. |
{% endif %}
{% if values.enableMetrics %}
| `internal/metrics` | Prometheus metrics, served on `:9090/metrics`. |
{% endif %}
{% if values.enableTracing %}
| `internal/tracing` | OpenTelemetry tracing over OTLP. |
{% endif %}
| `deploy/k8s` | Kubernetes manifests${{ ' with the Istio policies' if values.serviceMesh == 'istio' }}${{ ' with Linkerd injection' if values.serviceMesh == 'linkerd' }}. |
| `docs/` | The documentation shown in the developer portal. |

## Pipeline

`.github/workflows/ci.yaml` runs on every push to `main` and on pull requests.
It lints the proto files, generates the code, checks that `go.mod` is tidy,
runs golangci-lint and the tests with the race detector, validates the
Kubernetes manifests, builds the container image and calls the running
container over gRPC. Pull requests are also checked for breaking API changes.
It needs no secrets.

`.github/workflows/release.yaml` publishes the image to
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` when you push a tag such as `v${{ values.serviceVersion }}`.

See [docs/operations.md](docs/operations.md) for configuration and deployment.
