# ${{ values.name }}

${{ values.description }}

## Overview

| | |
| --- | --- |
| Chart | `${{ values.name }}` |
| Registry | `oci://ghcr.io/${{ values.destination.owner | lower }}/charts/${{ values.name }}` |
| Default image | `${{ values.image_repository }}` |
| Kubernetes | 1.31 or later |

## What the chart deploys

| Resource | When | Notes |
| --- | --- | --- |
| Deployment | Always | One container; non-root, read-only root filesystem, no capabilities |
| Service | Always | `ClusterIP` on port 80 to the named container port |
| ServiceAccount | `serviceAccount.create` (default) | Token not mounted unless `serviceAccount.automount` |
| NetworkPolicy | `networkPolicy.enabled` (default) | Ingress to the container port only |
| Ingress | `ingress.enabled` | Off by default |
| HorizontalPodAutoscaler | `autoscaling.enabled` | CPU and optional memory target |
| PodDisruptionBudget | `podDisruptionBudget.enabled` | |

## Versioning

- `version` is the chart's version. Any change to templates, defaults or the
  schema increases it: a patch for fixes, a minor for new optional values, a
  major when existing values change meaning or are removed.
- `appVersion` is the application version and the default image tag.
- Consumers pin a chart version and, in production, an image digest
  (`image.digest`).

## Supply chain

The release workflow publishes with short-lived credentials only:

| Step | Identity |
| --- | --- |
| Push to the registry | The workflow's `GITHUB_TOKEN`, scoped to `packages: write` |
| Signature | cosign keyless: a certificate issued for the workflow's OIDC identity, recorded in the transparency log |
| Provenance | A build provenance attestation stored with the package |

Consumers verify both with the commands in the repository's README. With Flux,
set `verify.provider: cosign` on the `OCIRepository`; with Argo CD, verify in
the pipeline that promotes the version.

## Testing levels

| Level | Tool | Catches |
| --- | --- | --- |
| Static | `helm lint`, `ct lint`, `values.schema.json` | Malformed charts, wrong value types, unknown keys |
| Unit | helm-unittest | Templates that render the wrong manifest for a set of values |
| Schema | kubeconform | Manifests the API server would reject |
| Install | `ct install` on kind | Pods that do not become ready, a failing `helm test` |
