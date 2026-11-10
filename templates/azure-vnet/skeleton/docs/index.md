# ${{ values.name }}

Azure Virtual Network (VNet) infrastructure for the **${{ values.envName }}** environment in **${{ values.location }}**.

## Overview

This VNet provides a production-ready network foundation with:

- Public and private subnets for workload isolation
- Dedicated database subnet with service endpoints
- AKS-ready subnet with container registry integration
- Network Security Groups (NSGs) for defense-in-depth
- NAT Gateway for secure outbound internet access
- Optional DDoS Protection Plan integration
- VNet peering support for hub-spoke architectures

```d2
direction: right

title: {
  label: Azure VNet Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

azure: Azure (${{ values.location }}) {
  style.fill: "#E3F2FD"
  style.stroke: "#0078D4"

  rg: Resource Group {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"

    vnet: VNet (${{ values.addressSpace }}) {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"

      public: snet-public {
        style.fill: "#C8E6C9"
        style.stroke: "#2E7D32"
        label: "Public Subnet\nLoad Balancers\nApp Gateways"
      }

      private: snet-private {
        style.fill: "#FFCDD2"
        style.stroke: "#C62828"
        label: "Private Subnet\nVMs, App Services"
      }

      database: snet-database {
        style.fill: "#FFE0B2"
        style.stroke: "#EF6C00"
        label: "Database Subnet\nSQL, CosmosDB"
      }

      aks: snet-aks {
        style.fill: "#B3E5FC"
        style.stroke: "#0277BD"
        label: "AKS Subnet\nKubernetes Nodes"
      }
    }

    nat: NAT Gateway {
      shape: hexagon
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
    }

    nsg-public: NSG Public {
      shape: diamond
      style.fill: "#DCEDC8"
      style.stroke: "#689F38"
    }

    nsg-private: NSG Private {
      shape: diamond
      style.fill: "#FFCDD2"
      style.stroke: "#E53935"
    }

    nsg-database: NSG Database {
      shape: diamond
      style.fill: "#FFE0B2"
      style.stroke: "#FB8C00"
    }
  }
}

internet -> azure.rg.vnet.public: HTTPS/HTTP
azure.rg.vnet.public -> azure.rg.nsg-public: filtered by
azure.rg.vnet.private -> azure.rg.nsg-private: filtered by
azure.rg.vnet.database -> azure.rg.nsg-database: filtered by
azure.rg.vnet.private -> azure.rg.nat: outbound
azure.rg.vnet.aks -> azure.rg.nat: outbound
azure.rg.nat -> internet: egress
```

## Configuration Summary

| Setting              | Value                                 |
| -------------------- | ------------------------------------- |
| VNet Name            | `vnet-${{ values.name }}-${{ values.envName }}` |
| Resource Group       | `rg-${{ values.name }}-${{ values.envName }}`   |
| Address Space        | `${{ values.addressSpace }}`          |
| Location             | `${{ values.location }}`              |
| Environment          | `${{ values.envName }}`           |
| NAT Gateway          | Enabled                               |
| DDoS Protection      | Configurable per environment          |

## Network Layout

| Subnet        | CIDR Range | Purpose                                                | Service Endpoints                |
| ------------- | ---------- | ------------------------------------------------------ | -------------------------------- |
| snet-public   | 1/16 of the address space | Public-facing resources (Load Balancers, App Gateways) | None                             |
| snet-private  | 1/16 of the address space | Private workloads (VMs, App Services)                  | None                             |
| snet-database | 1/16 of the address space | Database services (SQL, CosmosDB, PostgreSQL)          | Microsoft.Sql, Microsoft.Storage |
| snet-aks      | 1/4 of the address space  | AKS cluster nodes (larger for pod IP allocation)       | Microsoft.ContainerRegistry, Microsoft.KeyVault |

The subnets are carved out of `address_space` automatically. With `10.0.0.0/16` that gives `10.0.0.0/20`, `10.0.16.0/20`, `10.0.32.0/20` and `10.0.64.0/18`. Set `public_subnet_cidr`, `private_subnet_cidr`, `database_subnet_cidr` or `aks_subnet_cidr` in a tfvars file to override any of them.

### Subnet Design Considerations

- **Public Subnet**: Hosts internet-facing resources. NSG allows HTTPS inbound and Azure Load Balancer probes.
- **Private Subnet**: For internal workloads. Only VNet-internal traffic allowed. NAT Gateway provides outbound access.
- **Database Subnet**: Highly restricted. Only accepts connections from private and AKS subnets on database ports (1433, 5432, 3306).
- **AKS Subnet**: Takes a quarter of the address space to accommodate Azure CNI pod IP requirements. No NSG attached (AKS manages its own).

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
SUBSCRIPTION_ID="your-subscription-id"
APP_NAME="github-actions-${{ values.name }}"
GITHUB_ORG="your-org"
GITHUB_REPO="${{ values.name }}"

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

Create a custom role with the minimum required permissions:

```bash
# Create custom role definition
cat > vnet-deployer-role.json << 'EOF'
{
  "Name": "VNet Deployer",
  "Description": "Can manage Virtual Networks and related resources",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/write",
    "Microsoft.Resources/subscriptions/resourceGroups/delete",
    "Microsoft.Network/virtualNetworks/*",
    "Microsoft.Network/networkSecurityGroups/*",
    "Microsoft.Network/natGateways/*",
    "Microsoft.Network/publicIPAddresses/*",
    "Microsoft.Network/ddosProtectionPlans/read",
    "Microsoft.Network/ddosProtectionPlans/join/action",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Storage/storageAccounts/read",
    "Microsoft.Storage/storageAccounts/listKeys/action",
    "Microsoft.Storage/storageAccounts/blobServices/containers/read",
    "Microsoft.Storage/storageAccounts/blobServices/containers/write"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/$SUBSCRIPTION_ID"
  ]
}
EOF

# Create the role
az role definition create --role-definition vnet-deployer-role.json

# Assign role to the Service Principal
az role assignment create \
  --role "VNet Deployer" \
  --assignee $SP_OBJECT_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Also assign Storage Blob Data Contributor for Terraform state
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $SP_OBJECT_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-terraform-state"
```

#### Create Terraform State Backend

```bash
# Variables
RESOURCE_GROUP="rg-terraform-state"
LOCATION="${{ values.location }}"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"

# Create Resource Group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Enable versioning for state file history
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --enable-versioning true

# Create Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Enable soft delete for recovery
az storage blob service-properties delete-policy update \
  --account-name $STORAGE_ACCOUNT \
  --enable true \
  --days-retained 30

echo "Storage Account: $STORAGE_ACCOUNT"
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
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Login to Azure
az login
az account set --subscription "your-subscription-id"

# Initialize Terraform (local backend for dev)
terraform init -backend=false

# Or initialize with remote backend
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=your-storage-account" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}/dev/terraform.tfstate"

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars
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

### Referencing in Other Terraform

```hcl
# Reference the VNet
data "azurerm_virtual_network" "main" {
  name                = "vnet-${{ values.name }}-${{ values.envName }}"
  resource_group_name = "rg-${{ values.name }}-${{ values.envName }}"
}

# Reference a specific subnet
data "azurerm_subnet" "private" {
  name                 = "snet-private"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_virtual_network.main.resource_group_name
}

# Use subnet ID for VM or other resource
resource "azurerm_network_interface" "example" {
  name                = "nic-example"
  location            = data.azurerm_virtual_network.main.location
  resource_group_name = data.azurerm_virtual_network.main.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

### VNet Peering

To peer with a hub VNet or another spoke VNet:

```hcl
# Data source for remote VNet
data "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-prod"
  resource_group_name = "rg-hub-prod"
}

# Peering from this VNet to hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-to-hub"
  resource_group_name          = "rg-${{ values.name }}-${{ values.envName }}"
  virtual_network_name         = "vnet-${{ values.name }}-${{ values.envName }}"
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true  # If hub has a VPN gateway
}

# Peering from hub to this VNet (must be created in hub subscription)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-to-${{ values.name }}"
  resource_group_name          = "rg-hub-prod"
  virtual_network_name         = "vnet-hub-prod"
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true  # If hub has a VPN gateway
  use_remote_gateways          = false
}
```

---

## Security Features

### Network Security Groups (NSGs)

The template creates three NSGs with defense-in-depth rules:

#### Public NSG (`nsg-public-${{ values.name }}-${{ values.envName }}`)

| Rule                   | Priority | Direction | Access | Protocol | Ports    | Source            |
| ---------------------- | -------- | --------- | ------ | -------- | -------- | ----------------- |
| AllowHTTPS             | 100      | Inbound   | Allow  | TCP      | 443      | Any               |
| AllowAzureLoadBalancer | 120      | Inbound   | Allow  | Any      | Any      | AzureLoadBalancer |
| DenyAllInbound         | 4096     | Inbound   | Deny   | Any      | Any      | Any               |

#### Private NSG (`nsg-private-${{ values.name }}-${{ values.envName }}`)

| Rule                   | Priority | Direction | Access | Protocol | Ports | Source            |
| ---------------------- | -------- | --------- | ------ | -------- | ----- | ----------------- |
| AllowVNetInbound       | 100      | Inbound   | Allow  | Any      | Any   | VirtualNetwork    |
| AllowAzureLoadBalancer | 110      | Inbound   | Allow  | Any      | Any   | AzureLoadBalancer |
| DenyInternetInbound    | 4096     | Inbound   | Deny   | Any      | Any   | Internet          |

#### Database NSG (`nsg-database-${{ values.name }}-${{ values.envName }}`)

| Rule                | Priority | Direction | Access | Protocol | Ports            | Source          |
| ------------------- | -------- | --------- | ------ | -------- | ---------------- | --------------- |
| AllowSQLFromPrivate | 100      | Inbound   | Allow  | TCP      | 1433, 5432, 3306 | Private Subnet  |
| AllowSQLFromAKS     | 110      | Inbound   | Allow  | TCP      | 1433, 5432, 3306 | AKS Subnet      |
| DenyAllInbound      | 4096     | Inbound   | Deny   | Any      | Any              | Any             |

### NAT Gateway

- Provides secure outbound internet access for private resources
- Static public IP for consistent egress address (firewall whitelisting)
- Deployed in the first configured availability zone (a NAT Gateway is a zonal resource)
- Configurable idle timeout (default: 10 minutes)
- Associated with private and AKS subnets

### DDoS Protection

Optional Azure DDoS Protection Standard can be enabled:

```hcl
# In your tfvars file
enable_ddos_protection = true
```

This provides:
- Layer 3/4 DDoS attack mitigation
- Real-time attack metrics and alerts
- Cost protection (service credits if attacked)
- Post-attack reports

### Service Endpoints

Subnets are configured with service endpoints for secure PaaS connectivity:

| Subnet        | Service Endpoints                                    |
| ------------- | ---------------------------------------------------- |
| snet-database | Microsoft.Sql, Microsoft.Storage                     |
| snet-aks      | Microsoft.ContainerRegistry, Microsoft.KeyVault      |

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
| Trivy `AZU-0047` | Public NSG, `AllowHTTPS` rule | The public subnet fronts internet-facing load balancers; HTTPS from anywhere is its purpose |
| Checkov `CKV2_AZURE_31` | `snet-aks` | AKS attaches its own NSG to the node NICs and manages the rules for its load balancers |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_example" "this" {
  #checkov:skip=CKV_AZURE_123:Reason the check does not apply
  #trivy:ignore:AZU-0001 Reason the check does not apply
}
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis
- Multi-environment cost comparison

**Estimated costs for this configuration:**

| Resource                | Monthly Cost (USD) | Notes                         |
| ----------------------- | ------------------ | ----------------------------- |
| NAT Gateway             | ~$32               | Per gateway                   |
| Public IP (Static)      | ~$3.60             | Per IP                        |
| VNet                    | Free               | No charge for VNet itself     |
| Subnets                 | Free               | No charge for subnets         |
| NSGs                    | Free               | No charge for NSG rules       |
| DDoS Protection         | ~$2,944            | If enabled (shared across VNets) |
| **Total Base Cost**     | ~$36/month         | Without DDoS Protection       |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                   | Description                              |
| ------------------------ | ---------------------------------------- |
| `resource_group_name`    | Name of the resource group               |
| `resource_group_id`      | ID of the resource group                 |
| `vnet_id`                | ID of the Virtual Network                |
| `vnet_name`              | Name of the Virtual Network              |
| `vnet_address_space`     | Address space of the Virtual Network     |
| `vnet_guid`              | GUID of the Virtual Network              |
| `public_subnet_id`       | ID of the public subnet                  |
| `public_subnet_name`     | Name of the public subnet                |
| `private_subnet_id`      | ID of the private subnet                 |
| `private_subnet_name`    | Name of the private subnet               |
| `database_subnet_id`     | ID of the database subnet                |
| `database_subnet_name`   | Name of the database subnet              |
| `aks_subnet_id`          | ID of the AKS subnet                     |
| `aks_subnet_name`        | Name of the AKS subnet                   |
| `subnet_ids`             | Map of all subnet IDs                    |
| `public_nsg_id`          | ID of the public Network Security Group  |
| `private_nsg_id`         | ID of the private Network Security Group |
| `database_nsg_id`        | ID of the database Network Security Group|
| `nsg_ids`                | Map of all Network Security Group IDs    |
| `nat_gateway_id`         | ID of the NAT Gateway (null if disabled) |
| `nat_public_ip`          | Public IP of the NAT Gateway             |
| `vnet_info`              | Summary object with all VNet details     |

Access outputs via:

```bash
# Get single output
terraform output vnet_id

# Get all outputs as JSON
terraform output -json

# Get nested output
terraform output -json subnet_ids | jq '.aks'
```

---

## Troubleshooting

### Authentication Issues

**Error: AADSTS700016 - Application not found**

```
Error: AADSTS700016: Application with identifier 'xxx' was not found in the directory
```

**Resolution:**

1. Verify `AZURE_CLIENT_ID` secret matches the Azure AD App Registration
2. Ensure the Service Principal was created: `az ad sp show --id $CLIENT_ID`
3. Check the Federated Credential subjects match your repository path

**Error: AuthorizationFailed**

```
Error: The client 'xxx' with object id 'xxx' does not have authorization to perform action
```

**Resolution:**

1. Verify role assignments: `az role assignment list --assignee $SP_OBJECT_ID`
2. Check subscription scope: ensure role is assigned at correct scope
3. Wait a few minutes for role assignment propagation

### State Backend Issues

**Error: Failed to get existing workspaces**

```
Error: Failed to get existing workspaces: containers.Client#ListBlobs: Failure
```

**Resolution:**

1. Verify storage account name in `AZURE_STORAGE_ACCOUNT` secret
2. Check the Service Principal has `Storage Blob Data Contributor` role
3. Ensure the container `tfstate` exists in the storage account

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. Check if another Terraform process is running
3. If stuck, break the lease:
   ```bash
   az storage blob lease break \
     --account-name $STORAGE_ACCOUNT \
     --container-name tfstate \
     --blob-name "${{ values.name }}/${{ values.envName }}/terraform.tfstate"
   ```

### Network Issues

**Error: SubnetWithServiceEndpointCannotBeDeleted**

```
Error: Subnet with service endpoint cannot be deleted
```

**Resolution:**

1. Remove resources using the service endpoint first
2. Or remove the service endpoint before deleting the subnet
3. Check for Private Endpoints attached to the subnet

**Error: InUseSubnetCannotBeDeleted**

```
Error: Subnet is in use and cannot be deleted
```

**Resolution:**

1. List resources in the subnet: `az network vnet subnet list-available-ips`
2. Remove all NICs, Private Endpoints, and delegations
3. Check for NAT Gateway associations

### Pipeline Failures

**Security scan failing**

The job log lists each finding with its file and line. Fix the configuration, or accept the finding as described under [Security Scanning](#security-scanning).

**Terraform test failing**

```bash
# Run tests locally with verbose output
terraform test -verbose

# Run specific test file
terraform test -filter=tests/vnet.tftest.hcl
```

---

## Related Templates

| Template                                        | Description                            |
| ----------------------------------------------- | -------------------------------------- |
| [azure-aks](/docs/default/template/azure-aks)   | Azure Kubernetes Service cluster       |
| [azure-sql](/docs/default/template/azure-sql)   | Azure SQL Database                     |
| [azure-app-service](/docs/default/template/azure-app-service) | Azure App Service Web App |
| [azure-storage](/docs/default/template/azure-storage) | Azure Storage Account            |
| [aws-vpc](/docs/default/template/aws-vpc)       | AWS VPC (equivalent)                   |
| [gcp-vpc](/docs/default/template/gcp-vpc)       | Google Cloud VPC (equivalent)          |

---

## References

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure NAT Gateway](https://docs.microsoft.com/en-us/azure/nat-gateway/nat-overview)
- [Azure VNet Peering](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Well-Architected Framework - Networking](https://docs.microsoft.com/en-us/azure/architecture/framework/services/networking/)

---

## Owner

This resource is owned by **${{ values.owner }}**.
