"""The interactive API documentation and the OpenAPI document are served."""

from httpx import AsyncClient


async def test_openapi_document_describes_the_items_routes(client: AsyncClient) -> None:
    response = await client.get("/openapi.json")

    assert response.status_code == 200
    assert "/api/v1/items/{item_id}" in response.json()["paths"]


async def test_swagger_ui_and_redoc_are_served(client: AsyncClient) -> None:
    for path in ("/docs", "/redoc"):
        response = await client.get(path)
        assert response.status_code == 200
        assert response.headers["content-type"].startswith("text/html")
