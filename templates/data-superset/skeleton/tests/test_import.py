"""Tests for the import, against an in-memory stand-in for Superset."""

import importlib
import json

import pytest

from scripts.assets import load_assets
from scripts.client import SupersetError

importer = importlib.import_module("scripts.import")

KEYS = {
    "database": "database_name",
    "dataset": "table_name",
    "chart": "slice_name",
    "dashboard": "slug",
}


class FakeSuperset:
    """Stores what is created and updated, keyed by resource."""

    def __init__(self):
        self.items = {resource: {} for resource in KEYS}

    def find(self, resource, column, value):
        for item_id, item in self.items[resource].items():
            if item.get(column) == value:
                return {"id": item_id, **item}
        return None

    def upsert(self, resource, column, value, payload):
        existing = self.find(resource, column, value)
        item_id = existing["id"] if existing else len(self.items[resource]) + 1
        self.items[resource].setdefault(item_id, {}).update(payload)
        return item_id

    def request(self, method, path, json=None, params=None):
        resource, _, item_id = path.removeprefix("/api/v1/").partition("/")
        if method == "POST":
            new_id = len(self.items[resource]) + 1
            self.items[resource][new_id] = dict(json)
            return {"id": new_id}
        self.items[resource][int(item_id)].update(json)
        return {"id": int(item_id)}


def test_import_creates_every_asset(monkeypatch):
    monkeypatch.setenv("SUPERSET_DATABASE_URI", "postgresql://host/db")
    superset = FakeSuperset()
    assets = load_assets()

    importer.run(superset, assets)

    for resource, directory in (
        ("database", "databases"),
        ("dataset", "datasets"),
        ("chart", "charts"),
        ("dashboard", "dashboards"),
    ):
        assert len(superset.items[resource]) == len(assets[directory])
    chart = superset.items["chart"][1]
    assert chart["datasource_id"] == 1
    assert json.loads(chart["params"])["datasource"] == "1__table"
    assert chart["dashboards"] == [1]
    assert superset.items["database"][1]["sqlalchemy_uri"] == "postgresql://host/db"


def test_import_is_repeatable(monkeypatch):
    monkeypatch.setenv("SUPERSET_DATABASE_URI", "postgresql://host/db")
    superset = FakeSuperset()
    assets = load_assets()

    importer.run(superset, assets)
    importer.run(superset, assets)

    assert all(len(items) == 1 for items in superset.items.values())


def test_new_database_needs_a_connection_string(monkeypatch):
    monkeypatch.delenv("SUPERSET_DATABASE_URI", raising=False)

    with pytest.raises(SupersetError, match="SUPERSET_DATABASE_URI"):
        importer.run(FakeSuperset(), load_assets())
