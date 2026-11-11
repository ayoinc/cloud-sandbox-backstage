# ${{ values.name }}

${{ values.description }}

## How deployment works

```text
commit on main ──> Argo CD compares Git with the cluster ──> sync
```

1. `bootstrap/root.yaml` is an Argo CD Application that points at `argocd/`.
   It is the only thing applied by hand.
2. `argocd/` contains the AppProjects, the platform Application and an
   ApplicationSet. This is the *app of apps* pattern: Argo CD manages its own
   configuration from Git.
3. The ApplicationSet finds every directory `apps/<app>/overlays/<environment>`
   and creates the Application `<app>-<environment>`, which deploys that
   overlay into the namespace `<app>-<environment>` of the cluster named in
   `environments/<environment>.yaml`.

## Ordering with sync waves

| Level | Wave | What |
| --- | --- | --- |
| Root Application | -2 | AppProjects |
| | -1 | Platform: {% if values.secrets_backend == 'external-secrets' %}External Secrets Operator{% else %}Sealed Secrets controller{% endif %} |
| | 0 | ApplicationSet and its Applications |
| Each app | -1 | {% if values.secrets_backend == 'external-secrets' %}`ExternalSecret`{% else %}`SealedSecret`{% endif %}, so the Secret exists before the pods |
| | 0 | Deployment, Service |

Argo CD applies a wave only when the previous one is healthy. For waves of
Applications this needs the `Application` health check in `argocd-cm`; the
README has the snippet.

## Environments

| Environment | Namespace pattern | Sync |
| --- | --- | --- |
| dev | `<app>-dev` | Automatic |
| staging | `<app>-staging` | Automatic |
| production | `<app>-production` | {% if values.production_auto_sync %}Automatic{% else %}Manual{% endif %} |

Promotion is a pull request that changes the image tag of the next
environment's overlay. Each environment has its own file, so the history of
what ran where is the Git history of that file.

## Secrets
{% if values.secrets_backend == 'external-secrets' %}
**External Secrets Operator.** The repository holds references, not values.
An `ExternalSecret` names an entry of the secret manager; the operator, using
the ClusterSecretStore `${{ values.secret_store }}`, writes its keys into a Kubernetes
Secret and refreshes it hourly. Rotating a secret is a change in the secret
manager; pods pick it up on their next restart.
{%- else %}
**Sealed Secrets.** The repository holds encrypted values. `scripts/seal.sh`
encrypts with the public key of the controller in the target cluster and
writes a `SealedSecret`; the controller decrypts it into a Kubernetes Secret.
Rotating a secret is a new run of the script and a commit. The sealing keys
are the one thing to back up outside Git.
{%- endif %}

## Access model

| Project | Sources | Destinations | Cluster-scoped resources |
| --- | --- | --- | --- |
| `${{ values.name }}` | This repository | `*-dev`, `*-staging`, `*-production` | `Namespace` only |
| `${{ values.name }}-platform` | The chart repository of the platform component | Its own namespace | Any (CRDs, cluster roles) |

## Troubleshooting

| Symptom | Check |
| --- | --- |
| No Application appears for a new overlay | `kubectl describe applicationset ${{ values.name }}-apps -n ${{ values.argocd_namespace }}`; is there an `environments/<name>.yaml`? |
| Application is `OutOfSync` and stays so | Automatic sync is off for that environment; sync it in the UI or with `argocd app sync` |
| Sync stops at the secret | {% if values.secrets_backend == 'external-secrets' %}`kubectl describe externalsecret -n <namespace>`: does the remote entry exist, can the store read it?{% else %}`kubectl describe sealedsecret -n <namespace>`: was it sealed for this cluster, namespace and name?{% endif %} |
| `application destination ... is not permitted in project` | The namespace does not match the destinations in `argocd/projects.yaml` |
| Platform syncs after the apps | The `Application` health check is missing from `argocd-cm` |
