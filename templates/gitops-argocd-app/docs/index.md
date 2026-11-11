# GitOps Repository (Argo CD)

Creates the repository Argo CD deploys from: an app-of-apps root, an
ApplicationSet that turns directories into Applications, Kustomize overlays for
dev, staging and production, sync waves, and secrets wiring.

## What you get

| Path                        | Content                                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------- |
| `bootstrap/root.yaml`       | The root Application: the only manifest applied by hand                                                 |
| `argocd/projects.yaml`      | Two AppProjects with least-privilege sources and destinations                                           |
| `argocd/apps.yaml`          | ApplicationSet with a matrix of Git generators: one Application per `apps/<app>/overlays/<environment>` |
| `argocd/platform-*.yaml`    | The secrets controller, installed from its pinned Helm chart before the apps                            |
| `environments/*.yaml`       | Cluster and sync mode of each environment                                                               |
| `apps/podinfo/`             | A sample app with a hardened base and three overlays                                                    |
| `scripts/validate.sh`       | Renders every kustomization and validates it with kubeconform, including CRDs                           |
| `.github/workflows/ci.yaml` | yamllint, ShellCheck, validation and a Trivy scan on every push                                         |

## Parameters

| Parameter                     | Meaning                                                                                        |
| ----------------------------- | ---------------------------------------------------------------------------------------------- |
| Name                          | Repository, catalog entry, and the name of the AppProject, root Application and ApplicationSet |
| Argo CD Namespace             | Where Argo CD runs                                                                             |
| Sync Production Automatically | Off by default: production waits for a manual sync                                             |
| Secrets Management            | External Secrets Operator or Sealed Secrets                                                    |
| ClusterSecretStore Name       | External Secrets only: the store that `ExternalSecret`s refer to                               |

## Secrets management options

|                   | External Secrets Operator                   | Sealed Secrets                                              |
| ----------------- | ------------------------------------------- | ----------------------------------------------------------- |
| Where values live | Your secret manager                         | Encrypted in this repository                                |
| In Git            | A reference                                 | Ciphertext                                                  |
| Needs             | A ClusterSecretStore with workload identity | Access to the cluster to seal; a backup of the sealing keys |
| Rotation          | Change the value in the secret manager      | Re-seal and commit                                          |

## After creation

1. Give Argo CD read access to the new repository.
2. Enable the `Application` health check in `argocd-cm` (snippet in the
   repository's README) so that sync waves order the platform before the apps.
3. `kubectl apply -f bootstrap/root.yaml`.
4. Replace `apps/podinfo` with your own apps.
