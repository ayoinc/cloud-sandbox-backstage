# OpenTelemetry Collector Configuration

Creates a repository that holds the configuration of an OpenTelemetry
Collector, the files to deploy it, and CI that proves the configuration works
before it is deployed.

## What you get

| Path                                    | Content                                                                                                 |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `collector/config.yaml`                 | The collector configuration, built from the chosen receivers, processors and exporters                  |
| `scripts/validate.sh`                   | Validates the configuration with the collector binary itself                                            |
| `scripts/smoke-test.sh`, `test/`        | Runs the collector with a stand-in backend, sends traces, metrics and logs, and checks that they arrive |
| `helm/values.yaml`, `scripts/deploy.sh` | Kubernetes: values of the official Helm chart, and the install command with pinned versions             |
| `docker-compose.yaml`                   | Docker Compose: a hardened single-host deployment                                                       |
| `.env.example`                          | The environment variables that carry the backend endpoint and credentials                               |
| `.github/workflows/`                    | Lint, validation, smoke test, deployment check and a Trivy scan on every push                           |

## Parameters

| Parameter                   | Meaning                                                                           |
| --------------------------- | --------------------------------------------------------------------------------- |
| Deployment Method           | Kubernetes with the official Helm chart (a gateway Deployment), or Docker Compose |
| Kubernetes Namespace        | Helm only                                                                         |
| Scrape Prometheus Endpoints | Adds the `prometheus` receiver to the metrics pipeline                            |
| Accept Jaeger and Zipkin    | Adds the `jaeger` and `zipkin` receivers to the traces pipeline                   |
| Remove Sensitive Attributes | Adds a processor that deletes captured credentials from spans and logs            |
| Tail Sampling of Traces     | Keeps traces with errors or high latency and 10% of the rest                      |
| Backend Protocol            | OTLP over HTTP or gRPC                                                            |
| Metrics Destination         | The OTLP backend, or a Prometheus remote-write endpoint                           |

OTLP is always received, and the `memory_limiter`, `resource_detection` and
`batch` processors are always present.

## Design choices

- **One configuration file.** The Helm chart receives `collector/config.yaml`
  as its `alternateConfig` value, so what CI validates is what runs.
- **No endpoints or credentials in Git.** The configuration refers to
  environment variables; the template does not ask for them.
- **Validated by the collector.** `otelcol validate` rejects unknown
  components and keys for the pinned version, and the smoke test shows that
  the pipelines carry data.
- **Not exposed by default.** Compose publishes on the loopback interface;
  the Kubernetes Service is `ClusterIP` behind a NetworkPolicy.

## After creation

1. Copy `.env.example` to `.env` and fill in the backend endpoint.
2. Deploy with the commands in the repository's README.
3. Point services at the collector with `OTEL_EXPORTER_OTLP_ENDPOINT`.
