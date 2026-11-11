# Ansible Execution Environment

Creates a repository that builds an Ansible execution environment: a container
image holding ansible-core, a pinned set of collections and everything they
need, so that a playbook runs the same on a laptop, in a pipeline and in an
automation controller.

## What you get

| Path                             | Purpose                                                                                          |
| -------------------------------- | ------------------------------------------------------------------------------------------------ |
| `execution-environment.yml`      | ansible-builder version 3 definition: base image, ansible-core, ansible-runner, dependency files |
| `requirements.yml`               | Collections, each pinned to an exact version                                                     |
| `requirements.txt`, `bindep.txt` | Extra Python and system packages                                                                 |
| `ansible-navigator.yml`          | Runs playbooks in the published image by default                                                 |
| `tests/smoke.yml`                | Playbook run inside every image before it is pushed                                              |
| `.github/workflows/build.yaml`   | Lint, build, smoke test, vulnerability scan, multi-architecture push, keyless signature          |

## Parameters

| Parameter     | Description                                                                    |
| ------------- | ------------------------------------------------------------------------------ |
| Collections   | Collections baked into the image, at the versions listed in `requirements.yml` |
| Architectures | Build for `amd64` only, or for `amd64` and `arm64`                             |

## Registry and credentials

The image is pushed to the GitHub Container Registry next to the repository,
using the workflow's own short-lived token. The signature is made with Sigstore
cosign and the workflow's OIDC identity. No registry password or signing key
is stored anywhere.

The package is created private. Grant read access to the teams or automation
that pull it, under the repository's package settings.

## Updating the image

Change a pin in `requirements.yml` or `execution-environment.yml` and push to
`main`. Every push produces an image tagged with the commit; `latest` follows
`main`; pushing a tag such as `v1.2.0` publishes that version.
