#!/usr/bin/python
# Copyright (c) ${{ values.destination.owner }} and contributors
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)
# SPDX-License-Identifier: MIT

from __future__ import annotations

DOCUMENTATION = r"""
---
module: properties_entry
short_description: Manage a single entry in a properties file
version_added: "1.0.0"
description:
  - Ensures that a C(key=value) entry is present in, or absent from, a properties file.
  - Comments, blank lines and the order of the other entries are preserved.
  - The file is replaced atomically, so readers never see a partial write.
author:
  - ${{ values.destination.owner }} (@${{ values.destination.owner }})
extends_documentation_fragment:
  - ansible.builtin.files
  - ansible.builtin.action_common_attributes
attributes:
  check_mode:
    support: full
  diff_mode:
    support: full
  platform:
    platforms: posix
options:
  path:
    description:
      - Path of the properties file on the managed host.
    type: path
    required: true
    aliases: [dest]
  key:
    description:
      - Name of the property.
      - Must not start with V(#) or V(!) or contain whitespace, V(=) or V(:).
    type: str
    required: true
  value:
    description:
      - Value of the property. Required when O(state=present).
    type: str
  state:
    description:
      - Whether the entry should exist.
    type: str
    choices: [present, absent]
    default: present
  create:
    description:
      - Create the file when it does not exist and O(state=present).
      - When V(false), a missing file is an error.
    type: bool
    default: true
  backup:
    description:
      - Keep a timestamped copy of the file before changing it.
    type: bool
    default: false
notes:
  - Line continuations and escaped separators are not interpreted; each line is one entry.
seealso:
  - module: ansible.builtin.lineinfile
  - plugin: ${{ values.namespace }}.${{ values.collectionName }}.to_properties
    plugin_type: filter
"""

EXAMPLES = r"""
- name: Set the listen port
  ${{ values.namespace }}.${{ values.collectionName }}.properties_entry:
    path: /etc/app/app.properties
    key: server.port
    value: "8443"
    owner: app
    group: app
    mode: "0640"

- name: Remove a retired setting, keeping a copy of the file
  ${{ values.namespace }}.${{ values.collectionName }}.properties_entry:
    path: /etc/app/app.properties
    key: legacy.mode
    state: absent
    backup: true
"""

RETURN = r"""
path:
  description: Path of the properties file.
  returned: always
  type: str
  sample: /etc/app/app.properties
backup_file:
  description: Path of the copy made before the change.
  returned: when O(backup=true) and an existing file was changed
  type: str
  sample: /etc/app/app.properties.4242.2026-01-31@09:30:00~
"""

import os
import tempfile

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.common.text.converters import to_bytes, to_text

from ansible_collections.${{ values.namespace }}.${{ values.collectionName }}.plugins.module_utils.properties import (
    remove_property,
    set_property,
    validate_key,
)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            path=dict(type="path", required=True, aliases=["dest"]),
            key=dict(type="str", required=True, no_log=False),
            value=dict(type="str"),
            state=dict(type="str", choices=["present", "absent"], default="present"),
            create=dict(type="bool", default=True),
            backup=dict(type="bool", default=False),
        ),
        required_if=[("state", "present", ("value",))],
        add_file_common_args=True,
        supports_check_mode=True,
    )

    path = module.params["path"]
    key = module.params["key"]
    state = module.params["state"]
    b_path = to_bytes(path, errors="surrogate_or_strict")

    error = validate_key(key)
    if error:
        module.fail_json(msg=error, path=path)

    exists = os.path.exists(b_path)
    original = ""
    if exists:
        try:
            with open(b_path, "rb") as handle:
                original = to_text(handle.read(), errors="surrogate_or_strict")
        except (OSError, UnicodeError) as exc:
            module.fail_json(msg=f"Unable to read {path}: {exc}", path=path)
    elif state == "present" and not module.params["create"]:
        module.fail_json(msg=f"{path} does not exist and create is false.", path=path)

    lines = original.splitlines()
    if state == "present":
        lines, changed = set_property(lines, key, module.params["value"])
    else:
        lines, changed = remove_property(lines, key)
    updated = "".join(f"{line}\n" for line in lines)

    result = dict(changed=changed, path=path)
    if module._diff:
        result["diff"] = dict(before=original, after=updated, before_header=path, after_header=path)

    if changed and not module.check_mode:
        if module.params["backup"] and exists:
            result["backup_file"] = module.backup_local(path)
        descriptor, temporary = tempfile.mkstemp(dir=module.tmpdir)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(to_bytes(updated, errors="surrogate_or_strict"))
        module.atomic_move(temporary, path, unsafe_writes=module.params["unsafe_writes"])

    if os.path.exists(b_path):
        file_args = module.load_file_common_arguments(module.params)
        result["changed"] = module.set_fs_attributes_if_different(file_args, result["changed"])

    module.exit_json(**result)


if __name__ == "__main__":
    main()
