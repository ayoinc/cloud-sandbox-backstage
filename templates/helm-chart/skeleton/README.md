# ${{ values.name }}

${{ values.description }}

A Helm chart, tested on every push and published to the GitHub Container
Registry as a signed OCI artifact.

| | |
| --- | --- |
| Chart | [`charts/${{ values.name }}`](charts/${{ values.name }}) |
| Registry | `oci://ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }}` |
| Values | [chart README](charts/${{ values.name }}/README.md), validated by `values.schema.json` |

## Use the chart

```sh
helm install my-release oci://ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }} --version 0.1.0
```

Verify the signature and the provenance before installing:

```sh
cosign verify ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }}:0.1.0 \
  --certificate-identity-regexp '^https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/\.github/workflows/release\.yaml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

gh attestation verify oci://ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }}:0.1.0 \
  --repo ${{ values.destination.owner }}/${{ values.destination.repo }}
```

## Develop

Requirements: [Helm](https://helm.sh/) 4 and the
[helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin; for
the install test also [chart-testing](https://github.com/helm/chart-testing)
and [kind](https://kind.sigs.k8s.io/).

```sh
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.2.1 --verify=false

helm lint charts/${{ values.name }} --strict
helm unittest charts/${{ values.name }}
helm template my-release charts/${{ values.name }}       # see what would be applied

kind create cluster
ct install --config ct.yaml --all                # install, wait, run "helm test"
```

| Path | Content |
| --- | --- |
| `charts/${{ values.name }}/templates/` | Deployment, Service, ServiceAccount, NetworkPolicy; optional Ingress, HorizontalPodAutoscaler, PodDisruptionBudget |
| `charts/${{ values.name }}/values.yaml` | Defaults that satisfy the `restricted` Pod Security Standard |
| `charts/${{ values.name }}/values.schema.json` | JSON Schema of the values; unknown keys are rejected |
| `charts/${{ values.name }}/tests/` | helm-unittest suites |
| `charts/${{ values.name }}/ci/` | Values for the install test in CI |
| `ct.yaml` | chart-testing configuration |

When you add a value: give it a default in `values.yaml`, describe it in the
chart README, add it to `values.schema.json` (the schema rejects unknown
keys), and cover it with a unit test.

## CI

Every push runs `.github/workflows/ci.yaml`:

1. `helm lint --strict` and `ct lint` (YAML style, chart metadata, and, on
   branches, that a changed chart has a new version).
2. `helm unittest`.
3. Rendering with the default and the CI values, validated against the
   Kubernetes schemas with kubeconform.
4. `ct install` on a kind cluster: the chart is installed with each file in
   `ci/`, must become ready, and its `helm test` must pass.

## Release

1. Set `version` in `charts/${{ values.name }}/Chart.yaml` (and `appVersion` when the
   application changes), following semantic versioning. Merge to `main`.
2. Tag the commit `v<version>` and push the tag:

   ```sh
   git tag v0.1.0 && git push origin v0.1.0
   ```

`.github/workflows/release.yaml` then checks that the tag matches the chart
version, runs the tests, pushes the package to
`oci://ghcr.io/${{ values.destination.owner | lower }}/charts`, signs it with cosign using the
workflow's OIDC identity (no keys to manage), and attaches a build provenance
attestation. A published version is never overwritten.
