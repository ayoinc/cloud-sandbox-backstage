"""Browsers on a configured origin may call the API; other origins may not."""

from httpx import AsyncClient

from app.config import Settings

PREFLIGHT = {"Access-Control-Request-Method": "POST"}


async def test_preflight_from_an_allowed_origin(client: AsyncClient, settings: Settings) -> None:
    origin = settings.cors_origins[0]

    response = await client.options("/api/v1/items", headers={"Origin": origin, **PREFLIGHT})

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin


async def test_response_to_an_allowed_origin_carries_the_header(
    client: AsyncClient, settings: Settings
) -> None:
    origin = settings.cors_origins[0]

    response = await client.get("/health", headers={"Origin": origin})

    assert response.headers["access-control-allow-origin"] == origin


async def test_preflight_from_another_origin_is_refused(client: AsyncClient) -> None:
    headers = {"Origin": "https://not-allowed.example", **PREFLIGHT}

    response = await client.options("/api/v1/items", headers=headers)

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers
