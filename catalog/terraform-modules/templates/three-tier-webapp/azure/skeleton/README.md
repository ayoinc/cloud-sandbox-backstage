# ${{ values.projectName }} infrastructure

Azure three-tier web application infrastructure for **${{ values.projectName }}** (${{ values.environment }}), managed with Terraform.

| Tier        | What is created                                                                 |
| ----------- | ------------------------------------------------------------------------------- |
| Network     | Virtual network `${{ values.vnetAddressSpace }}` in `${{ values.location }}` with gateway, application and data subnets |
| Web         | Application Gateway{% if values.enableWaf %} on the WAF_v2 SKU with the OWASP rule set in Prevention mode{% else %} on the Standard_v2 SKU{% endif %}{% if values.enableFrontDoor %}, behind Azure Front Door{% endif %} |
| Application | {% if values.computeType == 'aks' %}AKS cluster with `${{ values.vmSize }}` nodes{% elif values.computeType == 'vmss' %}Scale set of `${{ values.vmSize }}` virtual machines{% else %}Container App in an internal Container Apps environment{% endif %}, ${{ values.minNodes }} to ${{ values.maxNodes }} in size |
| Data        | {% if values.databaseType == 'sql-database' %}Azure SQL Database on `${{ values.databaseSku }}`{% elif values.databaseType == 'postgresql' %}PostgreSQL flexible server on `${{ values.databaseSku }}`{% else %}Cosmos DB account, ${{ values.databaseSku }} capacity{% endif %}, without a public endpoint |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every compute type and database type against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an Azure subscription and stay skipped until it is configured:

| Setting                    | Kind     | Purpose                                                               |
| -------------------------- | -------- | --------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | secret   | Application the workflow signs in as through GitHub OIDC              |
| `AZURE_TENANT_ID`          | secret   | Microsoft Entra tenant of that application                            |
| `AZURE_SUBSCRIPTION_ID`    | secret   | Subscription the stack is deployed to                                 |
| `TF_STATE_RESOURCE_GROUP`  | variable | Resource group of the storage account that holds the Terraform state  |
| `TF_STATE_STORAGE_ACCOUNT` | variable | That storage account. The state is kept in its container `tfstate`    |
| `INFRACOST_API_KEY`        | secret   | Optional. Enables the cost estimate on pushes to `main`               |

The application needs a federated credential for this repository, the Contributor role on the subscription and the Storage Blob Data Contributor role on the state storage account. The `aks` compute type also assigns a role to the identity of the cluster, for which the application needs the Role Based Access Control Administrator role as well.

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

## Working locally

```bash
az login
export ARM_SUBSCRIPTION_ID=<subscription>
terraform init \
  -backend-config="resource_group_name=<state resource group>" \
  -backend-config="storage_account_name=<state storage account>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state storage account.
