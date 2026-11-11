"""The interactive API documentation and the OpenAPI document are not served."""

import pytest
from httpx import AsyncClient


@pytest.mark.parametrize("path", ["/docs", "/redoc", "/openapi.json"])
async def test_documentation_routes_do_not_exist(client: AsyncClient, path: str) -> None:
    response = await client.get(path)

    assert response.status_code == 404
