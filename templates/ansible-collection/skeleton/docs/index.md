# ${{ values.namespace }}.${{ values.collectionName }}

${{ values.description }}

| | |
| --- | --- |
| Fully qualified name | `${{ values.namespace }}.${{ values.collectionName }}` |
| Repository | `${{ values.destination.owner }}/${{ values.destination.repo }}` |
| Owner | `${{ values.owner }}` |
| Supported ansible-core | 2.18 and newer |

## Layout

```
galaxy.yml                          # Name, version, tags, what the build leaves out
meta/runtime.yml                    # Supported ansible-core range
plugins/
├── modules/properties_entry.py     # Module, with its documentation
├── module_utils/properties.py      # Logic shared by module and filter
└── filter/                         # Filter and its sidecar documentation
roles/properties_file/              # Role built on the module
tests/
├── unit/                           # pytest, run by ansible-test units
└── integration/targets/            # Playbook targets, run by ansible-test integration
changelogs/                         # antsibull-changelog configuration and fragments
```

## Pipelines

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yaml` | Push to `main`, manual | yamllint, ansible-lint, changelog lint, sanity, units, integration, build |
| `publish.yaml` | Version tag, manual | Build, provenance attestation, GitHub release, upload to Galaxy |
