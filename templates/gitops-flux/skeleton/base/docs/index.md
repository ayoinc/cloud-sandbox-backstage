# ${{ values.name }}

${{ values.description }}

## How deployment works

```text
commit on main ──> source-controller fetches ──> kustomize-controller applies ──> helm-controller releases
```

Each cluster runs Flux and watches one directory of this repository,
`clusters/<cluster>/`. The files there are Flux `Kustomization` resources that
point at the other directories:

| Kustomization | Path | Depends on | Content |
| --- | --- | --- | --- |
| `flux-system` | `clusters/<cluster>` | | Flux itself and the three below |
| `infra-controllers` | `infrastructure/controllers` | | Add-ons installed from Helm charts |
| `infra-configs` | `infrastructure/configs` | `infra-controllers` | Resources of the add-ons' CRDs |
| `apps` | `apps/<cluster>` | `infra-configs` | Workloads |

Every Kustomization has `wait: true`: it is ready only when what it applied is
ready, so the dependency order is real and not just an apply order.

## Clusters

| Cluster | Path | Apps overlay |
| --- | --- | --- |
| staging | `clusters/staging` | `apps/staging` |
| production | `clusters/production` | `apps/production` |

Both share `infrastructure/` and `apps/base/`. A version is promoted by
changing the tag in `apps/staging`, watching it, and then making the same
change in `apps/production`.

## Secrets
{% if values.secrets_backend == 'sops' %}
**SOPS with age.** Secrets are files named `*.sops.yaml`, encrypted for the
public key of the cluster they belong to (`.sops.yaml` maps paths to keys).
The `apps` Kustomization of each cluster decrypts them with the private key in
the `sops-age` Secret of the `flux-system` namespace. That Secret is created
by hand at bootstrap and is the one thing that is not in Git.

If a cluster is rebuilt, recreate `sops-age` from the copy of the private key
in your secret manager before bootstrapping.
{%- else %}
**External Secrets Operator.** The repository holds references, not values.
An `ExternalSecret` names an entry of the secret manager; the operator, using
the ClusterSecretStore `${{ values.secret_store }}`, writes it into a Kubernetes Secret
and refreshes it hourly.
{%- endif %}

## Operating

| Question | Command |
| --- | --- |
| Is everything reconciled? | `flux get all --all-namespaces` |
| Why is a Kustomization not ready? | `flux events --for Kustomization/apps` |
| Why did a release fail? | `flux logs --kind=HelmRelease --name=podinfo --namespace=podinfo` |
| What would this commit change? | `flux diff kustomization apps --path ./apps/staging` |
| Pause reconciliation during an incident | `flux suspend kustomization apps`, then `flux resume kustomization apps` |
| Which revision is applied? | `flux get kustomizations` shows the commit of each |

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `apps` stays `False` with `dependency not ready` | `infra-controllers` or `infra-configs` failed; start there |
| `decryption failed` | The `sops-age` Secret is missing or holds the key of another cluster |
| Release stuck after a bad upgrade | Fix it in Git; Flux retries and rolls back by itself. `flux reconcile helmrelease <name> --force` re-runs it |
| A manual `kubectl edit` disappears | Intended: drift is corrected. Make the change in Git |
