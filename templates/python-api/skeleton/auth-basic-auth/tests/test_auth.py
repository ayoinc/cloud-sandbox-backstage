"""The items routes require the configured user name and password."""

from httpx import AsyncClient, BasicAuth

from app.config import Settings


async def test_items_require_credentials(anonymous_client: AsyncClient) -> None:
    response = await anonymous_client.get("/api/v1/items")

    assert response.status_code == 401
    assert response.headers["www-authenticate"].startswith("Basic")


async def test_configured_credentials_are_accepted(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    auth = BasicAuth(settings.auth_username, settings.auth_password.get_secret_value())

    response = await anonymous_client.get("/api/v1/items", auth=auth)

    assert response.status_code == 200


async def test_wrong_password_and_wrong_user_are_rejected(
    anonymous_client: AsyncClient, settings: Settings
) -> None:
    wrong_password = BasicAuth(settings.auth_username, "wrong")
    wrong_user = BasicAuth("someone", settings.auth_password.get_secret_value())

    for auth in (wrong_password, wrong_user):
        response = await anonymous_client.get("/api/v1/items", auth=auth)
        assert response.status_code == 401


async def test_health_needs_no_credentials(anonymous_client: AsyncClient) -> None:
    assert (await anonymous_client.get("/health")).status_code == 200
