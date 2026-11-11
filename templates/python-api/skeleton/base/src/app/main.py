{%- set lifespan = values.sql or values.enable_caching -%}
"""Application factory and the ASGI application served by uvicorn."""
{%- if lifespan %}

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
{%- endif %}

from fastapi import {% if values.auth_type != 'none' %}Depends, {% endif %}FastAPI
{%- if values.enable_cors %}
from fastapi.middleware.cors import CORSMiddleware
{%- endif %}

from app.api import {% if values.auth_type == 'jwt' %}auth, {% endif %}health, items
from app.api.health import ReadinessCheck
{%- if values.enable_caching %}
from app.cache import CachedItemRepository, create_cache
{%- endif %}
from app.config import Settings
{%- if values.sql %}
from app.db import Database, SqlItemRepository
{%- endif %}
{%- if values.enable_logging %}
from app.log import RequestLoggingMiddleware, configure_logging
{%- endif %}
{%- if not values.sql %}
from app.memory import InMemoryItemRepository
{%- endif %}
{%- if values.enable_metrics %}
from app.metrics import setup_metrics
{%- endif %}
{%- if values.enable_rate_limiting %}
from app.rate_limit import RateLimitMiddleware
{%- endif %}
from app.repository import ItemRepository
{%- if values.auth_type != 'none' %}
from app.security import require_auth
{%- endif %}
{%- if values.enable_security_headers %}
from app.security_headers import SecurityHeadersMiddleware
{%- endif %}
{%- if lifespan %}


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Release connections when the server shuts down."""
    yield
{%- if values.enable_caching %}
    await app.state.cache.close()
{%- endif %}
{%- if values.sql %}
    await app.state.database.dispose()
{%- endif %}
{%- endif %}


def create_app(settings: Settings | None = None) -> FastAPI:
    """Build the application. Nothing here opens a network connection."""
    settings = settings or Settings()
{%- if values.enable_logging %}
    configure_logging(settings.log_level)
{%- endif %}

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
{%- if not values.enable_docs %}
        docs_url=None,
        redoc_url=None,
        openapi_url=None,
{%- endif %}
{%- if lifespan %}
        lifespan=lifespan,
{%- endif %}
    )
    app.state.settings = settings
    readiness_checks: dict[str, ReadinessCheck] = {}
{%- if values.sql %}

    database = Database(settings.database_url)
    app.state.database = database
    readiness_checks["database"] = database.ping
    repository: ItemRepository = SqlItemRepository(database.sessions)
{%- else %}

    repository: ItemRepository = InMemoryItemRepository()
{%- endif %}
{%- if values.enable_caching %}

    cache = create_cache(settings.redis_url)
    app.state.cache = cache
    readiness_checks["cache"] = cache.ping
    repository = CachedItemRepository(repository, cache, settings.cache_ttl_seconds)
{%- endif %}

    app.state.repository = repository
    app.state.readiness_checks = readiness_checks
{%- if values.enable_metrics or values.enable_rate_limiting or values.enable_cors or values.enable_security_headers or values.enable_logging %}

    # The middleware added last sees the request first.
{%- endif %}
{%- if values.enable_metrics %}
    setup_metrics(app)
{%- endif %}
{%- if values.enable_rate_limiting %}
    app.add_middleware(RateLimitMiddleware, limit=settings.rate_limit)
{%- endif %}
{%- if values.enable_cors %}
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
{%- endif %}
{%- if values.enable_security_headers %}
    app.add_middleware(SecurityHeadersMiddleware)
{%- endif %}
{%- if values.enable_logging %}
    app.add_middleware(RequestLoggingMiddleware)
{%- endif %}

    app.include_router(health.router)
{%- if values.auth_type == 'jwt' %}
    app.include_router(auth.router, prefix="/api/v1")
{%- endif %}
{%- if values.auth_type != 'none' %}
    app.include_router(items.router, prefix="/api/v1", dependencies=[Depends(require_auth)])
{%- else %}
    app.include_router(items.router, prefix="/api/v1")
{%- endif %}
    return app


app = create_app()
