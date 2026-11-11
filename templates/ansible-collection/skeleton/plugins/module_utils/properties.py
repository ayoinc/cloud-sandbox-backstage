# Copyright (c) ${{ values.destination.owner }} and contributors
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)
# SPDX-License-Identifier: MIT

"""Line-preserving edits of ``key=value`` properties files."""

from __future__ import annotations

import re

_ENTRY = re.compile(r"^\s*(?P<key>[^\s#!=:][^\s=:]*)\s*[=:]")
_INVALID_KEY = re.compile(r"^[#!]|[\s=:]")


def validate_key(key):
    """Return an error message when ``key`` cannot be a property name, else None."""
    if not key:
        return "The key must not be empty."
    if _INVALID_KEY.search(key):
        return "The key must not start with '#' or '!' or contain whitespace, '=' or ':'."
    return None


def entry_key(line):
    """Return the property name a line sets, or None for comments and blank lines."""
    match = _ENTRY.match(line)
    return match.group("key") if match else None


def set_property(lines, key, value):
    """Make ``key`` equal ``value``, keeping comments, order and other entries.

    The first entry for the key is rewritten in place and later duplicates are
    dropped; a missing key is appended. Returns ``(lines, changed)``.
    """
    wanted = f"{key}={value}"
    result = []
    seen = False
    for line in lines:
        if entry_key(line) != key:
            result.append(line)
        elif not seen:
            seen = True
            result.append(wanted)
    if not seen:
        result.append(wanted)
    return result, result != list(lines)


def remove_property(lines, key):
    """Drop every entry for ``key``. Returns ``(lines, changed)``."""
    result = [line for line in lines if entry_key(line) != key]
    return result, len(result) != len(lines)


def to_properties(mapping):
    """Render a mapping as properties text, one sorted ``key=value`` per line."""
    lines = []
    for key in sorted(mapping):
        error = validate_key(str(key))
        if error:
            raise ValueError(f"{key!r}: {error}")
        value = mapping[key]
        if isinstance(value, bool):
            value = "true" if value else "false"
        lines.append(f"{key}={value}")
    return "".join(f"{line}\n" for line in lines)
