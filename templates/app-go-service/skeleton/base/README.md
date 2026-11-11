# ${{ values.name }}

${{ values.description }}

Go HTTP service ({% if values.router == 'chi' %}chi{% else %}`net/http` ServeMux{% endif %}) with structured logs, OpenTelemetry tracing and graceful shutdown.

## Getting started

Requires Go 1.27 or later.

```bash
go run ./cmd/server
curl http://localhost:${{ values.port }}/health
```

## Commands

- `make run` starts the service
- `make test` runs the tests with the race detector
- `make lint` runs golangci-lint (v2)
- `make build` builds a static binary in `bin/`
- `make image` builds the container image

## Endpoints

| Method | Path              | Description                              |
| ------ | ----------------- | ---------------------------------------- |
| GET    | `/health`         | Service status, version and environment  |
| GET    | `/health/live`    | Liveness probe                           |
| GET    | `/health/ready`   | Readiness probe, 503 while shutting down |
| GET    | `/api/items`      | List items                               |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/{id}` | One item                                 |

## Configuration

| Variable                      | Default               | Purpose                                         |
| ----------------------------- | --------------------- | ----------------------------------------------- |
| `PORT`                        | `${{ values.port }}`  | Port the service listens on                     |
| `APP_ENV`                     | `development`         | Environment name reported by `/health`          |
| `LOG_LEVEL`                   | `info`                | `debug`, `info`, `warn` or `error`              |
| `SHUTDOWN_TIMEOUT`            | `15s`                 | Time in-flight requests get to finish           |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | unset                 | OTLP/HTTP collector; unset disables the export  |

Invalid values stop the service at start with a message naming the variable.

## Owner

${{ values.owner }}
