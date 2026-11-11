"""Liveness and readiness endpoints."""

from fastapi import FastAPI
from httpx import AsyncClient


async def test_liveness(client: AsyncClient) -> None:
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "environment": "development"}


async def test_readiness_when_every_check_passes(client: AsyncClient) -> None:
    response = await client.get("/health/ready")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ready"
    assert set(body["checks"].values()) <= {"ok"}


async def test_readiness_answers_503_when_a_check_fails(app: FastAPI, client: AsyncClient) -> None:
    async def failing_check() -> None:
        raise ConnectionError("dependency is down")

    app.state.readiness_checks["dependency"] = failing_check

    response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["status"] == "not ready"
    assert response.json()["checks"]["dependency"] == "failed"
