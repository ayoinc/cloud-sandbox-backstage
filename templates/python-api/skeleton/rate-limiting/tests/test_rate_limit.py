"""Requests over the configured limit are answered with 429."""

import pytest
from httpx import AsyncClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def settings(settings: Settings) -> Settings:
    return settings.model_copy(update={"rate_limit": "2/minute"})


async def test_requests_over_the_limit_are_rejected(client: AsyncClient) -> None:
    responses = [await client.get("/api/v1/items") for _ in range(3)]

    assert [response.status_code for response in responses] == [200, 200, 429]
    assert responses[2].json() == {"detail": "Rate limit exceeded: 2 per 1 minute"}
    assert 1 <= int(responses[2].headers["retry-after"]) <= 60


async def test_responses_report_the_remaining_requests(client: AsyncClient) -> None:
    response = await client.get("/api/v1/items")

    assert response.headers["x-ratelimit-limit"] == "2"
    assert response.headers["x-ratelimit-remaining"] == "1"


async def test_health_probes_are_not_limited(client: AsyncClient) -> None:
    for path in ("/health", "/health/ready"):
        statuses = {(await client.get(path)).status_code for _ in range(5)}
        assert statuses == {200}


def test_an_invalid_limit_stops_the_application_from_starting(settings: Settings) -> None:
    app = create_app(settings.model_copy(update={"rate_limit": "many"}))

    with pytest.raises(ValueError, match="many"):
        app.build_middleware_stack()
