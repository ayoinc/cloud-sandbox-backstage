# ${{ values.projectName }} Kubernetes platform

Kubernetes platform for **${{ values.projectName }}** (${{ values.environment }}) on Google Kubernetes Engine in `${{ values.gcpRegion }}`, project `${{ values.gcpProjectId }}`, managed with Terraform.

| Part       | What is created                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Network    | VPC with one subnet for the nodes and secondary ranges for pods and Services, Cloud NAT           |
| Cluster    | Regional GKE ${{ values.kubernetesVersion }} cluster with private nodes and Workload Identity{% if values.enableNetworkPolicies %}, GKE Dataplane V2 (network policies enforced){% endif %} |
| Nodes      | Node pool of ${{ values.nodeSize }} nodes, ${{ values.minNodes }} to ${{ values.maxNodes if values.maxNodes >= values.minNodes else values.minNodes }} over three zones, scaled by the GKE cluster autoscaler |
| Storage    | StorageClass `standard-rwo` (balanced persistent disks)                                           |
| Components | {% if values.enableGitOps %}Argo CD, {% endif %}{% if values.enableObservability %}Prometheus, Grafana and Loki, {% endif %}{% if values.enableServiceMesh %}Istio, {% endif %}{% if values.enableCertManager %}cert-manager, {% endif %}{% if values.enableExternalDns %}external-dns, {% endif %}{% if values.enableIngress != 'none' %}${{ values.enableIngress }} ingress controller, {% endif %}{% if values.enableOPA %}OPA Gatekeeper, {% endif %}{% if values.enableVaultIntegration %}Vault Secrets Operator, {% endif %}see [`docs/components.md`](docs/components.md) |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Layout

| File                                                    | Content                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| `main.tf`                                               | Names, node sizes, required Google APIs                        |
| `network.tf`                                            | VPC, subnet, firewall rule, Cloud Router, Cloud NAT            |
| `cluster.tf`                                            | GKE cluster and node pool                                      |
| `identity.tf`                                           | Service accounts of the nodes and of external-dns              |
| `platform.tf`, `platform-*.tf`, `variables-platform.tf` | Platform components installed into the cluster with Helm       |

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every node size, ingress controller and component choice against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to the Google Cloud project and stay skipped until it is configured:

| Setting                          | Kind     | Purpose                                                 |
| -------------------------------- | -------- | ------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret   | Workload identity provider that trusts this repository  |
| `GCP_SERVICE_ACCOUNT`            | secret   | Service account the workflow acts as                    |
| `TF_STATE_BUCKET`                | variable | Cloud Storage bucket that holds the Terraform state     |
| `INFRACOST_API_KEY`              | secret   | Optional. Enables the cost estimate on pushes to `main` |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked. The roles the service account needs are listed in [`docs/index.md`](docs/index.md).

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state bucket. Planning against an existing cluster uses your application default credentials (`gcloud auth application-default login`) for Google Cloud and for the Kubernetes API.
