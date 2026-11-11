# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of an Azure Database for PostgreSQL flexible server for the **${{ values.envName }}** environment in **${{ values.location }}**:

- Server `psql-${{ values.name }}-${{ values.envName }}`, PostgreSQL ${{ values.postgresVersion }}, in the resource group `rg-${{ values.name }}-${{ values.envName }}`
- No public endpoint: the server lives in a delegated subnet and is named in a private DNS zone
- Entra ID authentication only: there is no administrator password
- Automatic storage growth, point-in-time restore and a weekly maintenance window
- Optional standby replica in another availability zone with automatic failover

## Configuration Summary

| Setting | Value |
| --- | --- |
| Server | `psql-${{ values.name }}-${{ values.envName }}` |
| Resource group | `rg-${{ values.name }}-${{ values.envName }}` |
| Location | `${{ values.location }}` |
| PostgreSQL version | `${{ values.postgresVersion }}` |
| Compute | `${{ values.skuName }}` |
| Storage | ${{ values.storageGb }} GiB, growing automatically |
| High availability | `${{ values.highAvailability }}` |
| Database | `${{ values.databaseName }}` |
| Administrator | ${{ values.entraAdminType }} `${{ values.entraAdminObjectId }}` |
| Authentication | Entra ID only |

Every setting of every environment is in `environments/*.tfvars`.

## Connecting

The server is reachable only from the virtual network it lives in and from networks peered with it. Unless you pass an existing subnet, Terraform creates `vnet-${{ values.name }}-${{ values.envName }}`: peer it with the network of your workloads and link the private DNS zone to that network, so the server name resolves there.

Sign in as an Entra ID administrator with an access token as the password:

```bash
export PGHOST=$(terraform output -raw server_fqdn)
export PGUSER="<name of the administrator principal>"
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken --output tsv)
psql "dbname=${{ values.databaseName }} sslmode=require"
```

Give workloads their own database role tied to a managed identity instead of sharing the administrator:

```sql
SELECT * FROM pgaadauth_create_principal('<managed identity name>', false, false);
GRANT CONNECT ON DATABASE "${{ values.databaseName }}" TO "<managed identity name>";
```

The workload then requests a token for `https://ossrdbms-aad.database.windows.net/.default` and uses it as the password.

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
    | `Contributor` | The subscription, or a resource group you create up front | Create the resource group, network and server |
    | `Network Contributor` | An existing subnet and private DNS zone | Only when you pass `delegated_subnet_id` and `private_dns_zone_id` |
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
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Insights  # diagnostic logs
```

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `postgresql_version` | Major version; raise it to upgrade in place |
| `sku_name` | `B_Standard_B2s`, `GP_Standard_D4ds_v5`, `MO_Standard_E4ds_v5`, ... |
| `storage_gb` | Provisioned storage; it can grow but not shrink |
| `high_availability_mode` | `Disabled`, `ZoneRedundant` or `SameZone`; not in the Burstable tier |
| `backup_retention_days`, `geo_redundant_backup_enabled` | Point-in-time restore; geo redundancy is fixed at creation |
| `database_names` | Databases to create |
| `entra_administrators` | Principals that administer the server |
| `server_parameters` | PostgreSQL parameters by name |
| `virtual_network_address_space` | Address space of the created network (`/24` or larger) |
| `delegated_subnet_id`, `private_dns_zone_id` | Use an existing network instead |
| `log_analytics_workspace_id` | Destination of logs and metrics |

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the resource group |
| `server_id` | Resource ID of the PostgreSQL server |
| `server_name` | Name of the PostgreSQL server |
| `server_fqdn` | Host name of the server, resolvable inside the linked virtual networks |
| `database_names` | Names of the databases |
| `administrator_names` | Entra ID principals that administer the server; sign in with one of these as the user name |
| `virtual_network_id` | Resource ID of the virtual network created for the server, or null when an existing subnet is used |
| `delegated_subnet_id` | Resource ID of the subnet the server lives in |
| `private_dns_zone_id` | Resource ID of the private DNS zone holding the server name |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Network | No public endpoint; delegated subnet with a network security group and no default outbound access |
| Authentication | Entra ID only; password authentication disabled |
| Transport | TLS required (`require_secure_transport` is on by default) |
| Encryption at rest | Platform-managed keys |
| Recovery | Point-in-time restore for the backup retention period |

### Accepted Findings

Each exception is declared on the server, with its reason:

| Finding | Reason |
| --- | --- |
| Checkov `CKV_AZURE_136` | Geo-redundant backup is chosen per environment and is on in production |
| Checkov `CKV2_AZURE_57` | A server in a delegated subnet has no public endpoint and cannot take a private endpoint |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_206:Reason the check does not apply
  #trivy:ignore:AZU-0012 Reason the check does not apply
}
```

## Operations

- **Restore to a point in time**: `az postgres flexible-server restore --resource-group rg-${{ values.name }}-${{ values.envName }} --name <new-server> --source-server psql-${{ values.name }}-${{ values.envName }} --restore-time <timestamp>` creates a new server next to this one.
- **Scale**: change `sku_name` or `storage_gb` and apply. Changing the compute size restarts the server; with high availability it fails over instead.
- **Upgrade**: raise `postgresql_version` by one or more major versions and apply. Test the upgrade on a restored copy first.
- **Failover**: with a standby, Azure fails over automatically; Terraform ignores the resulting zone swap.
