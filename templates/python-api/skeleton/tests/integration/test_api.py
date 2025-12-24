"""Integration tests for API endpoints."""

from typing import Any

import pytest
from httpx import AsyncClient


@pytest.mark.integration
class TestHealthEndpoints:
    """Tests for health check endpoints."""

    async def test_health_check(self, client: AsyncClient) -> None:
        """Test health endpoint returns healthy status."""
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    async def test_readiness_check(self, client: AsyncClient) -> None:
        """Test readiness endpoint."""
        response = await client.get("/health/ready")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data


@pytest.mark.integration
class TestItemsEndpoints:
    """Tests for items CRUD endpoints."""

    async def test_create_item(
        self, client: AsyncClient, sample_item_data: dict[str, Any]
    ) -> None:
        """Test creating a new item."""
        response = await client.post("/api/v1/items/", json=sample_item_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == sample_item_data["name"]
        assert data["price"] == sample_item_data["price"]
        assert "id" in data

    async def test_list_items(self, client: AsyncClient) -> None:
        """Test listing items."""
        response = await client.get("/api/v1/items/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    async def test_get_item_not_found(self, client: AsyncClient) -> None:
        """Test getting non-existent item returns 404."""
        response = await client.get("/api/v1/items/00000000-0000-0000-0000-000000000000")
        assert response.status_code == 404

    async def test_create_item_invalid_data(self, client: AsyncClient) -> None:
        """Test creating item with invalid data returns 422."""
        response = await client.post("/api/v1/items/", json={"name": ""})
        assert response.status_code == 422
