# Ansible Collection

Creates an Ansible collection repository ready to be tested, released and
published to Ansible Galaxy or a private Automation Hub.

## What you get

| Path                                  | Purpose                                                                                      |
| ------------------------------------- | -------------------------------------------------------------------------------------------- |
| `galaxy.yml`, `meta/runtime.yml`      | Collection metadata and the supported ansible-core range                                     |
| `plugins/modules/properties_entry.py` | A complete example module: documented, check mode, diff mode, atomic writes                  |
| `plugins/module_utils/properties.py`  | Shared logic the module and filter import, unit tested                                       |
| `plugins/filter/`                     | An example filter with sidecar documentation                                                 |
| `roles/properties_file/`              | A role that uses the module, with typed arguments                                            |
| `tests/unit/`, `tests/integration/`   | `ansible-test units` and `ansible-test integration` targets                                  |
| `changelogs/`                         | antsibull-changelog configuration and the first fragment                                     |
| `.github/workflows/ci.yaml`           | Lint, changelog lint, sanity, units, integration and a build                                 |
| `.github/workflows/publish.yaml`      | Builds the tagged version, attests its provenance, publishes it and creates a GitHub release |

The example plugins are small but real; they show the conventions that
`ansible-test sanity` enforces. Replace them with your own content and keep
the structure.

## Parameters

| Parameter       | Description                                        |
| --------------- | -------------------------------------------------- |
| Name            | Repository and catalog component name              |
| Namespace       | Galaxy namespace, usually the organisation         |
| Collection name | Second half of the fully qualified collection name |

## Publishing

Ansible Galaxy authenticates with an API token; it has no keyless option. Add
the token as the `ANSIBLE_GALAXY_TOKEN` repository secret. Without it the
publish workflow still builds, attests and attaches the artifact to a GitHub
release, and skips the upload. To publish to a private Automation Hub, also set
the `ANSIBLE_GALAXY_SERVER` repository variable to its API URL.

## Releasing

1. Add a changelog fragment with each change.
2. Set the version in `galaxy.yml` and run `antsibull-changelog release`.
3. Commit, tag the commit with the bare version (`1.2.0`) and push the tag.
