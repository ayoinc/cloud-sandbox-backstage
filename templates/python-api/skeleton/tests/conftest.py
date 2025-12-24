"""Pytest configuration and fixtures."""

import asyncio
from collections.abc import AsyncGenerator, Generator
from typing import Any

import pytest
from httpx import ASGITransport, AsyncClient

from ${{ values.name | replace('-', '_') }}.main import app


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create event loop for async tests."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """Create async HTTP client for testing."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def sample_item_data() -> dict[str, Any]:
    """Sample item data for tests."""
    return {
        "name": "Test Item",
        "description": "A test item description",
        "price": 29.99,
        "is_active": True,
    }


@pytest.fixture
def sample_user_data() -> dict[str, Any]:
    """Sample user data for tests."""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "securepassword123",
    }
