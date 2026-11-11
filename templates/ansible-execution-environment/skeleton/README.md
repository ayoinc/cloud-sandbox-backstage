# ${{ values.name }}

${{ values.description }}

An Ansible execution environment: a container image with ansible-core
2.22.0, ansible-runner and a pinned set of collections.

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
```

## Contents

| Component | Version |
| --- | --- |
| Base image | `quay.io/fedora/fedora:44` |
| ansible-core | 2.22.0 |
| ansible-runner | 2.4.3 |
{%- if 'ansible.posix' in values.collections %}
| `ansible.posix` | 2.2.2 |
{%- endif %}{%- if 'community.general' in values.collections %}
| `community.general` | 14.0.1 |
{%- endif %}{%- if 'ansible.utils' in values.collections %}
| `ansible.utils` | 6.1.1 |
{%- endif %}{%- if 'community.crypto' in values.collections %}
| `community.crypto` | 3.5.1 |
{%- endif %}{%- if 'kubernetes.core' in values.collections %}
| `kubernetes.core` | 6.6.0 |
{%- endif %}{%- if 'community.docker' in values.collections %}
| `community.docker` | 5.4.0 |
{%- endif %}{%- if 'community.postgresql' in values.collections %}
| `community.postgresql` | 5.1.1 |
{%- endif %}{%- if 'ansible.windows' in values.collections %}
| `ansible.windows` | 3.9.2 |
{%- endif %}

`requirements.yml` is the authoritative list.

## Use it

With ansible-navigator, from a directory holding a copy of `ansible-navigator.yml`:

```bash
pip install ansible-navigator
ansible-navigator run site.yml --inventory inventory/
```

In an automation controller, add `ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest` as an execution environment
with a registry credential that can read the package.

## Verify it

Every published image is signed with the identity of this repository's build
workflow:

```bash
cosign verify ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest \
  --certificate-identity-regexp '^https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/\.github/workflows/build\.yaml@' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Change it

| To | Edit |
| --- | --- |
| Add or upgrade a collection | `requirements.yml`, with an exact version |
| Add a Python package | `requirements.txt`, with an exact version |
| Add a system package | `bindep.txt` |
| Upgrade ansible-core or the base image | `execution-environment.yml` |

Build and try it locally before pushing:

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt

ansible-builder build --tag ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:dev
ansible-navigator run tests/smoke.yml --execution-environment-image ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:dev --pull-policy never
```

## Pipeline

`.github/workflows/build.yaml` runs on pushes to `main`, on `v*.*.*` tags and
on demand:

1. yamllint, ansible-lint and a check that the definition is valid
2. Build for `linux/amd64` and run `tests/smoke.yml` inside the image
3. Scan with Trivy; fixable critical or high findings stop the run
4. Build for `${{ 'linux/amd64 and linux/arm64' if values.multiArch else 'linux/amd64' }}` and push, with provenance and an SBOM attached
5. Sign the pushed digest with cosign

Manual runs build, test and scan but do not push.

| Pushed ref | Tags |
| --- | --- |
| `main` | `latest`, `sha-<commit>` |
| `v1.2.3` | `1.2.3`, `1.2`, `sha-<commit>` |

Pin `sha-` or version tags, or a digest, wherever a run must be reproducible.

## Owner

${{ values.owner }}
