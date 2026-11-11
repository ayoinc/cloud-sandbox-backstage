# Copyright (c) ${{ values.destination.owner }} and contributors
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)
# SPDX-License-Identifier: MIT

from __future__ import annotations

from ansible.errors import AnsibleFilterError
from ansible.module_utils.common.text.converters import to_native

from ansible_collections.${{ values.namespace }}.${{ values.collectionName }}.plugins.module_utils.properties import to_properties


def to_properties_filter(mapping):
    """Render a mapping as the text of a properties file."""
    if not isinstance(mapping, dict):
        raise AnsibleFilterError(f"to_properties expects a dictionary, got {type(mapping).__name__}")
    try:
        return to_properties(mapping)
    except ValueError as exc:
        raise AnsibleFilterError(f"to_properties: {to_native(exc)}") from exc


class FilterModule:
    """Filters for properties files."""

    def filters(self):
        return {"to_properties": to_properties_filter}
