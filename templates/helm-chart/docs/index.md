# Helm Chart

Creates a repository with a production-grade Helm chart, its tests and the
workflows that publish it as a signed OCI artifact.

## What you get

| Path                               | Content                                                                                                                                  |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `charts/<name>/`                   | The chart: Deployment, Service, ServiceAccount and NetworkPolicy, with optional Ingress, HorizontalPodAutoscaler and PodDisruptionBudget |
| `charts/<name>/values.schema.json` | JSON Schema of the values. Unknown keys and wrong types fail at install time                                                             |
| `charts/<name>/tests/`             | helm-unittest suites for every template and for the schema                                                                               |
| `charts/<name>/ci/`                | Values for the install test                                                                                                              |
| `ct.yaml`                          | chart-testing configuration                                                                                                              |
| `.github/workflows/ci.yaml`        | Lint, unit tests, schema validation and an install test on kind, on every push                                                           |
| `.github/workflows/release.yaml`   | On a `v*` tag: push to `oci://ghcr.io/<owner>/charts`, sign with cosign (keyless) and attest provenance                                  |

## Parameters

| Parameter                  | Meaning                                     |
| -------------------------- | ------------------------------------------- |
| Chart Name                 | Chart, repository and catalog entry         |
| Container Image Repository | Default image of the chart, without a tag   |
| Application Version        | Initial `appVersion`: the default image tag |
| Container Port             | Port the application listens on             |

## Defaults worth knowing

- The pod satisfies the `restricted` Pod Security Standard: non-root,
  read-only root filesystem, no capabilities, `RuntimeDefault` seccomp.
- Nothing is exposed outside the cluster: the Service is `ClusterIP` and the
  Ingress is off.
- A NetworkPolicy limits ingress to the container port.
- The ServiceAccount token is not mounted.

## Releasing

Tag a commit `v<chart version>`. The release workflow uses the workflow's
OIDC identity for the signature and the provenance, and `GITHUB_TOKEN` for the
registry: there are no long-lived credentials to create or rotate.

## After creation

1. Adjust the probes in `values.yaml` to your application's health endpoints.
2. Make sure the default image exists and can be pulled by your clusters.
3. Push; CI must be green. Then tag `v0.1.0` to publish the first version.
