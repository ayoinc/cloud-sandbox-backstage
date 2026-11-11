# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Language   | Go 1.27                                                                             |
| Router     | {% if values.router == 'chi' %}chi v5{% else %}`net/http` ServeMux{% endif %}      |
| Port       | `${{ values.port }}`                                                                |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/ci.yaml     # Lint, tests, vulnerability check, image
├── cmd/server/main.go        # Entry point, signals, graceful shutdown
├── internal/
│   ├── config/               # Settings read from the environment
│   ├── httpserver/           # Routes, handlers, middleware
│   ├── store/                # Store interface and in-memory implementation
│   └── telemetry/            # OpenTelemetry tracer provider
├── .golangci.yml             # golangci-lint v2 configuration
├── Dockerfile                # Static binary on a distroless base
├── Makefile
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Request handling

Every request passes through, in order: OpenTelemetry instrumentation
(`otelhttp`), request logging and panic recovery. Each request is logged as one
JSON line with method, path, status, duration and, when the request is traced,
its `trace_id`. Probe requests are logged at `debug` level and are not traced.

Handlers depend on the `store.Store` interface. The generated implementation
keeps items in memory; implement the interface on your database and pass it to
`httpserver.New` in `cmd/server/main.go`.

## Shutdown

On `SIGINT` or `SIGTERM` the service reports not ready on `/health/ready`,
stops accepting connections, lets in-flight requests finish for up to
`SHUTDOWN_TIMEOUT`, then flushes pending spans.

## Tracing

Set `OTEL_EXPORTER_OTLP_ENDPOINT` (for example `http://localhost:4318`) to
export spans over OTLP/HTTP. The other standard `OTEL_*` variables, such as
`OTEL_RESOURCE_ATTRIBUTES` and `OTEL_EXPORTER_OTLP_HEADERS`, apply. W3C trace
context and baggage are propagated whether or not spans are exported.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job                 | What it does                                                         |
| ------------------- | -------------------------------------------------------------------- |
| Lint                | `go mod tidy -diff` and golangci-lint                                |
| Test                | Tests with the race detector, then starts the service and calls it   |
| Vulnerability check | govulncheck report; does not fail the build                          |
| Image               | Hadolint, image build, start check, Trivy report, publish to GHCR    |

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image runs as user 65532 on `gcr.io/distroless/static`, which has no shell.
Use the HTTP probes of your orchestrator on `/health/live` and `/health/ready`.

## References

- [Go documentation](https://go.dev/doc/)
- [log/slog](https://pkg.go.dev/log/slog)
- [OpenTelemetry for Go](https://opentelemetry.io/docs/languages/go/)
- [golangci-lint](https://golangci-lint.run/)
