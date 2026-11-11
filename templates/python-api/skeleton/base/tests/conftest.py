"""Fixtures shared by all tests."""
{% if values.auth_type == 'basic-auth' %}
from base64 import b64encode
{%- endif %}
from collections.abc import AsyncIterator

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.config import Settings
{%- if values.sql %}
from app.db import Base
{%- endif %}
from app.main import create_app
{%- if values.auth_type == 'jwt' %}
from app.security import create_access_token
{%- endif %}


@pytest.fixture
def settings() -> Settings:
    """Settings that ignore a local .env file{% if values.sql %} and use an in-memory SQLite database{% endif %}."""
    return Settings(
        _env_file=None,
{%- if values.sql %}
        database_url="sqlite+aiosqlite://",
{%- endif %}
{%- if values.auth_type == 'api-key' %}
        api_keys=["test-key", "second-test-key"],
{%- endif %}
{%- if values.enable_rate_limiting %}
        rate_limit="1000/minute",
{%- endif %}
    )


@pytest.fixture
async def app(settings: Settings) -> AsyncIterator[FastAPI]:
    application = create_app(settings)
    async with application.router.lifespan_context(application):
{%- if values.sql %}
        async with application.state.database.engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)
{%- endif %}
        yield application
{%- if values.auth_type != 'none' %}


@pytest.fixture
def auth_headers(settings: Settings) -> dict[str, str]:
    """Headers that authenticate a request."""
{%- if values.auth_type == 'jwt' %}
    token = create_access_token(settings.auth_username, settings)
    return {"Authorization": f"Bearer {token}"}
{%- elif values.auth_type == 'api-key' %}
    return {"X-API-Key": settings.api_keys[0]}
{%- else %}
    credentials = f"{settings.auth_username}:{settings.auth_password.get_secret_value()}"
    return {"Authorization": f"Basic {b64encode(credentials.encode()).decode()}"}
{%- endif %}


@pytest.fixture
async def client(app: FastAPI, auth_headers: dict[str, str]) -> AsyncIterator[AsyncClient]:
    """HTTP client that calls the application in process as an authenticated caller."""
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test", headers=auth_headers
    ) as client:
        yield client


@pytest.fixture
async def anonymous_client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    """HTTP client that sends no credentials."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
{%- else %}


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    """HTTP client that calls the application in process."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
{%- endif %}
