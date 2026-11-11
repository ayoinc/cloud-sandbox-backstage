"""OpenTelemetry set-up.

Tracing is configured with the standard ``OTEL_*`` environment variables and is
exported only when ``OTEL_EXPORTER_OTLP_ENDPOINT`` (or the traces-specific
variable) is set. Without it the spans created in the agent loop are no-ops.

The spans follow the OpenTelemetry semantic conventions for generative AI:
``invoke_agent``, ``chat <model>`` and ``execute_tool <name>``, with token
usage as attributes. Prompts, answers and tool arguments are not recorded.
"""

import os

from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from agent import __version__

SERVICE_NAME = "${{ values.name }}"


def tracing_enabled() -> bool:
    if os.environ.get("OTEL_SDK_DISABLED", "").lower() == "true":
        return False
    return bool(
        os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")
        or os.environ.get("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT")
    )


def setup_telemetry(app: FastAPI) -> TracerProvider | None:
    """Export traces over OTLP/HTTP and instrument the HTTP server, if enabled."""
    if not tracing_enabled():
        return None
    # OTEL_SERVICE_NAME and OTEL_RESOURCE_ATTRIBUTES take precedence over these.
    resource = Resource.create({"service.name": SERVICE_NAME, "service.version": __version__})
    provider = TracerProvider(resource=resource)
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(provider)
    FastAPIInstrumentor.instrument_app(app, excluded_urls="healthz,readyz")
    return provider
