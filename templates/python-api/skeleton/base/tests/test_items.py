"""CRUD behaviour of the items resource."""

from httpx import AsyncClient

ITEMS = "/api/v1/items"


async def test_list_is_empty_at_first(client: AsyncClient) -> None:
    response = await client.get(ITEMS)

    assert response.status_code == 200
    assert response.json() == []


async def test_create_returns_the_stored_item(client: AsyncClient) -> None:
    response = await client.post(ITEMS, json={"name": "first", "description": "an item"})

    assert response.status_code == 201
    assert response.json() == {"id": 1, "name": "first", "description": "an item"}


async def test_get_returns_a_created_item(client: AsyncClient) -> None:
    created = (await client.post(ITEMS, json={"name": "first"})).json()

    response = await client.get(f"{ITEMS}/{created['id']}")

    assert response.status_code == 200
    assert response.json() == {"id": created["id"], "name": "first", "description": None}


async def test_list_supports_skip_and_limit(client: AsyncClient) -> None:
    for name in ("one", "two", "three"):
        await client.post(ITEMS, json={"name": name})

    response = await client.get(ITEMS, params={"skip": 1, "limit": 1})

    assert [item["name"] for item in response.json()] == ["two"]


async def test_replace_changes_every_field(client: AsyncClient) -> None:
    created = (await client.post(ITEMS, json={"name": "first", "description": "old"})).json()
    path = f"{ITEMS}/{created['id']}"

    response = await client.put(path, json={"name": "renamed"})

    assert response.status_code == 200
    assert response.json() == {"id": created["id"], "name": "renamed", "description": None}
    assert (await client.get(path)).json() == response.json()


async def test_delete_removes_the_item(client: AsyncClient) -> None:
    created = (await client.post(ITEMS, json={"name": "first"})).json()
    path = f"{ITEMS}/{created['id']}"

    response = await client.delete(path)

    assert response.status_code == 204
    assert (await client.get(path)).status_code == 404


async def test_unknown_item_answers_404(client: AsyncClient) -> None:
    assert (await client.get(f"{ITEMS}/999")).status_code == 404
    assert (await client.put(f"{ITEMS}/999", json={"name": "x"})).status_code == 404
    assert (await client.delete(f"{ITEMS}/999")).status_code == 404


async def test_invalid_input_answers_422(client: AsyncClient) -> None:
    assert (await client.post(ITEMS, json={"name": ""})).status_code == 422
    assert (await client.post(ITEMS, json={"description": "no name"})).status_code == 422
    assert (await client.get(ITEMS, params={"limit": 0})).status_code == 422
