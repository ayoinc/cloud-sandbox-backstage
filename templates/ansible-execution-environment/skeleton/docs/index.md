# ${{ values.name }}

${{ values.description }}

| | |
| --- | --- |
| Image | `ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}` |
| Registry | GitHub Container Registry |
| Architectures | ${{ 'amd64, arm64' if values.multiArch else 'amd64' }} |
| ansible-core | 2.22.0 |
| Owner | `${{ values.owner }}` |

## Why an execution environment

A playbook depends on more than its own YAML: a version of ansible-core,
collections, Python libraries and command-line tools. An execution environment
fixes all of them in one image, so the run on a laptop, in a pipeline and in
an automation controller are the same run.

## How the image is built

```
execution-environment.yml ─┐
requirements.yml ──────────┤
requirements.txt ──────────┼─ ansible-builder create ─▶ context/Containerfile ─▶ build ─▶ test ─▶ scan ─▶ push ─▶ sign
bindep.txt ────────────────┘
```

ansible-builder turns the definition into a multi-stage Containerfile:
collections are downloaded in one stage, Python wheels compiled in another,
and only the results are copied into the final image. Each collection's own
Python and system requirements are discovered and installed automatically.

## Supply chain

- The base image and every dependency are pinned
- The workflow authenticates to the registry with its own short-lived token
- Images carry build provenance and an SBOM
- The pushed digest is signed keylessly; `README.md` shows how to verify it
- The image runs as an unprivileged user
