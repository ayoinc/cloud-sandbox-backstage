"""The items routes require a bearer token issued by the token endpoint."""

from datetime import UTC, datetime, timedelta

import jwt
from httpx import AsyncClient

from app.config import Settings
from app.security import ALGORITHM, create_access_token


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def test_token_endpoint_issues_a_token_that_opens_the_api(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    form = {
        "username": settings.auth_username,
        "password": settings.auth_password.get_secret_value(),
    }

    issued = await anonymous_client.post("/api/v1/auth/token", data=form)

    assert issued.status_code == 200
    assert issued.json()["token_type"] == "bearer"
    response = await anonymous_client.get(
        "/api/v1/items", headers=bearer(issued.json()["access_token"])
    )
    assert response.status_code == 200


async def test_token_endpoint_rejects_wrong_credentials(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    wrong_password = {"username": settings.auth_username, "password": "wrong"}
    wrong_username = {"username": "someone", "password": "change-me"}

    for form in (wrong_password, wrong_username):
        response = await anonymous_client.post("/api/v1/auth/token", data=form)
        assert response.status_code == 401


async def test_items_require_a_token(anonymous_client: AsyncClient) -> None:
    response = await anonymous_client.get("/api/v1/items")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


async def test_health_needs_no_token(anonymous_client: AsyncClient) -> None:
    assert (await anonymous_client.get("/health")).status_code == 200


async def test_malformed_token_is_rejected(anonymous_client: AsyncClient) -> None:
    response = await anonymous_client.get("/api/v1/items", headers=bearer("not-a-token"))

    assert response.status_code == 401


async def test_token_signed_with_another_secret_is_rejected(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    claims = {"sub": settings.auth_username, "exp": datetime.now(UTC) + timedelta(minutes=5)}
    forged = jwt.encode(claims, "another-secret-of-sufficient-length-0123456789", ALGORITHM)

    response = await anonymous_client.get("/api/v1/items", headers=bearer(forged))

    assert response.status_code == 401


async def test_expired_token_is_rejected(anonymous_client: AsyncClient, settings: Settings) -> None:
    expired = create_access_token(
        settings.auth_username, settings.model_copy(update={"jwt_expire_minutes": -1})
    )

    response = await anonymous_client.get("/api/v1/items", headers=bearer(expired))

    assert response.status_code == 401
