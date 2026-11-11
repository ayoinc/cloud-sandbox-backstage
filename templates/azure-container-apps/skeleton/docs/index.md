# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of an Azure Container Apps service for the **${{ values.envName }}** environment in **${{ values.location }}**:

- Container app `ca-${{ values.name }}-${{ values.envName }}` running `${{ values.containerImage }}`
- Its own Container Apps environment (workload profiles, Consumption) and Log Analytics workspace
- User-assigned managed identity for pulling images, reading Key Vault secrets and calling Azure services
- HTTPS ingress, ${{ "open to the internet" if values.externalIngress else "internal to the environment" }}, with liveness and readiness probes
- Autoscaling on concurrent HTTP requests, down to zero when idle

## Configuration Summary

| Setting | Value |
| --- | --- |
| Container app | `ca-${{ values.name }}-${{ values.envName }}` |
| Environment | `cae-${{ values.name }}-${{ values.envName }}` |
| Resource group | `rg-${{ values.name }}-${{ values.envName }}` |
| Location | `${{ values.location }}` |
| Image | `${{ values.containerImage }}` |
| Port | ${{ values.targetPort }} |
| Size per replica | ${{ values.cpu }} vCPU, ${{ values.memory }} |
| Replicas | ${{ values.minReplicas }} to ${{ values.maxReplicas }} |
| Ingress | ${{ "External" if values.externalIngress else "Internal" }}, HTTPS only |

Every setting of every environment is in `environments/*.tfvars`.

## Deploying a New Image

The image is part of the configuration. Change `container_image` in `environments/<environment>.tfvars`, push, and the pipeline creates a new revision that replaces the old one once it passes its probes. Pin a tag or a digest per release rather than `latest`, so a revision is reproducible.

### Private Registry

```hcl
container_image = "<registry>.azurecr.io/<repository>:<tag>"
container_registry = {
  id           = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<registry>"
  login_server = "<registry>.azurecr.io"
}
```

The app identity is granted `AcrPull`; no registry password is involved.

### Secrets

Secrets stay in Key Vault and are referenced, never copied into this repository or the Terraform state:

```hcl
key_vault_id = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>"
secret_environment_variables = {
  DATABASE_PASSWORD = "https://<vault>.vault.azure.net/secrets/database-password"
}
```

### Calling Azure Services

Grant roles to `terraform output identity_principal_id`. The container gets `AZURE_CLIENT_ID`, so `DefaultAzureCredential` picks the identity up without configuration.

### Logs

```bash
az containerapp logs show --name ca-${{ values.name }}-${{ values.envName }} --resource-group rg-${{ values.name }}-${{ values.envName }} --follow
```

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
    | `Contributor` | The subscription, or a resource group you create up front | Create the resource group, environment and app |
    | `Role Based Access Control Administrator` | The registry and the key vault | Only when you set `container_registry` or `key_vault_id` |
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
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ManagedIdentity
```

## Variables

The settings you are most likely to change. `variables.tf` documents all of them.

| Variable | Description |
| --- | --- |
| `container_image` | Image and tag or digest |
| `container_cpu`, `container_memory` | Size of a replica; 2Gi for each vCPU |
| `min_replicas`, `max_replicas`, `concurrent_requests_per_replica` | Autoscaling |
| `target_port`, `health_probe_path` | Where the container listens and how its health is checked |
| `external_ingress_enabled` | Accept requests from outside the environment |
| `environment_variables`, `secret_environment_variables`, `key_vault_id` | Configuration and Key Vault secrets |
| `container_registry` | Private Azure Container Registry |
| `infrastructure_subnet_id`, `internal_load_balancer_enabled`, `zone_redundancy_enabled` | Run the environment in your own virtual network |
| `log_retention_days` | Retention of container logs |

## Outputs

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the resource group |
| `container_app_id` | Resource ID of the container app |
| `container_app_name` | Name of the container app |
| `container_app_url` | HTTPS URL of the app; reachable from the internet only with external ingress |
| `latest_revision_name` | Name of the latest revision |
| `environment_id` | Resource ID of the Container Apps environment |
| `environment_default_domain` | Default domain of the Container Apps environment |
| `environment_static_ip_address` | Static IP address of the Container Apps environment |
| `identity_id` | Resource ID of the app's managed identity |
| `identity_principal_id` | Object ID of the app's managed identity, for role assignments |
| `identity_client_id` | Client ID of the app's managed identity |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics workspace holding the container logs |

```bash
terraform output
terraform output -json
```

## Security

| Control | Setting |
| --- | --- |
| Identity | User-assigned managed identity; no registry passwords or connection strings |
| Ingress | ${{ "External" if values.externalIngress else "Internal to the environment" }}; HTTPS only, HTTP is redirected |
| Secrets | Key Vault references resolved with the app identity |
| Logs | Container and system logs in Log Analytics |

Without `infrastructure_subnet_id` the environment runs in a network managed by Azure and has a public address even when the app's ingress is internal; set the subnet and `internal_load_balancer_enabled = true` for a fully private environment.

No scanner exceptions are declared in this configuration.

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_206:Reason the check does not apply
  #trivy:ignore:AZU-0012 Reason the check does not apply
}
```

## Operations

- **Roll back**: set `container_image` back to the previous tag and push.
- **Scale**: change `min_replicas` and `max_replicas`. Keep `min_replicas` at 1 or more when cold starts matter.
- **Restart**: `az containerapp revision restart --name ca-${{ values.name }}-${{ values.envName }} --resource-group rg-${{ values.name }}-${{ values.envName }} --revision $(terraform output -raw latest_revision_name)`.
