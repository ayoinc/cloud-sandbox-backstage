"""Prometheus metrics of HTTP requests, served on /metrics."""

from fastapi import FastAPI
from prometheus_client import CollectorRegistry, GCCollector, PlatformCollector, ProcessCollector
from prometheus_fastapi_instrumentator import Instrumentator


def setup_metrics(app: FastAPI) -> None:
    """Record request counts and durations and expose them in the Prometheus text format.

    Each application owns its registry, so creating several applications in one process
    does not register the same metric twice.
    """
    registry = CollectorRegistry()
    ProcessCollector(registry=registry)
    PlatformCollector(registry=registry)
    GCCollector(registry=registry)
    instrumentator = Instrumentator(registry=registry, excluded_handlers=["/metrics"])
    instrumentator.instrument(app).expose(app, include_in_schema=False)
