# ${{ values.name }}

${{ values.description }}

## Role

The collector sits between the services that produce telemetry and the
backend that stores it. Services send OTLP to it and know nothing about the
backend; the collector adds context, removes what must not leave, batches,
retries, and holds the backend credentials in one place.

```text
services ── OTLP ──> ${{ values.name }} ── ${{ values.exporter_protocol }} ──> backend
```

## Components

### Receivers

| Receiver | Purpose |
| --- | --- |
| `otlp` | Traces, metrics and logs from OpenTelemetry SDKs and other collectors, on 4317 (gRPC) and 4318 (HTTP) |
{%- if values.receive_legacy_tracing %}
| `jaeger`, `zipkin` | Traces from services that have not moved to OTLP |
{%- endif %}
{%- if values.receive_prometheus %}
| `prometheus` | Scrapes metrics endpoints. It starts with one job, the collector itself; add jobs under `scrape_configs` |
{%- endif %}

### Processors, in pipeline order

| Processor | Purpose |
| --- | --- |
| `memory_limiter` | Refuses data at 80% of the container's memory limit, so the collector pushes back instead of being killed |
| `resource_detection` | Adds the host the telemetry passed through |
| `resource/environment` | Adds `deployment.environment.name` |
{%- if values.scrub_sensitive_attributes %}
| `attributes/scrub` | Deletes captured credentials: authorization, cookie and API-key headers, and URL query strings |
{%- endif %}
{%- if values.tail_sampling %}
| `tail_sampling` | Keeps all traces with an error or longer than a second, and 10% of the rest |
{%- endif %}
| `batch` | Sends up to 8192 items per request, or every five seconds |

### Exporters

| Exporter | Purpose |
| --- | --- |
| `${{ values.exporter_protocol }}` | The backend. Gzip compression, a queue of 2000 batches, retries for up to five minutes |
{%- if values.metrics_exporter == 'prometheus-remote-write' %}
| `prometheus_remote_write` | Metrics, to a Prometheus-compatible store. Resource attributes become labels |
{%- endif %}

## Reliability

- **Back-pressure.** When the backend is slow or down, batches wait in the
  sending queue and are retried. When the queue is full or memory is short,
  the collector refuses new data and well-behaved senders retry.
- **Data loss.** The queue is in memory: telemetry in it is lost if the
  collector restarts during a backend outage. Add the `file_storage` extension
  and a volume to persist the queue if that matters.
{%- if values.deployment == 'kubernetes-helm' %}
- **Availability.** {% if values.tail_sampling %}One replica, because tail sampling needs whole traces in one instance.{% else %}Two replicas behind a ClusterIP Service, spread over nodes, with a PodDisruptionBudget.{% endif %}
{%- endif %}
{%- if values.tail_sampling %}
- **Tail sampling** holds every trace in memory for ten seconds. Size the
  memory limit for `num_traces`, and do not scale this collector out without a
  load-balancing tier in front that routes by trace id.
{%- endif %}

## Monitoring the collector

Its own metrics are on port 8888{% if values.receive_prometheus %} and are scraped by its `prometheus` receiver, so they arrive at the backend with everything else{% endif %}.

| Metric | Watch for |
| --- | --- |
| `otelcol_receiver_refused_spans` (and `_metric_points`, `_log_records`) | Above zero: the memory limiter is refusing data |
| `otelcol_exporter_send_failed_spans` | Above zero: the backend rejects or is unreachable |
| `otelcol_exporter_queue_size` against `otelcol_exporter_queue_capacity` | A queue that fills up |
| `otelcol_processor_batch_batch_send_size` | Batch sizes |
| `otelcol_process_memory_rss` | Memory against the limit |

## Security

- The backend endpoint and credentials are environment variables
  {%- if values.deployment == 'kubernetes-helm' %} from the Secret `${{ values.name }}-backend`{% else %} from `.env`, which Git ignores{% endif %}.
{%- if values.deployment == 'kubernetes-helm' %}
- The pod runs as non-root with a read-only root filesystem and no
  capabilities; a NetworkPolicy limits what can reach it; the Service is
  `ClusterIP`.
{%- else %}
- The container has a read-only filesystem, no capabilities and
  `no-new-privileges`; its ports are bound to the loopback interface.
{%- endif %}
- The OTLP receivers accept unauthenticated traffic from the network they are
  reachable on. Keep that network private, or add TLS and an authenticator
  extension to the receivers.
{%- if values.scrub_sensitive_attributes %}
- Scrubbing is a safety net, not a guarantee: it removes known attribute
  names. Do not record secrets in telemetry in the first place.
{%- endif %}

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Nothing arrives at the backend | Collector logs for export errors; `OTLP_ENDPOINT` and `OTLP_AUTHORIZATION` |
| The collector does not start | `scripts/validate.sh`; an unset environment variable shows as an empty endpoint |
| Senders get `RESOURCE_EXHAUSTED` or HTTP 503 | The memory limiter is refusing data: raise the memory limit or scale out |
| Unexpected attributes are missing | A processor removed them; add the `debug` exporter to a pipeline temporarily to see what leaves |
