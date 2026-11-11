"""Handlers of the /items endpoints."""

import uuid
from datetime import UTC, datetime

from router import HttpError, json_response, no_content, parse_object


def _now():
    return datetime.now(UTC).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _not_found():
    return HttpError(404, "Item not found")


def item_routes(store):
    """Build the routes on top of a store with list, get, put and delete."""

    def list_items(_event):
        return json_response(200, {"items": store.list()})

    def create_item(event):
        now = _now()
        item = {
            **parse_object(event),
            "id": str(uuid.uuid4()),
            "createdAt": now,
            "updatedAt": now,
        }
        store.put(item)
        return json_response(201, item)

    def get_item(event):
        item = store.get(event["pathParameters"]["id"])
        if item is None:
            raise _not_found()
        return json_response(200, item)

    def replace_item(event):
        attributes = parse_object(event)
        existing = store.get(event["pathParameters"]["id"])
        if existing is None:
            raise _not_found()
        item = {
            **attributes,
            "id": existing["id"],
            "createdAt": existing["createdAt"],
            "updatedAt": _now(),
        }
        store.put(item)
        return json_response(200, item)

    def delete_item(event):
        if not store.delete(event["pathParameters"]["id"]):
            raise _not_found()
        return no_content()

    return {
        "GET /items": list_items,
        "POST /items": create_item,
        "GET /items/{id}": get_item,
        "PUT /items/{id}": replace_item,
        "DELETE /items/{id}": delete_item,
    }
