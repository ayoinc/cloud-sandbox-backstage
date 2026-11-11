# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of an Azure Key Vault for the **${{ values.envName }}** environment in **${{ values.location }}**:

- Vault `kv-${{ values.name }}-${{ values.envName }}` in the resource group `rg-${{ values.name }}-${{ values.envName }}`
- Azure RBAC for secrets, keys and certificates; access policies are not used
- Soft delete with purge protection: nothing can be destroyed for good before the retention ends
- Firewall that denies everything by default, with an optional private endpoint
- Optional audit log in Log Analytics

## Configuration Summary

| Setting | Value |
| --- | --- |
| Key vault | `kv-${{ values.name }}-${{ values.envName }}` |
| Resource group | `rg-${{ values.name }}-${{ values.envName }}` |
| Location | `${{ values.location }}` |
| Tier | `${{ values.skuName }}` |
| Permission model | Azure RBAC |
| Purge protection | Enabled |
| Soft delete | ${{ values.softDeleteDays }} days |
| Public network access | ${{ "Enabled, behind the firewall" if values.publicNetworkAccess else "Disabled" }} |

Every setting of every environment is in `environments/*.tfvars`.

## Using the Vault

Nobody can read or write the vault until they hold a data role, not even its creator:

1. Add object IDs to the role lists in `environments/${{ values.envName }}.tfvars` and apply:

    | Variable | Role | For |
    | --- | --- | --- |
    | `administrator_principal_ids` | Key Vault Administrator | People who manage everything in the vault |
    | `secrets_officer_principal_ids` | Key Vault Secrets Officer | Pipelines and people who write secrets |
    | `secrets_user_principal_ids` | Key Vault Secrets User | Workloads that read secrets |
    | `crypto_user_principal_ids` | Key Vault Crypto User | Workloads that use keys |
    | `certificates_officer_principal_ids` | Key Vault Certificates Officer | People who manage certificates |

2. Open a network path: list your address ranges in `allowed_ip_ranges` and set `public_network_access_enabled = true`, or set `private_endpoint_subnet_id` (and `private_dns_zone_id`) to reach the vault from a virtual network.

```bash
az keyvault secret set --vault-name kv-${{ values.name }}-${{ values.envName }} --name database-password --value "<value>"
az keyvault secret show --vault-name kv-${{ values.name }}-${{ values.envName }} --name database-password --query value -o tsv
```

Secret values do not belong in this repository or in the Terraform state: write them with the CLI, the portal or the system that generates them. Workloads read them with a managed identity that holds `Key Vault Secrets User`.

## Working Locally

```bash
# Check the configuration without touching Azure
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test

# Plan against the real state
az login
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=<storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}/${{ values.envName }}/terraform.tfstate"
terraform plan -var-file=environments/${{ values.envName }}.tfvars
```

The tests in `tests/` run against a mocked provider: they need no account and create nothing.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

| Job | What it does |
| --- | --- |
| Validate | `terraform fmt -check` and `terraform validate` |
| TFLint | Lints the configuration with the rules in `.tflint.hcl` |
| Terraform Tests | `terraform test` against a mocked provider |
| Security Scan | Trivy and Checkov; MEDIUM and above fail the run |
| Plan | Plans the `${{ values.envName }}` environment and attaches the plan to the run summary |
| Apply | Applies exactly that saved plan, after the approval of the GitHub environment |

The jobs before Plan need no cloud account. Plan and apply are skipped, with a notice, until the secrets below exist.

Run other environments, `destroy` (type `DESTROY` to confirm) and `drift-detection` from **Actions > Terraform > Run workflow**. Drift detection opens an issue when the deployed infrastructure no longer matches the configuration.

## Connecting the Pipeline to Azure

The pipeline signs in with OpenID Connect: GitHub issues a short-lived token for each run and Azure exchanges it for an access token. No client secret is stored anywhere.

1. Create an app registration (or a user-assigned managed identity) for this repository.
2. Add federated credentials for the subjects the pipeline uses:

    | Subject | Used by |
    | --- | --- |
    | `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:ref:refs/heads/main` | Plan and drift detection |
    | `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:dev` | Apply and destroy in `dev` |
    | `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:staging` | Apply and destroy in `staging` |
    | `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:environment:prod` | Apply and destroy in `prod` |

    ```bash
    az ad app federated-credential create --id <application-id> --parameters '{
      "name": "github-main",
      "issuer": "https://token.actions.githubusercontent.com",
      "subject": "repo:${{ values.destination.owner }}/${{ values.destination.repo }}:ref:refs/heads/main",
      "audiences": ["api://AzureADTokenExchange"]
    }'
    ```

3. Grant the identity these roles:

    | Role | Scope | Why |
    | --- | --- | --- |
    | `Contributor` | The subscription, or a resource group you create up front | Create the resource group and the vault |
    | `Role Based Access Control Administrator` | The same scope | Only when you list principals in the `*_principal_ids` variables |
    | `Storage Blob Data Contributor` | The state container | Read and write the Terraform state |

4. Register the resource providers once per subscription (the pipeline identity deliberately cannot): see the list under [Resource Providers](#resource-providers).
5. Add the repository secrets:

    | Secret | Description |
    | --- | --- |
    | `AZURE_CLIENT_ID` | Application (client) ID of the app registration or managed identity |
    | `AZURE_TENANT_ID` | Directory (tenant) ID |
    | `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into |
    | `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state |

    The state resource group and container default to `rg-terraform-state` and `tfstate`; override them with the repository variables `TF_STATE_RESOURCE_GROUP` and `TF_STATE_CONTAINER`.

6. Create the GitHub environments `dev`, `staging` and `prod` under **Settings > Environments** and add required reviewers to `prod`. Apply and destroy wait for that approval.

### Resource Providers

```bash
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network   # private endpoint
az provider register --namespace Microsoft.Insights  # audit log
```

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `sku_name` | `standard`, or `premium` for HSM-backed keys |
| `soft_delete_retention_days` | 7 to 90; fixed once the vault exists |
| `public_network_access_enabled`, `allowed_ip_ranges`, `allowed_subnet_ids` | Firewall |
| `trusted_services_bypass` | Lets trusted Azure services through the firewall, for customer-managed keys of other services |
| `private_endpoint_subnet_id`, `private_dns_zone_id` | Private endpoint |
| `*_principal_ids` | Data plane roles |
| `enabled_for_disk_encryption`, `enabled_for_deployment`, `enabled_for_template_deployment` | Access for Azure services acting on their own behalf |
| `log_analytics_workspace_id` | Destination of the audit log |

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the resource group |
| `key_vault_id` | Resource ID of the key vault |
| `key_vault_name` | Name of the key vault |
| `key_vault_uri` | URI of the key vault, for SDKs and secret references |
| `tenant_id` | Entra ID tenant that authenticates requests to the vault |
| `private_endpoint_ip_address` | Private IP address of the private endpoint, or null without one |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Authorisation | Azure RBAC; no access policies |
| Network | Public endpoint ${{ "enabled behind the firewall" if values.publicNetworkAccess else "disabled" }}; firewall default `Deny` |
| Recovery | Soft delete and purge protection |
| Audit | `AuditEvent` log to Log Analytics when `log_analytics_workspace_id` is set |

### Accepted Findings

| Finding | Reason |
| --- | --- |
| Checkov `CKV2_AZURE_32` | A private endpoint is opt-in; the firewall denies everything else |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_206:Reason the check does not apply
  #trivy:ignore:AZU-0012 Reason the check does not apply
}
```

## Operations

- **Recover a deleted secret**: `az keyvault secret recover --vault-name kv-${{ values.name }}-${{ values.envName }} --name <name>` within the retention period.
- **Destroy**: purge protection keeps the deleted vault, and its name, reserved until the retention ends. Recreating the environment before then recovers the old vault; to start clean, change the name.
- **Rotate**: give secrets an expiry date and keys a rotation policy when you create them; both are properties of the objects, not of the vault.
