# Copyright (c) ${{ values.destination.owner }} and contributors
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)
# SPDX-License-Identifier: MIT

from __future__ import annotations

import pytest

from ansible_collections.${{ values.namespace }}.${{ values.collectionName }}.plugins.module_utils.properties import (
    entry_key,
    remove_property,
    set_property,
    to_properties,
    validate_key,
)

EXISTING = ["# server", "server.port=8080", "", "server.host : localhost", "server.port=9090"]


@pytest.mark.parametrize(
    ("line", "expected"),
    [
        ("server.port=8080", "server.port"),
        ("  server.host : localhost", "server.host"),
        ("# server.port=1", None),
        ("! note", None),
        ("", None),
        ("no separator", None),
    ],
)
def test_entry_key(line, expected):
    assert entry_key(line) == expected


def test_set_property_rewrites_first_entry_and_drops_duplicates():
    lines, changed = set_property(EXISTING, "server.port", "8443")

    assert changed is True
    assert lines == ["# server", "server.port=8443", "", "server.host : localhost"]


def test_set_property_appends_missing_key():
    lines, changed = set_property(EXISTING, "server.tls", "true")

    assert changed is True
    assert lines == [*EXISTING, "server.tls=true"]


def test_set_property_is_idempotent():
    lines, changed = set_property(["a=1", "b=2"], "b", "2")

    assert changed is False
    assert lines == ["a=1", "b=2"]


def test_remove_property_drops_every_entry():
    lines, changed = remove_property(EXISTING, "server.port")

    assert changed is True
    assert lines == ["# server", "", "server.host : localhost"]


def test_remove_property_without_match():
    lines, changed = remove_property(EXISTING, "absent.key")

    assert changed is False
    assert lines == EXISTING


@pytest.mark.parametrize("key", ["", "#comment", "!bang", "has space", "a=b", "a:b"])
def test_validate_key_rejects(key):
    assert validate_key(key) is not None


def test_validate_key_accepts():
    assert validate_key("server.port") is None


def test_to_properties_sorts_and_renders_booleans():
    assert to_properties({"b": True, "a": 1, "c": "x y"}) == "a=1\nb=true\nc=x y\n"


def test_to_properties_rejects_invalid_key():
    with pytest.raises(ValueError, match="bad key"):
        to_properties({"bad key": 1})
