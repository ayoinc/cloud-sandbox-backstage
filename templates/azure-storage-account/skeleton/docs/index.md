# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of an Azure Storage account for the **${{ values.envName }}** environment in **${{ values.location }}**:

- General-purpose v2 account, `st${{ values.name | replace("-", "") }}${{ values.envName }}`, in the resource group `rg-${{ values.name }}-${{ values.envName }}`
- Entra ID is the only way in: shared keys, anonymous access and local users are disabled
- Firewall that denies everything by default, with an optional private endpoint
- Blob versioning, change feed and soft delete for blobs and containers
- Lifecycle policy that tiers blobs and expires previous versions
- Encryption at rest twice (service and infrastructure), with an optional customer-managed key

## Configuration Summary

| Setting | Value |
| --- | --- |
| Storage account | `st${{ values.name | replace("-", "") }}${{ values.envName }}` |
| Resource group | `rg-${{ values.name }}-${{ values.envName }}` |
| Location | `${{ values.location }}` |
| Redundancy | `${{ values.replicationType }}` |
| Access tier | `${{ values.accessTier }}` |
| Containers | `${{ values.containerNames | join("`, `") }}` |
| Versioning | ${{ "Enabled" if values.versioning else "Disabled" }} |
| Soft delete | ${{ values.softDeleteDays }} days |
| Public network access | Disabled |

Every setting of every environment is in `environments/*.tfvars`.

## Using the Account

The account has no keys and no connection string. Everything authenticates with Entra ID and needs a data role:

1. Add the object IDs of users, groups or managed identities to `blob_data_contributor_principal_ids` or `blob_data_reader_principal_ids` and apply.
2. Open a network path: list your address ranges in `allowed_ip_ranges` and set `public_network_access_enabled = true`, or set `private_endpoint_subnet_id` (and `private_dns_zone_id`) to reach the account from a virtual network.

```bash
az storage blob upload \
  --account-name st${{ values.name | replace("-", "") }}${{ values.envName }} \
  --container-name ${{ values.containerNames | first }} \
  --name hello.txt --file hello.txt \
  --auth-mode login
```

Applications use `DefaultAzureCredential` with the blob endpoint from `terraform output primary_blob_endpoint`.

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
    | `Contributor` | The subscription, or a resource group you create up front | Create the resource group and the storage account |
    | `Role Based Access Control Administrator` | The same scope | Only when you assign data roles or use a customer-managed key |
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
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network          # private endpoint
az provider register --namespace Microsoft.ManagedIdentity  # customer-managed key
az provider register --namespace Microsoft.Insights         # diagnostic logs
```

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `replication_type` | `LRS`, `ZRS`, `GRS`, `RAGRS`, `GZRS` or `RAGZRS` |
| `container_names` | Private containers to create |
| `versioning_enabled`, `soft_delete_retention_days` | Protection against overwrites and deletions |
| `cool_after_days`, `archive_after_days`, `expire_after_days` | Lifecycle steps; `null` switches one off. Archiving needs `LRS`, `GRS` or `RAGRS` |
| `noncurrent_version_retention_days` | How long previous versions and snapshots are kept |
| `public_network_access_enabled`, `allowed_ip_ranges`, `allowed_subnet_ids` | Firewall |
| `private_endpoint_subnet_id`, `private_dns_zone_id` | Private endpoint for the blob service |
| `customer_managed_key` | Key Vault and key that encrypt the account |
| `blob_data_contributor_principal_ids`, `blob_data_reader_principal_ids` | Who may use the data |
| `log_analytics_workspace_id` | Destination of the blob access logs |

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the resource group |
| `storage_account_id` | Resource ID of the storage account |
| `storage_account_name` | Name of the storage account |
| `primary_blob_endpoint` | URL of the blob service |
| `container_names` | Names of the blob containers |
| `private_endpoint_ip_address` | Private IP address of the blob private endpoint, or null without one |
| `encryption_identity_principal_id` | Object ID of the identity that reads the customer-managed key, or null without one |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Authentication | Entra ID only; shared keys, account SAS and anonymous access are disabled |
| Network | Public endpoint disabled; firewall default `Deny`; trusted Azure services may bypass it |
| Transport | HTTPS only, TLS 1.2 minimum |
| Encryption at rest | Service and infrastructure encryption; optional customer-managed key |
| Recovery | Versioning, change feed, soft delete for blobs and containers |

### Customer-Managed Key

Set `customer_managed_key` to a Key Vault that uses Azure RBAC and has purge protection, and to the **versionless** ID of an RSA key in it, so the account follows key rotation:

```hcl
customer_managed_key = {
  key_vault_id     = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>"
  key_vault_key_id = "https://<vault>.vault.azure.net/keys/<key>"
}
```

Terraform creates a user-assigned identity, grants it `Key Vault Crypto Service Encryption User` on the vault and points the account at the key.

### Accepted Findings

Each exception is declared on the storage account, with its reason:

| Finding | Reason |
| --- | --- |
| Checkov `CKV2_AZURE_1` | A customer-managed key is opt-in |
| Checkov `CKV2_AZURE_33` | A private endpoint is opt-in; the firewall denies everything else |
| Checkov `CKV_AZURE_206` | Redundancy is chosen per environment |
| Checkov `CKV_AZURE_33` | The queue service is unused and unreachable without an Entra ID role |
| Checkov `CKV2_AZURE_41` | With shared keys disabled only user delegation SAS remains, which Azure limits to seven days |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_206:Reason the check does not apply
  #trivy:ignore:AZU-0012 Reason the check does not apply
}
```

## Operations

- **Restore a deleted blob or container**: within the soft delete period, `az storage blob undelete` or `az storage container restore` with `--auth-mode login`.
- **Restore a previous version**: copy the version over the current blob (`az storage blob copy start --source-uri "<blob-url>?versionId=<id>"`).
- **Destroy**: the resource group is not deleted while it holds resources Terraform does not manage, and the account stays recoverable for the soft delete period of the subscription.
