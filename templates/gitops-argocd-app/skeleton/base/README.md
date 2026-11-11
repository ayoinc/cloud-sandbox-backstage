# ${{ values.name }}

${{ values.description }}

The GitOps repository that [Argo CD](https://argo-cd.readthedocs.io/) deploys
from. What is on `main` is what runs: a change is a commit, a rollback is a
revert.

## Layout

```text
bootstrap/root.yaml            the one manifest applied by hand (app of apps)
argocd/
  projects.yaml                AppProjects: what may be deployed where        wave -2
  platform-${{ values.secrets_backend }}.yaml{% if values.secrets_backend == 'external-secrets' %}  External Secrets Operator                      wave -1{% else %}    Sealed Secrets controller                      wave -1{% endif %}
  apps.yaml                    ApplicationSet: one Application per overlay    wave  0
environments/
  dev.yaml staging.yaml production.yaml   cluster and sync mode of each environment
apps/
  podinfo/
    base/                      manifests shared by every environment
    overlays/dev|staging|production/      what differs: replicas, image tag, settings
scripts/validate.sh            render and validate everything, as CI does
```

## Bootstrap

Prerequisites: a cluster with Argo CD in the `${{ values.argocd_namespace }}` namespace, and
read access for Argo CD to this repository (a repository credential or a
GitHub App; see the Argo CD documentation on private repositories).

```sh
kubectl apply -f bootstrap/root.yaml
```

The root Application syncs `argocd/`, which creates the projects, the platform
components and the ApplicationSet. The ApplicationSet then creates
`podinfo-dev`, `podinfo-staging` and `podinfo-production`.

### Sync waves between Applications

`argocd/` relies on sync waves to order Applications: projects, then platform,
then apps. Argo CD only waits for a child Application to be healthy if the
health check for the `Application` kind is enabled, which it is not by default.
Add this to the `argocd-cm` ConfigMap once per Argo CD installation:

```yaml
data:
  resource.customizations.health.argoproj.io_Application: |
    hs = {}
    hs.status = "Progressing"
    hs.message = ""
    if obj.status ~= nil and obj.status.health ~= nil then
      hs.status = obj.status.health.status
      if obj.status.health.message ~= nil then
        hs.message = obj.status.health.message
      end
    end
    return hs
```

## Daily work

| Task | Change |
| --- | --- |
| Deploy a new version | `images[].newTag` in `apps/<app>/overlays/<environment>/kustomization.yaml`, one environment at a time |
| Change a setting everywhere | `apps/<app>/base/` |
| Change a setting in one environment | A patch in that overlay |
| Add an app | Copy `apps/podinfo` to `apps/<app>`; the ApplicationSet creates its Applications |
| Add an environment | `environments/<name>.yaml`, an overlay per app, and a `*-<name>` destination in `argocd/projects.yaml` |
| Move an environment to another cluster | `cluster` in `environments/<name>.yaml` (the cluster must be registered in Argo CD) |
| Roll back | `git revert` the commit |

Validate before pushing:

```sh
scripts/validate.sh
```

### Sync policy

| Environment | Sync |
| --- | --- |
| dev, staging | Automatic, with pruning and self-healing |
| production | {% if values.production_auto_sync %}Automatic, with pruning and self-healing{% else %}Manual: Argo CD shows the difference, a person presses Sync{% endif %} |

Change it with `autoSync` in `environments/<name>.yaml`.

## Secrets
{% if values.secrets_backend == 'external-secrets' %}
Secrets stay in your secret manager. The repository contains `ExternalSecret`
resources that say which entry to read; the External Secrets Operator creates
the Kubernetes Secret from it.

- The operator is installed by `argocd/platform-external-secrets.yaml`.
- `ExternalSecret`s refer to the ClusterSecretStore `${{ values.secret_store }}`. Creating it
  is a one-time platform task that depends on your provider; authenticate it
  with workload identity rather than static keys.
- `podinfo` reads the entries `podinfo/dev`, `podinfo/staging` and
  `podinfo/production`. Create them (any JSON object of keys and values)
  before the first sync: the ExternalSecret is in sync wave -1, so the
  Deployment waits until the Secret exists.
{%- else %}
Secrets are committed encrypted, as `SealedSecret` resources that only the
controller in the cluster can decrypt.

- The controller is installed by `argocd/platform-sealed-secrets.yaml`.
- Create or replace a secret with the script, which needs `kubectl` access to
  the target cluster, `kubeseal` and `kustomize`:

  ```sh
  scripts/seal.sh podinfo dev PODINFO_UI_MESSAGE='hello from dev'
  git add apps/podinfo/overlays/dev && git commit -m "Seal podinfo config for dev"
  ```

- A sealed secret is bound to its cluster, namespace and name. Seal once per
  environment.
- Back up the controller's sealing keys (`kubectl get secret -n sealed-secrets
  -l sealedsecrets.bitnami.com/sealed-secrets-key`) to your secret manager:
  without them the committed secrets cannot be decrypted after a cluster loss.
{%- endif %}

Never commit a plain `Secret`. `scripts/validate.sh` and CI reject one.

## Guard rails

- The `${{ values.name }}` AppProject only accepts this repository as a source, only
  namespaces ending in `-dev`, `-staging` or `-production` as destinations,
  and no cluster-scoped resources except `Namespace`.
- Namespaces are created with the `restricted` Pod Security Standard enforced.
- CI lints the YAML, renders every overlay, validates the result against the
  Kubernetes and CRD schemas, and scans for misconfigurations and secrets.
- Protect `main` and require review: a merge is a deployment.
