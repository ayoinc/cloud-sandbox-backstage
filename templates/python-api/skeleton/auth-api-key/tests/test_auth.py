"""The items routes require a configured API key in the X-API-Key header."""

from httpx import ASGITransport, AsyncClient

from app.config import Settings
from app.main import create_app


async def test_items_require_an_api_key(anonymous_client: AsyncClient) -> None:
    response = await anonymous_client.get("/api/v1/items")

    assert response.status_code == 401


async def test_unknown_api_key_is_rejected(anonymous_client: AsyncClient) -> None:
    response = await anonymous_client.get("/api/v1/items", headers={"X-API-Key": "unknown"})

    assert response.status_code == 401


async def test_every_configured_api_key_is_accepted(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    assert len(settings.api_keys) > 1

    for key in settings.api_keys:
        response = await anonymous_client.get("/api/v1/items", headers={"X-API-Key": key})
        assert response.status_code == 200


async def test_health_needs_no_api_key(anonymous_client: AsyncClient) -> None:
    assert (await anonymous_client.get("/health")).status_code == 200


async def test_no_key_is_accepted_when_none_is_configured(settings: Settings) -> None:
    app = create_app(settings.model_copy(update={"api_keys": []}))

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/items", headers={"X-API-Key": ""})

    assert response.status_code == 401
