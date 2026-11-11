# GitOps Repository (Flux)

Creates the repository that Flux v2 reconciles clusters from, in the layout
the Flux project recommends for a mono-repository: `clusters/`,
`infrastructure/` and `apps/`, with a staging and a production cluster.

## What you get

| Path                                | Content                                                                                |
| ----------------------------------- | -------------------------------------------------------------------------------------- |
| `clusters/<cluster>/`               | Flux Kustomizations with explicit dependencies: controllers, then configs, then apps   |
| `infrastructure/controllers/`       | cert-manager, and External Secrets when chosen, from pinned OCI charts                 |
| `infrastructure/configs/`           | A ClusterIssuer, applied once the controllers are ready                                |
| `apps/base/podinfo/`                | A sample HelmRelease with drift detection, tests and remediation                       |
| `apps/staging/`, `apps/production/` | Kustomize overlays per cluster                                                         |
| `.sops.yaml`                        | SOPS only: one age key per cluster, selected by path                                   |
| `scripts/validate.sh`               | Renders every kustomization and validates it with kubeconform and the Flux CRD schemas |
| `.github/workflows/ci.yaml`         | yamllint, ShellCheck, validation, an install test on kind, and a Trivy scan            |

## Parameters

| Parameter                            | Meaning                                                                                                                             |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Name                                 | Repository and catalog entry                                                                                                        |
| Secrets Management                   | SOPS with age, or External Secrets Operator                                                                                         |
| age Public Key (staging, production) | SOPS only. Create each pair with `age-keygen`; enter the public keys. The private keys go into the clusters and your secret manager |
| ClusterSecretStore Name              | External Secrets only                                                                                                               |

## Secrets management options

|                   | SOPS with age                          | External Secrets Operator                   |
| ----------------- | -------------------------------------- | ------------------------------------------- |
| Where values live | Encrypted in this repository           | Your secret manager                         |
| Extra controller  | None: Flux decrypts                    | External Secrets Operator                   |
| Needs             | One private key per cluster, backed up | A ClusterSecretStore with workload identity |
| Rotation          | `sops` edit and commit                 | Change the value in the secret manager      |

## After creation

1. For SOPS, create the `sops-age` Secret in each cluster from its private key.
2. Run `flux bootstrap github` once per cluster with `--path=clusters/<cluster>`;
   the README of the new repository has the exact commands.
3. Replace `apps/base/podinfo` with your own apps.
