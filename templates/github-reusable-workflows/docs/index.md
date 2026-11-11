# Reusable GitHub Actions Workflows

Creates a repository of reusable workflows and composite actions that other
repositories call, so that build, test and publish are implemented once and
reviewed once.

## What you get

| Path                                       | Content                                                                                              |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `.github/workflows/node-ci.yaml`           | Reusable workflow: install, audit, lint, test and build a Node.js project                            |
| `.github/workflows/python-ci.yaml`         | Reusable workflow: install, lint, type check and test a Python project managed with uv               |
| `.github/workflows/container-publish.yaml` | Reusable workflow: build, scan, publish, sign with cosign (keyless) and attest SLSA build provenance |
| `actions/`                                 | Composite actions: set up a Node.js project, set up a Python project, smoke-test a container         |
| `.github/workflows/ci.yaml`                | actionlint, zizmor, and a run of every workflow and action against fixtures                          |
| `.github/workflows/release.yaml`           | Moves the major version tag when a release is tagged                                                 |
| `.github/dependabot.yml`                   | Weekly updates of the pinned action commits                                                          |
| `test/fixtures/`                           | Small Node.js, Python and container projects the tests run against                                   |

## Parameters

| Parameter               | Meaning                                                           |
| ----------------------- | ----------------------------------------------------------------- |
| Name                    | Repository and catalog entry                                      |
| Default Node.js Version | Used by the Node.js workflow and action when the caller sets none |
| Default Python Version  | Used by the Python workflow and action when the caller sets none  |

## Security properties

- Every action is pinned to a full commit hash.
- Workflows start from `permissions: {}`; jobs request what they use.
- Caller input reaches shell scripts through environment variables only.
- Publishing uses `GITHUB_TOKEN` and OIDC: there are no stored registry or
  cloud credentials, and the reusable workflows declare no secrets.
- Images are signed, and carry provenance that names the reusable workflow as
  the builder, so consumers can require images built by this pipeline.

## After creation

1. If the repository is private, allow access from the repositories that will
   call it (Settings > Actions > General > Access).
2. Tag `v1.0.0`. Callers reference a workflow as
   `<owner>/<repository>/.github/workflows/<file>@<commit>`.
3. Add your own workflows next to the three provided, each with a fixture and
   a job in `ci.yaml`.
