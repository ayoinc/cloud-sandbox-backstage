# Copyright (c) ${{ values.destination.owner }} and contributors
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)
# SPDX-License-Identifier: MIT

from __future__ import annotations

import pytest
from ansible.errors import AnsibleFilterError

from ansible_collections.${{ values.namespace }}.${{ values.collectionName }}.plugins.filter.properties import FilterModule


@pytest.fixture(name="to_properties")
def fixture_to_properties():
    return FilterModule().filters()["to_properties"]


def test_renders_mapping(to_properties):
    assert to_properties({"server.port": 8443, "server.tls": False}) == "server.port=8443\nserver.tls=false\n"


def test_empty_mapping(to_properties):
    assert to_properties({}) == ""


@pytest.mark.parametrize("value", [["a"], "a=b", None])
def test_rejects_non_mapping(to_properties, value):
    with pytest.raises(AnsibleFilterError, match="expects a dictionary"):
        to_properties(value)


def test_rejects_invalid_key(to_properties):
    with pytest.raises(AnsibleFilterError, match="must not"):
        to_properties({"a b": 1})
