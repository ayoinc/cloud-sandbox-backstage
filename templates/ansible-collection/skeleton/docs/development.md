# Development

## Adding a module

1. Create `plugins/modules/<name>.py` with `DOCUMENTATION`, `EXAMPLES` and `RETURN`. Set `version_added` to the release that will contain it.
2. Keep logic that can be tested without Ansible in `plugins/module_utils/` and import it with the full `ansible_collections.${{ values.namespace }}.${{ values.collectionName }}.plugins.module_utils` path.
3. Support check mode, and diff mode where the module changes text.
4. Add unit tests under `tests/unit/plugins/` and an integration target under `tests/integration/targets/<name>/`.
5. Add a changelog fragment.

## Tests

| Command | Checks |
| --- | --- |
| `ansible-test sanity --docker default` | Documentation matches the argument spec, imports, style, compile on every supported Python |
| `ansible-test units --docker default` | `tests/unit/` with pytest |
| `ansible-test integration --docker ubuntu2404` | Each target in `tests/integration/targets/` against a real container |
| `ansible-lint` | Roles, playbooks and collection metadata, `production` profile |

Run one integration target with
`ansible-test integration properties_entry --docker ubuntu2404`.

Accepted sanity findings are recorded per ansible-core version in
`tests/sanity/ignore-<version>.txt`, each with a comment giving the reason.
The one entry there today exists because `validate-modules` expects a GPLv3
header and this collection is MIT licensed; a new module needs the same line,
and a new ansible-core release needs a copy of the file under its version.

## Supported versions

`meta/runtime.yml` states the oldest supported ansible-core. When raising it,
update the minimum in `README.md`, the role's `meta/main.yml` and the Python
matrix in `.github/workflows/ci.yaml`.
