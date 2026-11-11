"""Every response carries the security headers, including error responses."""

import pytest
from httpx import AsyncClient

from app.security_headers import SECURITY_HEADERS


@pytest.mark.parametrize("path", ["/health", "/api/v1/items", "/no-such-path"])
async def test_responses_carry_the_security_headers(client: AsyncClient, path: str) -> None:
    response = await client.get(path)

    for name, value in SECURITY_HEADERS.items():
        assert response.headers[name] == value
