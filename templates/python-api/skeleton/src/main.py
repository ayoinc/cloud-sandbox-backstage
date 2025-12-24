"""${{ values.name }} - FastAPI Application Entry Point."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
{%- if values.enable_metrics %}
from prometheus_fastapi_instrumentator import Instrumentator
{%- endif %}
{%- if values.enable_logging %}
import structlog

from ${{ values.name | replace('-', '_') }}.core.logging import configure_logging

configure_logging()
logger = structlog.get_logger()
{%- endif %}

from ${{ values.name | replace('-', '_') }}.api.routes import router as api_router
from ${{ values.name | replace('-', '_') }}.config import settings
{%- if values.database_type in ['postgresql', 'mysql'] %}
from ${{ values.name | replace('-', '_') }}.core.database import init_db, close_db
{%- endif %}


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan handler for startup and shutdown events."""
{%- if values.enable_logging %}
    logger.info("Starting ${{ values.name }}", version=settings.VERSION)
{%- endif %}
{%- if values.database_type in ['postgresql', 'mysql'] %}
    await init_db()
{%- endif %}
    yield
{%- if values.database_type in ['postgresql', 'mysql'] %}
    await close_db()
{%- endif %}
{%- if values.enable_logging %}
    logger.info("Shutting down ${{ values.name }}")
{%- endif %}


app = FastAPI(
    title=settings.PROJECT_NAME,
    description=settings.DESCRIPTION,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json" if settings.OPENAPI_ENABLED else None,
    docs_url=f"{settings.API_V1_PREFIX}/docs" if settings.OPENAPI_ENABLED else None,
    redoc_url=f"{settings.API_V1_PREFIX}/redoc" if settings.OPENAPI_ENABLED else None,
    default_response_class=ORJSONResponse,
    lifespan=lifespan,
)

# CORS Middleware
{%- if values.enable_cors %}
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
{%- endif %}

{%- if values.enable_metrics %}
# Prometheus Metrics
Instrumentator().instrument(app).expose(app, endpoint="/metrics")
{%- endif %}

# Include API routes
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.get("/health", tags=["Health"])
async def health_check() -> dict[str, str]:
    """Health check endpoint for liveness probes."""
    return {"status": "healthy"}


@app.get("/health/ready", tags=["Health"])
async def readiness_check() -> dict[str, str | bool]:
    """Readiness check endpoint for readiness probes."""
{%- if values.database_type in ['postgresql', 'mysql'] %}
    from ${{ values.name | replace('-', '_') }}.core.database import check_db_connection
    
    db_healthy = await check_db_connection()
    return {
        "status": "ready" if db_healthy else "not_ready",
        "database": db_healthy,
    }
{%- else %}
    return {"status": "ready"}
{%- endif %}


def cli() -> None:
    """CLI entry point for running the application."""
    import uvicorn
    
    uvicorn.run(
        "${{ values.name | replace('-', '_') }}.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="debug" if settings.DEBUG else "info",
    )


if __name__ == "__main__":
    cli()
