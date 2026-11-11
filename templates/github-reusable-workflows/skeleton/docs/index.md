# ${{ values.name }}

${{ values.description }}

## Why shared workflows

Without them every repository carries its own copy of the pipeline, each
slightly different and none reviewed for security. With them:

- a fix or an upgrade is made once and reaches every caller;
- the supply-chain controls (pinned actions, minimal permissions, signing,
  provenance) are present by default instead of by diligence;
- the provenance of an artifact names one builder, this repository, which
  policy can require.

## Catalogue

| Name | Type | Call |
| --- | --- | --- |
| Node.js CI | Reusable workflow | `${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/node-ci.yaml` |
| Python CI | Reusable workflow | `${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/python-ci.yaml` |
| Container publish | Reusable workflow | `${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/container-publish.yaml` |
| Set up a Node.js project | Composite action | `${{ values.destination.owner }}/${{ values.destination.repo }}/actions/setup-node-project` |
| Set up a Python project | Composite action | `${{ values.destination.owner }}/${{ values.destination.repo }}/actions/setup-python-project` |
| Container smoke test | Composite action | `${{ values.destination.owner }}/${{ values.destination.repo }}/actions/container-smoke-test` |

Inputs, outputs and required permissions are in the repository's README.

## Workflow or action?

| | Reusable workflow | Composite action |
| --- | --- | --- |
| Unit | One or more whole jobs | Steps inside the caller's job |
| Runner and permissions | Declared by the workflow, limited by the caller | The caller's |
| Identity in OIDC tokens and provenance | The reusable workflow (`job_workflow_ref`) | The calling workflow |
| Use when | The process must be the same everywhere: publish, sign, deploy | Set-up that jobs combine with their own steps |

The container workflow is a reusable workflow for the third row: the OIDC
token of its job names this repository's workflow file, so signatures and
provenance prove that the reviewed pipeline built the image.

## Supply-chain guarantees of `container-publish.yaml`

| Property | How |
| --- | --- |
| No long-lived credentials | `GITHUB_TOKEN` for the GitHub Container Registry; an OIDC-assumed role for Amazon ECR |
| Scanned before publishing | Trivy scans the built image; the push happens afterwards |
| Immutable reference | The outputs give the digest; deploy by digest, not by tag |
| Signed | cosign keyless signature on the digest, recorded in the transparency log |
| Provenance | SLSA build provenance attestation stored in the registry, generated in a job the caller's steps cannot alter |
| SBOM | Attached to the image by BuildKit |

## How this repository is checked

| Check | Catches |
| --- | --- |
| actionlint | Invalid workflow syntax, wrong expression types, shell mistakes |
| zizmor (pedantic) | Unpinned actions, broad permissions, template injection, credential persistence, cache poisoning |
| Fixture runs | A workflow or action that no longer works |
| Dependabot | Stale action pins, as weekly grouped pull requests |

## Versioning

- Tags `v<major>.<minor>.<patch>` mark releases; `v<major>` follows the latest.
- Callers should pin a commit hash and let Dependabot propose updates.
- Breaking changes (a removed or renamed input, a new required permission, a
  changed default that alters results) need a new major version.
