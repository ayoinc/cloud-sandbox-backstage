# ${{ values.projectName }} Kubernetes platform

Azure Kubernetes Service cluster and platform components for **${{ values.projectName }}** (${{ values.environment }}), managed with Terraform.
{%- set components = [] %}
{%- if values.enableGitOps %}{% set components = components.concat(['Argo CD']) %}{% endif %}
{%- if values.enableObservability %}{% set components = components.concat(['Prometheus, Grafana and Loki']) %}{% endif %}
{%- if values.enableServiceMesh %}{% set components = components.concat(['Istio']) %}{% endif %}
{%- if values.enableCertManager %}{% set components = components.concat(['cert-manager']) %}{% endif %}
{%- if values.enableExternalDns %}{% set components = components.concat(['external-dns']) %}{% endif %}
{%- if values.enableIngress == 'nginx' %}{% set components = components.concat(['ingress-nginx']) %}{% endif %}
{%- if values.enableIngress == 'traefik' %}{% set components = components.concat(['Traefik']) %}{% endif %}
{%- if values.enableOPA %}{% set components = components.concat(['OPA Gatekeeper']) %}{% endif %}
{%- if values.enableVaultIntegration %}{% set components = components.concat(['Vault Secrets Operator']) %}{% endif %}

| Layer      | What is created                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Network    | Virtual network in `${{ values.azureRegion }}` with a subnet for the nodes; pods use an overlay network |
| Cluster    | AKS with Kubernetes ${{ values.kubernetesVersion }}, ${{ values.minNodes }} to ${{ values.maxNodes }} `${{ values.nodeSize }}` nodes across availability zones{% if values.enableNetworkPolicies %}, network policies enforced by Cilium{% endif %} |
| Identity   | Microsoft Entra ID sign-in with Azure RBAC, workload identity{% if values.enableExternalDns %}, managed identity for external-dns{% endif %} |
| Logs       | Control plane logs in a Log Analytics workspace                                                   |
| Components | {% if components | length %}${{ components | join(', ') }}, installed with Helm{% else %}No Helm chart was selected{% endif %}{% if values.enablePodSecurityPolicies %}; Pod Security Standards on the platform namespaces{% endif %}{% if values.enableNetworkPolicies %}; default-deny network policies{% endif %} (see [`docs/components.md`](docs/components.md)) |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every node size, ingress controller and component combination against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an Azure subscription and stay skipped until it is configured:

| Setting                    | Kind     | Purpose                                                              |
| -------------------------- | -------- | -------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application or managed identity the workflow signs in as (GitHub OIDC) |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra ID tenant of that identity                           |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription of that identity                                        |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state |
| `TF_STATE_STORAGE_ACCOUNT` | variable | Storage account with the container `tfstate`                         |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`              |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

The identity needs the roles Owner (or Contributor plus Role Based Access Control Administrator) on the subscription, because the stack assigns roles to the identities it creates, and Storage Blob Data Contributor on the state container.

## Working locally

```bash
az login
terraform init \
  -backend-config="resource_group_name=<state resource group>" \
  -backend-config="storage_account_name=<state storage account>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state.

After an apply, `terraform output -raw get_credentials_command` prints the command that adds the cluster to your kubeconfig.
