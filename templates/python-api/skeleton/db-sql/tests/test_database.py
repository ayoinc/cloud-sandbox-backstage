"""The readiness endpoint reflects whether the database answers."""

from pathlib import Path

from httpx import ASGITransport, AsyncClient

from app.config import Settings
from app.main import create_app


async def test_readiness_reports_the_database(client: AsyncClient) -> None:
    response = await client.get("/health/ready")

    assert response.status_code == 200
    assert response.json()["checks"]["database"] == "ok"


async def test_readiness_fails_when_the_database_is_unreachable(
    settings: Settings, tmp_path: Path
) -> None:
    unreachable = f"sqlite+aiosqlite:///{tmp_path}/missing-directory/app.db"
    app = create_app(settings.model_copy(update={"database_url": unreachable}))

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        ready = await client.get("/health/ready")
        live = await client.get("/health")

    assert ready.status_code == 503
    assert ready.json()["status"] == "not ready"
    assert ready.json()["checks"]["database"] == "failed"
    assert live.status_code == 200


async def test_items_survive_between_requests(client: AsyncClient) -> None:
    created = await client.post("/api/v1/items", json={"name": "stored"})

    listed = await client.get("/api/v1/items")

    assert listed.json() == [created.json()]
