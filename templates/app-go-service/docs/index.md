# Go Service Template

Creates a Go HTTP service in a new GitHub repository: structured JSON logs with
`log/slog`, OpenTelemetry tracing, graceful shutdown, tests, a distroless
container image and a pipeline that passes on the first push.

## Form

| Field        | Effect                                                           |
| ------------ | ---------------------------------------------------------------- |
| Project Name | Name of the service, the repository and the catalog entry        |
| Description  | README, documentation and catalog entry                          |
| Owner        | Owner of the catalog entry                                       |
| Router       | `net/http` ServeMux (no dependency) or chi                       |
| Port         | Default of `PORT`; port exposed by the image                     |
| Repository   | GitHub repository to create; its path becomes the Go module path |

## What is generated

- `cmd/server`: entry point with signal handling and graceful shutdown
- `internal/config`: settings read from the environment, validated at start
- `internal/httpserver`: routes, JSON handlers, request logging and panic recovery
- `internal/store`: in-memory repository behind an interface, ready to be replaced
- `internal/telemetry`: OpenTelemetry tracer provider exporting OTLP over HTTP,
  enabled by setting `OTEL_EXPORTER_OTLP_ENDPOINT`
- Tests for every endpoint and for the configuration, run with the race detector
- `.golangci.yml` for golangci-lint v2
- `Dockerfile`: static binary on `gcr.io/distroless/static`, running as non-root
- `.github/workflows/ci.yaml`: lint, tests, vulnerability check, image build
  with a start check, publication to the GitHub Container Registry on `main`
- `.github/dependabot.yml`: weekly updates of modules, base images and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured: the image is published with the
workflow's own token.

## Template layout

| Directory                | Used               |
| ------------------------ | ------------------ |
| `skeleton/base`          | Always             |
| `skeleton/router-stdlib` | Router is ServeMux |
| `skeleton/router-chi`    | Router is chi      |
