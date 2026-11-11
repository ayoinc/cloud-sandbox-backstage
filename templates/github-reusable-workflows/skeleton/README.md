# ${{ values.name }}

${{ values.description }}

Reusable GitHub Actions workflows and composite actions: one maintained,
security-reviewed implementation of build, test and publish that repositories
call instead of copying.

| Kind | Name | Purpose |
| --- | --- | --- |
| Workflow | [`node-ci.yaml`](.github/workflows/node-ci.yaml) | Install, audit, lint, test and build a Node.js project |
| Workflow | [`python-ci.yaml`](.github/workflows/python-ci.yaml) | Install, lint, type check and test a Python project managed with uv |
| Workflow | [`container-publish.yaml`](.github/workflows/container-publish.yaml) | Build, scan, publish and sign a container image, with SLSA build provenance |
| Action | [`setup-node-project`](actions/setup-node-project) | Node.js, dependency cache, `npm ci` |
| Action | [`setup-python-project`](actions/setup-python-project) | uv, Python, dependency cache, `uv sync --locked` |
| Action | [`container-smoke-test`](actions/container-smoke-test) | Start an image and wait for an HTTP path to answer |

## Use a workflow

A reusable workflow is a whole job. Call it with `uses` at job level and grant
the permissions it needs; a called workflow can never have more than its
caller grants.

```yaml
name: CI

on:
  push:

permissions: {}

jobs:
  test:
    permissions:
      contents: read
    uses: ${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/node-ci.yaml@<commit> # v1.0.0

  publish:
    needs: test
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
      id-token: write
      attestations: write
    uses: ${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/container-publish.yaml@<commit> # v1.0.0
    with:
      platforms: linux/amd64,linux/arm64

  deploy:
    needs: publish
    runs-on: ubuntu-latest
    steps:
      - env:
          IMAGE: {% raw %}${{ needs.publish.outputs.image }}@${{ needs.publish.outputs.digest }}{% endraw %}
        run: echo "Deploy $IMAGE"
```

Pin `@<commit>` to the full commit hash of a release and keep the version in
a comment; Dependabot updates both. `@v1` follows the latest release of a
major version, which is convenient but means the code your pipeline runs can
change without a commit in your repository.

### `node-ci.yaml`

| Input | Default | Meaning |
| --- | --- | --- |
| `node-version` | `.node-version` of the project, else `${{ values.node_version }}` | Node.js version |
| `working-directory` | `.` | Directory of the project |
| `run-lint` | `true` | Run `npm run lint` if the script exists |
| `run-build` | `true` | Run `npm run build` if the script exists |
| `audit-level` | `high` | Fail on production advisories of this severity; `none` skips the audit |

Permissions: `contents: read`.

### `python-ci.yaml`

| Input | Default | Meaning |
| --- | --- | --- |
| `python-version` | `.python-version` of the project, else `${{ values.python_version }}` | Python version |
| `working-directory` | `.` | Directory of the project |
| `run-ruff` | `true` | Run `ruff check` and `ruff format --check` |
| `run-mypy` | `false` | Run `mypy` |
| `test-command` | `pytest` | Command run with `uv run` |

Permissions: `contents: read`. The project needs a committed `uv.lock`.

### `container-publish.yaml`

| Input | Default | Meaning |
| --- | --- | --- |
| `image-name` | the calling repository | Image name without registry and tag |
| `context` | `.` | Build context |
| `dockerfile` | `Dockerfile` in the context | Path of the Dockerfile |
| `platforms` | `linux/amd64` | Target platforms |
| `push` | `true` | `false` builds and scans without publishing |
| `registry` | `ghcr.io` | Registry host |
| `aws-role-to-assume` | empty | IAM role assumed through OIDC to push to Amazon ECR |
| `aws-region` | empty | Region of the ECR registry |
| `fail-on-vulnerabilities` | `false` | Fail on fixable CRITICAL or HIGH vulnerabilities |

| Output | Meaning |
| --- | --- |
| `image` | Image name with registry, without a tag |
| `digest` | Digest of the published image |

Permissions: `contents: read`, `packages: write`, `id-token: write`,
`attestations: write`.

What it does, in order: build for the runner and scan with Trivy; log in
(`GITHUB_TOKEN` for the GitHub Container Registry, or an OIDC-assumed role for
Amazon ECR); build and push with an SBOM; sign the digest with cosign
(keyless); attach a SLSA build provenance attestation.

To publish to Amazon ECR, create an IAM role whose trust policy accepts
GitHub's OIDC provider for your repository and that may push to the ECR
repository, then pass its ARN. No access keys are stored anywhere:

```yaml
    with:
      registry: 123456789012.dkr.ecr.eu-west-2.amazonaws.com
      image-name: team/service
      aws-role-to-assume: arn:aws:iam::123456789012:role/github-publish
      aws-region: eu-west-2
```

#### Verify a published image

The signature and the provenance name **this** repository's workflow as the
builder, whatever repository called it. A consumer, or an admission
controller, can therefore require that an image was built by the reviewed
pipeline:

```sh
cosign verify ghcr.io/<owner>/<image>@sha256:<digest> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/\.github/workflows/container-publish\.yaml@'

gh attestation verify oci://ghcr.io/<owner>/<image>@sha256:<digest> \
  --owner <owner> \
  --signer-workflow ${{ values.destination.owner }}/${{ values.destination.repo }}/.github/workflows/container-publish.yaml
```

## Use an action

A composite action is one step of your own job:

```yaml
    steps:
      - uses: actions/checkout@<commit>
      - uses: ${{ values.destination.owner }}/${{ values.destination.repo }}/actions/setup-node-project@<commit> # v1.0.0
      - run: npm test
```

Each action's inputs are described in its `action.yml`.

## Private repositories

For repositories in your organisation to call workflows and actions of a
private repository, allow it under **Settings > Actions > General > Access**
of this repository.

## Contribute

Every push runs [`ci.yaml`](.github/workflows/ci.yaml):

1. **actionlint** checks syntax, expressions and embedded shell scripts.
2. **zizmor** audits security in its strictest persona: unpinned actions,
   excessive permissions, template injection, persisted credentials.
3. Each workflow and action runs against the projects in `test/fixtures/`.

Run the static checks locally:

```sh
actionlint
uvx zizmor==1.32.0 --persona pedantic .
```

Rules these files follow, and that reviews should hold new ones to:

- Third-party and first-party actions are pinned to a full commit hash, with
  the version in a comment.
- `permissions: {}` at the top of every workflow; each job asks for what it
  needs.
- Inputs and other caller-controlled values reach shell scripts through `env`,
  never by expanding an expression inside `run`.
- `persist-credentials: false` on checkout unless the job pushes.
- No long-lived secrets: `GITHUB_TOKEN` and OIDC only. A reusable workflow
  here declares no `secrets`.
- Add a fixture and a job in `ci.yaml` for every new workflow or action.

## Release

```sh
git tag v1.0.0 && git push origin v1.0.0
```

[`release.yaml`](.github/workflows/release.yaml) then moves the `v1` tag to
the same commit. Use semantic versioning: removing or renaming an input, or
requiring a new permission, is a major version.
