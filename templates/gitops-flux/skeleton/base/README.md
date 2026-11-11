# ${{ values.name }}

${{ values.description }}

The GitOps repository that [Flux](https://fluxcd.io/) reconciles the clusters
from. What is on `main` is what runs: a change is a commit, a rollback is a
revert.

## Layout

```text
clusters/
  staging/                 what the staging cluster reconciles
    infrastructure.yaml      Kustomizations: infra-controllers -> infra-configs
    apps.yaml                Kustomization: apps (after infra-configs)
    flux-system/             written by "flux bootstrap"; do not edit by hand
  production/              the same for the production cluster
infrastructure/
  controllers/             cluster add-ons installed from pinned charts{% if values.secrets_backend == 'external-secrets' %} (cert-manager, External Secrets){% else %} (cert-manager){% endif %}
  configs/                 resources that need the controllers' CRDs (ClusterIssuer)
apps/
  base/podinfo/            a release shared by every cluster
  staging/                 what staging changes: version, replicas, settings
  production/              what production changes
{%- if values.secrets_backend == 'sops' %}
.sops.yaml                 which age key encrypts which path
{%- endif %}
scripts/validate.sh        render and validate everything, as CI does
```

Dependencies are explicit: `infra-controllers` is ready before `infra-configs`
is applied, and `apps` waits for both.

## Bootstrap

Prerequisites: the [Flux CLI](https://fluxcd.io/flux/installation/) 2.10 or
later, `kubectl` access to the cluster, and a GitHub token that can administer
this repository (it is used once, to add a deploy key; Flux then pulls over
SSH with that read-only key).
{% if values.secrets_backend == 'sops' %}
Create the decryption key in the cluster **before** bootstrapping, from the
private half of the age key pair whose public half is in `.sops.yaml`:

```sh
kubectl create namespace flux-system
kubectl create secret generic sops-age \
  --namespace flux-system \
  --from-file=age.agekey=/path/to/staging.agekey
```

Keep the private key in your secret manager. It never goes into Git.
{% endif %}
```sh
export GITHUB_TOKEN=<token>
flux bootstrap github \
  --owner=${{ values.destination.owner }} \
  --repository=${{ values.destination.repo }} \
  --branch=main \
  --path=clusters/staging \
  --read-write-key=false
```

Repeat with the production context and `--path=clusters/production`. Bootstrap
commits `clusters/<cluster>/flux-system/` to this repository and from then on
Flux manages itself from Git.

```sh
flux get kustomizations --watch
flux get helmreleases --all-namespaces
```

## Daily work

| Task | Change |
| --- | --- |
| Deploy a new app version | The tag patch in `apps/<cluster>/kustomization.yaml`: staging first, then production |
| Change a setting on every cluster | `apps/base/<app>/release.yaml` |
| Change a setting on one cluster | A patch in `apps/<cluster>/kustomization.yaml` |
| Add an app | A directory in `apps/base/`, and a line in the `resources` of each cluster that runs it |
| Add a cluster add-on | A file in `infrastructure/controllers/`, listed in its `kustomization.yaml` |
| Upgrade an add-on | The `ref.tag` of its `OCIRepository` |
| Add a cluster | Copy `clusters/staging` (without `flux-system/`) and `apps/staging`, then bootstrap with the new path |
| Roll back | `git revert` the commit |

Validate before pushing:

```sh
scripts/validate.sh
```

Apply a change without waiting for the next interval:

```sh
flux reconcile kustomization apps --with-source
```

## Secrets
{% if values.secrets_backend == 'sops' %}
Secrets are committed encrypted with [SOPS](https://github.com/getsops/sops)
and [age](https://github.com/FiloSottile/age). Flux decrypts them in the
cluster with the key in the `sops-age` Secret.

Create a secret for one cluster. The file name must end in `.sops.yaml` and
the file must live under that cluster's directory, so that `.sops.yaml` picks
the right key:

```sh
kubectl create secret generic podinfo-values \
  --namespace podinfo \
  --from-literal=values.yaml='ui: { message: "a value nobody else should read" }' \
  --dry-run=client --output yaml > apps/staging/podinfo-values.sops.yaml

sops --encrypt --in-place apps/staging/podinfo-values.sops.yaml
```

Add `podinfo-values.sops.yaml` to the `resources` of
`apps/staging/kustomization.yaml` and commit. Only `data` and `stringData` are
encrypted, so the diff stays reviewable. Edit later with
`sops apps/staging/podinfo-values.sops.yaml`, which needs the private key in
`SOPS_AGE_KEY_FILE`.

| Rule | Why |
| --- | --- |
| One key pair per cluster | A leaked staging key does not expose production |
| Private keys only in the cluster and the secret manager | Git holds ciphertext and public keys |
| Rotate with `sops updatekeys` after changing `.sops.yaml` | Re-encrypts existing files for the new recipients |
{%- else %}
Secrets stay in your secret manager. The repository contains `ExternalSecret`
resources that say which entry to read; the External Secrets Operator creates
the Kubernetes Secret from it.

- The operator is installed by `infrastructure/controllers/external-secrets.yaml`.
- `ExternalSecret`s refer to the ClusterSecretStore `${{ values.secret_store }}`. Add its
  manifest to `infrastructure/configs/`; it depends on your provider, and
  should authenticate with workload identity rather than static keys.
- `podinfo` reads chart values from the entries `podinfo/staging` and
  `podinfo/production`. Each holds a YAML document, for example
  `ui: { message: "a value nobody else should read" }`.
{%- endif %}

Never commit a plain `Secret`. `scripts/validate.sh` and CI reject one.

## Guard rails

- Charts are pinned to exact versions and pulled from OCI registries.
- `prune: true` removes from the cluster what is removed from Git.
- Helm releases detect and correct drift, run the chart's tests, and roll back
  a failed upgrade.
- CI lints the YAML, renders every overlay, validates it against the
  Kubernetes, Flux and CRD schemas, installs the infrastructure layer on a
  kind cluster, and scans for misconfigurations and secrets.
- Protect `main` and require review: a merge is a deployment.
