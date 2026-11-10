# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds the Terraform configuration of a complete Azure infrastructure stack. The stack is made of modules that are switched on or off with `enable_*` variables; enabled modules are wired to each other automatically. Three environments are defined: `dev`, `staging` and `prod`. The pipeline deploys **${{ values.envName }}** to **${{ values.primaryRegion }}** on every push to `main`.

```d2
direction: right

title: {
  label: Azure Full Infrastructure
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Users and pipelines {
  shape: person
}

network: Networking {
  style.fill: "#E3F2FD"
  style.stroke: "#0078D4"

  default: snet-default
  aks: snet-aks
  compute: snet-compute
  database: snet-database {
    label: "snet-database\n(delegated to PostgreSQL)"
  }
  endpoints: snet-private_endpoints
}

workloads: Workloads {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  aks: AKS cluster
  acr: Container registry
  vms: Virtual machines
  identity: Managed identity
}

data: Data {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  storage: Storage account
  postgres: PostgreSQL {
    shape: cylinder
  }
  bus: Service Bus and Event Grid
}

platform: Platform {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  vault: Key Vault
  logs: Log Analytics and Application Insights
  governance: Budget and tag policies
}

users -> workloads.aks: kubectl, HTTPS
workloads.aks -> network.aks: nodes and pods
workloads.vms -> network.compute
data.postgres -> network.database: private access
workloads.aks -> workloads.acr: pulls images
workloads.aks -> platform.logs: Container Insights
workloads.identity -> platform.vault: reads secrets
network.aks -> platform.vault: service endpoint
network.aks -> data.storage: service endpoint
```

---

## Modules

| Module | Path | Creates | In this stack |
| ------ | ---- | ------- | ------------- |
| Networking | `modules/networking` | Virtual network, five subnets with a network security group each; optional NAT gateway, Bastion host and DDoS protection plan | {% if values.enableNetworking %}Enabled{% else %}Disabled{% endif %} |
| Compute | `modules/compute` | Linux virtual machines with private addresses, SSH keys and an optional daily shutdown | {% if values.enableCompute %}Enabled{% else %}Disabled{% endif %} |
| Containers | `modules/containers` | AKS cluster with a system and an autoscaling user node pool, and a container registry | {% if values.enableContainers %}Enabled{% else %}Disabled{% endif %} |
| Storage | `modules/storage` | Storage account with blob versioning and soft delete | {% if values.enableStorage %}Enabled{% else %}Disabled{% endif %} |
| Database | `modules/database` | PostgreSQL flexible server with one database | {% if values.enableDatabase %}Enabled{% else %}Disabled{% endif %} |
| Security | `modules/security` | Key Vault with Azure RBAC authorization and purge protection | {% if values.enableSecurity %}Enabled{% else %}Disabled{% endif %} |
| Identity | `modules/identity` | User-assigned managed identity for workloads | {% if values.enableIdentity %}Enabled{% else %}Disabled{% endif %} |
| Monitoring | `modules/monitoring` | Log Analytics workspace and Application Insights | {% if values.enableMonitoring %}Enabled{% else %}Disabled{% endif %} |
| Integration | `modules/integration` | Service Bus namespace and Event Grid topic | {% if values.enableIntegration %}Enabled{% else %}Disabled{% endif %} |
| Governance | `modules/governance` | Monthly budget with alerts and tag policies in audit mode | {% if values.enableGovernance %}Enabled{% else %}Disabled{% endif %} |

Change the selection in `environments/*.tfvars`:

```hcl
enable_networking = true
enable_database   = false
```

### How the Modules Connect

| When these are enabled | Then |
| ---------------------- | ---- |
| Networking + Containers | AKS nodes and pods run in `snet-aks`; without Networking, AKS manages a network of its own |
| Networking + Database | PostgreSQL is reachable only from the virtual network (delegated subnet and private DNS zone); without Networking it has a public endpoint whose firewall admits no address until you add rules |
| Networking + Compute | Virtual machines are attached to `snet-compute`. Compute cannot be enabled without Networking |
| Networking + Security or Storage | The `default`, `aks` and `compute` subnets reach Key Vault and storage through service endpoints |
| Monitoring + Containers | AKS sends container logs and metrics to the Log Analytics workspace |
| Security + Identity | The managed identity may read secrets from the Key Vault |

### Resource Groups

| Resource group | Holds |
| -------------- | ----- |
| `rg-${{ values.name }}-<env>` | Workloads and data: AKS, registry, virtual machines, storage, PostgreSQL, Service Bus, managed identity. The budget and tag policies apply to this group |
| `rg-${{ values.name }}-<env>-network` | Virtual network and its subnets, NSGs, NAT gateway, Bastion |
| `rg-${{ values.name }}-<env>-security` | Key Vault |
| `rg-${{ values.name }}-<env>-monitoring` | Log Analytics workspace, Application Insights |

In `prod` every resource group carries a delete lock. Remove the locks before destroying the environment.

---

## Configuration Summary

| Setting | Value |
| ------- | ----- |
| Project | `${{ values.name }}` |
| Owner | `${{ values.owner }}` |
| Business unit | `${{ values.businessUnit }}` |
| Primary region | `${{ values.primaryRegion }}` |
| Secondary region | `${{ values.secondaryRegion }}` |
| Environment deployed on push | `${{ values.envName }}` |

### Environments

| Setting | dev | staging | prod |
| ------- | --- | ------- | ---- |
| Virtual network | `10.0.0.0/16` | `10.1.0.0/16` | `10.2.0.0/16` |
| AKS user nodes | 1-3 x D2s_v3 | 1-5 x D4s_v3 | 3-10 x D4s_v3 |
| PostgreSQL | Burstable B1ms, 32 GB | General Purpose D2s_v3, 64 GB | General Purpose D4s_v3, 128 GB |
| Virtual machines | 1 x D2s_v5 | 2 x D2s_v5 | 3 x D4s_v5 |
| Log retention | 30 days | 60 days | 90 days |
| Monthly budget | 500 | 2000 | 10000 |

High availability, disaster recovery and auto-shutdown are set per environment in `environments/*.tfvars`; the `${{ values.envName }}` file carries the choices made when this repository was created.

### Subnets

The subnets are carved out of `vnet_address_space` (shown for `10.0.0.0/16`):

| Subnet | Range | Purpose | Service endpoints |
| ------ | ----- | ------- | ----------------- |
| `snet-default` | `10.0.1.0/24` | General workloads | Key Vault, Storage |
| `snet-aks` | `10.0.16.0/20` | AKS nodes and pods | Key Vault, Storage |
| `snet-database` | `10.0.32.0/24` | PostgreSQL flexible server (delegated) | Storage |
| `snet-compute` | `10.0.33.0/24` | Virtual machines | Key Vault, Storage |
| `snet-private_endpoints` | `10.0.34.0/24` | Reserved for private endpoints you add | - |
| `AzureBastionSubnet` | `10.0.254.0/26` | Bastion host (with `enable_bastion`) | - |

### Resilience and Cost Settings

| Variable | Effect |
| -------- | ------ |
| `enable_high_availability` | Zone-redundant storage (ZRS); AKS nodes in three zones and the Standard tier with its uptime SLA; zone-redundant PostgreSQL standby (General Purpose and Memory Optimized SKUs); virtual machines spread over three zones |
| `enable_dr` | Geo-redundant storage (GRS, or GZRS with high availability); geo-redundant PostgreSQL backups; Premium container registry with a replica in `secondary_location` |
| `enable_auto_shutdown` | Virtual machines shut down every day at `auto_shutdown_time` (UTC). Never applied in `prod` |
| `enable_nat_gateway` | Outbound traffic of the `default`, `aks` and `compute` subnets leaves through one static public IP |
| `enable_bastion` | Bastion host for SSH access to the virtual machines |
| `enable_ddos_protection` | DDoS protection plan for the virtual network (billed monthly at a fixed price) |
| `restrict_network_access` | Key Vault and storage accept requests only from the service subnets and `allowed_ip_ranges`. Terraform then needs a runner inside the network, or its address in `allowed_ip_ranges` |

---

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request to `main`, and on demand from the **Actions** tab.

### Checks

These jobs need no cloud account and run from the first commit:

| Job             | What it does                                                                  |
| --------------- | ----------------------------------------------------------------------------- |
| Validate        | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` |
| TFLint          | Lints the root module and `modules/` with the AzureRM ruleset                 |
| Terraform Tests | Runs `tests/*.tftest.hcl` against a mocked provider                           |
| Security Scan   | Trivy and Checkov; any finding fails the job                                  |

### Deployment

These jobs sign in to Azure with OIDC. They are skipped until the repository secrets listed under [GitHub Repository Setup](#2-github-repository-setup) exist:

| Job             | Runs on                                              | What it does                                                       |
| --------------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Cost Estimate   | Pull requests, once `INFRACOST_API_KEY` is set       | Posts an Infracost breakdown on the pull request                   |
| Plan            | Pull requests, pushes to `main`, manual plan/apply   | Plans the target environment and adds the plan to the run summary  |
| Apply           | Pushes to `main`, manual apply                       | Applies the saved plan in the GitHub environment of the same name  |
| Destroy         | Manual destroy with `DESTROY` typed as confirmation  | Destroys the target environment                                    |
| Drift Detection | Manual drift-detection                               | Opens an issue when the deployed infrastructure has drifted        |

Pushes and pull requests target the `${{ values.envName }}` environment (`DEFAULT_ENVIRONMENT` in the workflow). The other environments are deployed from **Actions > Terraform > Run workflow**.

### Pipeline Workflow

```d2
direction: right

push: Push or pull request {
  shape: oval
}

checks: Checks {
  validate: Validate
  lint: TFLint
  test: Terraform Tests
  security: Security Scan
}

plan: Plan
apply: Apply {
  label: "Apply\n(main only)"
}

push -> checks -> plan -> apply
```

---

## Prerequisites

### 1. Azure Account Setup

#### Create Azure AD App Registration for OIDC

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with Azure.

```bash
# Set variables
APP_NAME="github-actions-${{ values.name }}"
GITHUB_ORG="${{ values.destination.owner }}"
GITHUB_REPO="${{ values.destination.repo }}"

# Create Azure AD Application
az ad app create --display-name "$APP_NAME" --query appId -o tsv

# Get the Application ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get the Object ID of the Service Principal
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

# Create Federated Credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create Federated Credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create Federated Credentials for the environments the Apply and Destroy jobs run in
for ENV in dev staging prod; do
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters '{
      "name": "github-env-'$ENV'",
      "issuer": "https://token.actions.githubusercontent.com",
      "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:'$ENV'",
      "audiences": ["api://AzureADTokenExchange"]
    }'
done
```

#### Assign Required Azure Permissions

The stack creates several resource groups, so the roles are assigned on the subscription:

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create and change resources
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Create role assignments (Containers and Identity modules), delete locks and
# policy assignments (Governance module)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Resource Policy Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

The provider does not register resource providers. Register the ones your modules use once per subscription, for example:

```bash
for NAMESPACE in Microsoft.Network Microsoft.Compute Microsoft.ContainerService Microsoft.ContainerRegistry \
  Microsoft.Storage Microsoft.DBforPostgreSQL Microsoft.KeyVault Microsoft.ManagedIdentity \
  Microsoft.OperationalInsights Microsoft.Insights Microsoft.ServiceBus Microsoft.EventGrid \
  Microsoft.Consumption Microsoft.PolicyInsights Microsoft.DevTestLab; do
  az provider register --namespace $NAMESPACE
done
```

#### Create Terraform State Backend

```bash
# Variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="${{ values.primaryRegion }}"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Enable versioning for state recovery
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --enable-versioning true

# Let the pipeline read and write the state with its Entra ID identity
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"

# Store this name in the AZURE_STORAGE_ACCOUNT repository secret
echo $STORAGE_ACCOUNT
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**. Until the four `AZURE_*` secrets exist the pipeline runs its checks and skips every job that talks to Azure:

| Secret                  | Description                                 | Example                                |
| ----------------------- | ------------------------------------------- | -------------------------------------- |
| `AZURE_CLIENT_ID`       | Application (client) ID of the app registration | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID`       | Directory (tenant) ID                       | `12345678-1234-1234-1234-123456789012` |
| `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into                 | `12345678-1234-1234-1234-123456789012` |
| `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state | `stterraformstate1234`              |
| `INFRACOST_API_KEY`     | Enables cost estimates on pull requests (optional) | `ico-xxxxxxxx`                  |

The state lives in resource group `rg-terraform-state`, container `tfstate`. Set the repository variables `TF_STATE_RESOURCE_GROUP` and `TF_STATE_CONTAINER` to use other names.

#### GitHub Environments

The Apply and Destroy jobs run in the GitHub environment named after their target: `dev`, `staging` or `prod`. GitHub creates an environment the first time a job uses it; add protection rules in **Settings > Environments** to require approval:

| Environment | Suggested protection rules                          |
| ----------- | --------------------------------------------------- |
| `dev`       | None                                                |
| `staging`   | Required reviewers                                  |
| `prod`      | Required reviewers, deployment branches: `main` only |

---

## Usage

### Local Development

```bash
# Initialize Terraform without the state backend
terraform init -backend=false

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests (mocked provider, no Azure account needed)
terraform test
```

To plan or apply from your machine, sign in with `az login`, initialize against the state backend as shown in the README, then:

```bash
terraform plan -var-file=environments/${{ values.envName }}.tfvars
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

### Running the Pipeline

#### Automatic Triggers

| Trigger        | Jobs                                                             |
| -------------- | ---------------------------------------------------------------- |
| Pull request   | Checks, Cost Estimate, Plan (`${{ values.envName }}`)            |
| Push to `main` | Checks, Plan and Apply (`${{ values.envName }}`)                 |

Plan, Apply and Cost Estimate are skipped while their secrets are missing.

#### Manual Deployment

1. Open the **Actions** tab
2. Select the **Terraform** workflow
3. Click **Run workflow**
4. Choose:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: type `DESTROY` (destroy only)
5. Click **Run workflow**

A manual run fails straight away, naming the missing secrets, if the Azure credentials are not configured.

### After the First Apply

**AKS.** Local accounts are disabled, so every user signs in with Entra ID and needs a Kubernetes role in Azure:

```bash
az role assignment create \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --assignee <user-or-group-object-id> \
  --scope $(az aks show --resource-group rg-${{ values.name }}-${{ values.envName }} --name aks-${{ values.name }}-${{ values.envName }} --query id -o tsv)

# Configure kubectl
$(terraform output -raw aks_get_credentials_command)
```

**PostgreSQL.** The administrator password is generated and kept in the Terraform state:

```bash
terraform output -raw database_administrator_password
```

**Virtual machines.** Unless `admin_ssh_public_key` is set, a key pair is generated:

```bash
terraform output -raw vm_generated_ssh_private_key > id_rsa && chmod 600 id_rsa
```

The machines have private addresses only; reach them through Bastion (`enable_bastion`) or from inside the virtual network.

**Key Vault, storage, Service Bus and Event Grid** accept Entra ID identities. Grant people and workloads the data roles they need, for example `Key Vault Secrets Officer`, `Storage Blob Data Contributor` or `Azure Service Bus Data Sender`.

---

## Security Scanning

The Security Scan job runs two scanners and fails on any finding:

| Tool        | Scope                                                      | Run locally                                        |
| ----------- | ---------------------------------------------------------- | -------------------------------------------------- |
| **Trivy**   | Misconfigurations of severity MEDIUM and above             | `trivy config --severity CRITICAL,HIGH,MEDIUM .`   |
| **Checkov** | Policy checks for Terraform                                | `checkov --directory . --config-file .checkov.yaml` |

### Accepted Findings

Each exception is declared next to the resource it applies to, with its reason:

| Finding | Where | Reason |
| ------- | ----- | ------ |
| Trivy `AZU-0013`, Checkov `CKV_AZURE_109`, `CKV2_AZURE_32` | Key Vault | The vault accepts requests from any network by default so the pipeline can manage it; every request still needs an Azure role. Set `restrict_network_access` to change it |
| Trivy `AZU-0012`, Checkov `CKV_AZURE_35`, `CKV_AZURE_59`, `CKV2_AZURE_33` | Storage account | The account accepts requests from any network by default so the pipeline can manage it. Set `restrict_network_access` to change it |
| Checkov `CKV2_AZURE_40`, `CKV2_AZURE_1` | Storage account | Terraform configures the blob and queue services with the account key; data is encrypted with platform-managed keys |
| Checkov `CKV_AZURE_206` | Storage account | Replication follows the high availability and disaster recovery settings |
| Trivy `AZU-0065`, `AZU-0041`, Checkov `CKV_AZURE_115`, `CKV_AZURE_6` | AKS cluster | The API server is public by default and protected by Entra ID with Azure RBAC; set `private_cluster_enabled` or `api_server_authorized_ip_ranges` in the containers module to change it |
| Trivy `AZU-0040` | AKS cluster | Container Insights is switched on together with the Monitoring module |
| Checkov `CKV_AZURE_170` | AKS cluster | The Standard tier with its uptime SLA is selected together with high availability |
| Checkov `CKV_AZURE_117`, `CKV_AZURE_226`, `CKV_AZURE_227` | AKS cluster and node pool | Node disks use platform-managed keys and managed OS disks; encryption at host needs a subscription feature |
| Checkov `CKV_AZURE_139`, `CKV_AZURE_233`, `CKV_AZURE_237`, `CKV_AZURE_164`, `CKV_AZURE_165`, `CKV_AZURE_166` | Container registry | Public endpoint for pipelines that push images; the other checks are Premium SKU features, which disaster recovery switches on |
| Checkov `CKV2_AZURE_57`, `CKV_AZURE_136` | PostgreSQL server | VNet integration replaces a private endpoint; geo-redundant backups are switched on with disaster recovery |
| Checkov `CKV_AZURE_199`, `CKV_AZURE_201`, `CKV_AZURE_204` | Service Bus namespace | Platform-managed keys; public endpoint that accepts Entra ID identities only |
| Checkov `CKV_AZURE_193` | Event Grid topic | Public endpoint that accepts Entra ID identities only |
| Trivy `AZU-0068`, Checkov `CKV2_AZURE_12` | Virtual machines | The compute subnet carries the network security group; the machines hold no data of their own |
| Checkov `CKV2_AZURE_31` | AzureBastionSubnet | Azure Bastion manages the traffic of its own subnet |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_example" "this" {
  #checkov:skip=CKV_AZURE_123:Reason the check does not apply
  #trivy:ignore:AZU-0001 Reason the check does not apply
}
```

---

## Outputs

| Output | Description |
| ------ | ----------- |
| `resource_group_name` | Primary resource group |
| `vnet_id`, `vnet_name`, `subnet_ids` | Virtual network and its subnets |
| `key_vault_name`, `key_vault_uri` | Key Vault |
| `managed_identity_client_id`, `managed_identity_principal_id` | Managed identity for workloads |
| `storage_account_name`, `storage_primary_blob_endpoint` | Storage account |
| `log_analytics_workspace_id`, `application_insights_connection_string` | Monitoring |
| `aks_cluster_name`, `aks_get_credentials_command`, `acr_login_server` | AKS and the registry |
| `database_server_fqdn`, `database_name`, `database_administrator_login` | PostgreSQL |
| `vm_names`, `vm_private_ips` | Virtual machines |
| `service_bus_endpoint`, `event_grid_topic_endpoint` | Integration |
| `infrastructure_summary` | Project, environment, regions and enabled modules |

Outputs of disabled modules are `null`. `terraform output` lists them all.

---

## Troubleshooting

**Error: AuthorizationFailed when creating a role assignment, lock or policy assignment**

The pipeline identity lacks `User Access Administrator` or `Resource Policy Contributor`. See [Assign Required Azure Permissions](#assign-required-azure-permissions).

**Error: MissingSubscriptionRegistration**

A resource provider is not registered on the subscription. Register it with `az provider register --namespace <namespace>`.

**Error: a name is already taken (Key Vault, storage account, container registry, PostgreSQL, Service Bus)**

These names are unique across Azure and are derived from the project name. Change `name` in `environments/*.tfvars`.

**Error: enable_compute needs enable_networking**

Virtual machines are attached to the compute subnet. Enable the Networking module.

**Error: ScopeLocked when destroying prod**

The `prod` resource groups carry delete locks. Remove them in the portal or with `az lock delete`, then run the destroy again.

**Error: Failed to get existing workspaces**

The state backend is not reachable. Check the `AZURE_STORAGE_ACCOUNT` secret and that the pipeline identity has `Storage Blob Data Contributor` on the state storage account.

**Security scan failing**

The job log lists each finding with its file and line. Fix the configuration, or accept the finding as described under [Security Scanning](#security-scanning).

---

## References

- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Tests](https://developer.hashicorp.com/terraform/language/tests)
- [Azure landing zone design areas](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [AKS documentation](https://learn.microsoft.com/azure/aks/)
- [Azure Database for PostgreSQL flexible server](https://learn.microsoft.com/azure/postgresql/flexible-server/)

## Owner

**${{ values.owner }}**
