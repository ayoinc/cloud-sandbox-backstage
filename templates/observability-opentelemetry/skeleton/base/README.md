# ${{ values.name }}

${{ values.description }}

Configuration of an [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
(contrib distribution, version 0.165.0), deployed with
{%- if values.deployment == 'kubernetes-helm' %} the official Helm chart as a gateway in the `${{ values.namespace }}` namespace.
{%- else %} Docker Compose on a single host.
{%- endif %}

## Pipelines

| Signal | Receivers | Processors | Exporter |
| --- | --- | --- | --- |
| Traces | `otlp`{% if values.receive_legacy_tracing %}, `jaeger`, `zipkin`{% endif %} | `memory_limiter`, `resource_detection`, `resource/environment`{% if values.scrub_sensitive_attributes %}, `attributes/scrub`{% endif %}{% if values.tail_sampling %}, `tail_sampling`{% endif %}, `batch` | `${{ values.exporter_protocol }}` |
| Metrics | `otlp`{% if values.receive_prometheus %}, `prometheus`{% endif %} | `memory_limiter`, `resource_detection`, `resource/environment`, `batch` | `{% if values.metrics_exporter == 'prometheus-remote-write' %}prometheus_remote_write{% else %}${{ values.exporter_protocol }}{% endif %}` |
| Logs | `otlp` | `memory_limiter`, `resource_detection`, `resource/environment`{% if values.scrub_sensitive_attributes %}, `attributes/scrub`{% endif %}, `batch` | `${{ values.exporter_protocol }}` |

Everything is in one file, [`collector/config.yaml`](collector/config.yaml).

## Ports

| Port | Purpose |
| --- | --- |
| 4317 | OTLP over gRPC |
| 4318 | OTLP over HTTP |
{%- if values.receive_legacy_tracing %}
| 14250, 14268 | Jaeger gRPC and Thrift over HTTP |
| 9411 | Zipkin |
{%- endif %}
| 13133 | Health check |
| 8888 | The collector's own metrics (Prometheus format) |

## Backend endpoint and credentials

They are environment variables, read when the collector starts, and are not
stored in this repository.

| Variable | Meaning |
| --- | --- |
| `OTLP_ENDPOINT` | {% if values.exporter_protocol == 'otlp_http' %}Base URL of the backend's OTLP/HTTP endpoint{% else %}Host and port of the backend's OTLP/gRPC endpoint{% endif %} |
{%- if values.exporter_protocol == 'otlp_grpc' %}
| `OTLP_INSECURE` | `true` disables TLS to the backend. Default `false` |
{%- endif %}
| `OTLP_AUTHORIZATION` | Value of the `Authorization` header, or empty |
{%- if values.metrics_exporter == 'prometheus-remote-write' %}
| `PROMETHEUS_REMOTE_WRITE_ENDPOINT` | Remote-write URL, including the path |
| `PROMETHEUS_REMOTE_WRITE_AUTHORIZATION` | Value of the `Authorization` header, or empty |
{%- endif %}
| `DEPLOYMENT_ENVIRONMENT` | Added as `deployment.environment.name` where the sender did not set it |

## Change the configuration

1. Edit `collector/config.yaml`.
2. Check it with the collector itself, then run it end to end against a
   stand-in backend. Both need only Docker:

   ```sh
   scripts/validate.sh
   scripts/smoke-test.sh
   ```

3. Push. CI runs the same checks{% if values.deployment == 'kubernetes-helm' %}, renders the Helm release and validates the manifests{% else %} and starts the Compose deployment{% endif %}.

A component must be defined **and** listed in a pipeline to take effect, and
the order of processors matters: `memory_limiter` first, `batch` last.

## Deploy
{% if values.deployment == 'kubernetes-helm' %}
Requirements: `kubectl` access to the cluster and Helm 4.

```sh
cp .env.example .env          # fill in the endpoint and credentials
scripts/create-secret.sh      # creates the Secret ${{ values.name }}-backend
scripts/deploy.sh             # helm upgrade --install, waits for the rollout
```

`scripts/deploy.sh --dry-run=server` shows what would change. The chart
version and the collector image are pinned in the scripts and in
`helm/values.yaml`.

Applications send to
`${{ values.name }}-opentelemetry-collector.${{ values.namespace }}.svc.cluster.local`, port 4317
(gRPC) or 4318 (HTTP):

```sh
OTEL_EXPORTER_OTLP_ENDPOINT=http://${{ values.name }}-opentelemetry-collector.${{ values.namespace }}.svc.cluster.local:4318
```

Where a secrets operator is available, let it create the
`${{ values.name }}-backend` Secret with the keys of `.env.example` instead of
running `scripts/create-secret.sh`.
{%- else %}
Requirements: Docker with the Compose plugin.

```sh
cp .env.example .env          # fill in the endpoint and credentials
docker compose up --detach
curl http://127.0.0.1:13133/  # health
```

The ports are published on the loopback interface only. Applications on the
same host send to `http://127.0.0.1:4318` (HTTP) or `127.0.0.1:4317` (gRPC).
To receive from other hosts, publish the OTLP ports on a private address and
terminate TLS in front of the collector, or configure `tls` on the OTLP
receiver.
{%- endif %}

## Upgrade the collector

The image tag `0.165.0` appears in `scripts/`, `test/` and the deployment
files. Change it everywhere in one commit, read the
[release notes](https://github.com/open-telemetry/opentelemetry-collector-contrib/releases)
for breaking changes, and let CI validate the configuration against the new
version.
