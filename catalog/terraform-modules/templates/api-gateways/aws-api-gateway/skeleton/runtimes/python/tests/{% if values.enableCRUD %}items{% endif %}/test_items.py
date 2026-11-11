import json
import re
from datetime import datetime
from decimal import Decimal

import pytest

from items.handlers import item_routes
from items.store import _from_dynamo, _to_dynamo
from router import route


class MemoryStore:
    """The interface of items.store.DynamoStore, kept in memory."""

    def __init__(self):
        self._items = {}

    def list(self):
        return list(self._items.values())

    def get(self, item_id):
        return self._items.get(item_id)

    def put(self, item):
        self._items[item["id"]] = item

    def delete(self, item_id):
        return self._items.pop(item_id, None) is not None


_NO_BODY = object()


@pytest.fixture
def call():
    routes = item_routes(MemoryStore())

    def _call(method, resource, item_id=None, body=_NO_BODY):
        return route(
            routes,
            {
                "httpMethod": method,
                "resource": resource,
                "pathParameters": {"id": item_id} if item_id else None,
                "body": None if body is _NO_BODY else json.dumps(body),
                "isBase64Encoded": False,
            },
        )

    return _call


def create(call, attributes):
    return json.loads(call("POST", "/items", body=attributes)["body"])


def test_post_stores_the_body_with_an_id_and_timestamps(call):
    response = call("POST", "/items", body={"name": "first"})
    assert response["statusCode"] == 201
    item = json.loads(response["body"])
    assert item["name"] == "first"
    assert re.fullmatch(r"[0-9a-f-]{36}", item["id"])
    assert item["createdAt"] == item["updatedAt"]
    assert datetime.fromisoformat(item["createdAt"])


def test_post_rejects_a_body_that_is_not_a_json_object(call):
    response = call("POST", "/items", body=["not", "an", "object"])
    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {
        "message": "The request body must be a JSON object"
    }


def test_get_lists_what_was_stored(call):
    first = create(call, {"name": "first"})
    second = create(call, {"name": "second"})
    response = call("GET", "/items")
    assert response["statusCode"] == 200
    assert json.loads(response["body"]) == {"items": [first, second]}


def test_get_by_id_returns_the_item_or_404(call):
    item = create(call, {"name": "first"})
    found = call("GET", "/items/{id}", item_id=item["id"])
    assert found["statusCode"] == 200
    assert json.loads(found["body"]) == item

    missing = call("GET", "/items/{id}", item_id="unknown")
    assert missing["statusCode"] == 404
    assert json.loads(missing["body"]) == {"message": "Item not found"}


def test_put_replaces_the_attributes_and_keeps_id_and_created_at(call):
    item = create(call, {"name": "first", "colour": "red"})
    response = call(
        "PUT",
        "/items/{id}",
        item_id=item["id"],
        body={"name": "renamed", "id": "ignored", "createdAt": "ignored"},
    )
    assert response["statusCode"] == 200
    updated = json.loads(response["body"])
    assert updated["name"] == "renamed"
    assert "colour" not in updated
    assert updated["id"] == item["id"]
    assert updated["createdAt"] == item["createdAt"]

    stored = call("GET", "/items/{id}", item_id=item["id"])
    assert json.loads(stored["body"]) == updated


def test_put_answers_404_for_an_unknown_id_and_400_for_a_bad_body(call):
    missing = call("PUT", "/items/{id}", item_id="unknown", body={})
    assert missing["statusCode"] == 404

    item = create(call, {"name": "first"})
    invalid = call("PUT", "/items/{id}", item_id=item["id"], body="text")
    assert invalid["statusCode"] == 400


def test_delete_removes_the_item_then_answers_404(call):
    item = create(call, {"name": "first"})
    deleted = call("DELETE", "/items/{id}", item_id=item["id"])
    assert deleted["statusCode"] == 204
    assert deleted["body"] == ""

    again = call("DELETE", "/items/{id}", item_id=item["id"])
    assert again["statusCode"] == 404


def test_numbers_survive_the_dynamodb_representation():
    item = {"count": 3, "price": 9.5, "tags": ["a"], "nested": {"ratio": 0.25}}
    stored = _to_dynamo(item)
    assert stored["price"] == Decimal("9.5")
    assert _from_dynamo(stored) == item
