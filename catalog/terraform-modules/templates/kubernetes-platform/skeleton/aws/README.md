# ${{ values.projectName }} Kubernetes platform

Kubernetes platform for **${{ values.projectName }}** (${{ values.environment }}) on Amazon EKS in `${{ values.awsRegion }}`, managed with Terraform.

| Part       | What is created                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Network    | VPC with three public and three private subnets, {% if values.environment == 'production' %}one NAT gateway per availability zone{% else %}one shared NAT gateway{% endif %} |
| Cluster    | EKS ${{ values.kubernetesVersion }} with the VPC CNI{% if values.enableNetworkPolicies %} (network policies enforced){% endif %}, CoreDNS, kube-proxy and the EBS CSI driver |
| Nodes      | Managed node group of ${{ values.nodeSize }} nodes, ${{ values.minNodes }} to ${{ values.maxNodes if values.maxNodes > values.minNodes else values.minNodes }}, scaled by the cluster autoscaler |
| Storage    | Default StorageClass `gp3` (encrypted EBS volumes)                                                |
| Components | {% if values.enableGitOps %}Argo CD, {% endif %}{% if values.enableObservability %}Prometheus, Grafana and Loki, {% endif %}{% if values.enableServiceMesh %}Istio, {% endif %}{% if values.enableCertManager %}cert-manager, {% endif %}{% if values.enableExternalDns %}external-dns, {% endif %}{% if values.enableIngress != 'none' %}${{ values.enableIngress }} ingress controller, {% endif %}{% if values.enableOPA %}OPA Gatekeeper, {% endif %}{% if values.enableVaultIntegration %}Vault Secrets Operator, {% endif %}see [`docs/components.md`](docs/components.md) |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Layout

| File                                                    | Content                                                        |
| ------------------------------------------------------- | -------------------------------------------------------------- |
| `network.tf`                                            | VPC, subnets, NAT gateways                                     |
| `cluster.tf`                                            | EKS cluster, add-ons, node group, StorageClass                 |
| `identity.tf`                                           | IAM roles of the EBS CSI driver, cluster autoscaler and external-dns |
| `autoscaling.tf`                                        | Cluster autoscaler                                             |
| `platform.tf`, `platform-*.tf`, `variables-platform.tf` | Platform components installed into the cluster with Helm       |

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every node size, ingress controller and component choice against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an AWS account and stay skipped until it is configured:

| Setting             | Kind     | Purpose                                                 |
| ------------------- | -------- | ------------------------------------------------------- |
| `AWS_ROLE_ARN`      | secret   | IAM role the workflow assumes through GitHub OIDC       |
| `TF_STATE_BUCKET`   | variable | S3 bucket that holds the Terraform state                |
| `INFRACOST_API_KEY` | secret   | Optional. Enables the cost estimate on pushes to `main` |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked. The role in `AWS_ROLE_ARN` creates the cluster and is its administrator.

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state bucket. Planning against an existing cluster needs the AWS CLI, which issues the token for the Kubernetes API.
