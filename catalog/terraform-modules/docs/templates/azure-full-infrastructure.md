# Azure Full Infrastructure Template

Creates a complete Azure infrastructure stack with modular components that can be individually enabled or disabled.

## Overview

This template provides a comprehensive Azure infrastructure foundation with 10+ module categories, allowing teams to quickly scaffold production-ready infrastructure while maintaining flexibility.

## Included Modules

| Module | Description | Default |
|--------|-------------|---------|
| **Networking** | VNet, Subnets, NSGs, Load Balancers, Firewall, VPN Gateway | Enabled |
| **Compute** | VMs, VMSS, App Service, Container Instances | Disabled |
| **Containers** | AKS Cluster, Container Registry, Container Apps | Disabled |
| **Storage** | Storage Accounts, Data Lake, File Shares | Enabled |
| **Database** | SQL Database, PostgreSQL, MySQL, Cosmos DB, Redis | Disabled |
| **Security** | Key Vault, Managed Identities | Enabled |
| **Identity** | Azure AD Groups, RBAC Assignments | Disabled |
| **Monitoring** | Log Analytics, Application Insights, Alerts | Enabled |
| **Integration** | Service Bus, Event Grid, Event Hubs, Logic Apps | Disabled |
| **Governance** | Policy Definitions, Cost Management | Disabled |

## Quick Start

### 1. Create from Backstage

Navigate to **Create** > **Templates** > **Azure Full Infrastructure Stack**

### 2. Configure Project

```yaml
Project Name: myapp
Environment: prod
Business Unit: engineering
Description: Production infrastructure for MyApp
```

### 3. Select Region

```yaml
Primary Region: eastus
Secondary Region: westus2  # For DR
```

### 4. Enable Modules

Select which modules to include:

- ✅ Networking
- ✅ Containers (AKS + ACR)
- ✅ Storage
- ✅ Database (PostgreSQL)
- ✅ Security
- ✅ Monitoring

### 5. Advanced Options

```yaml
Enable Disaster Recovery: true
Enable High Availability: true
Enable Auto-Shutdown: false
```

## Generated Structure

```
infrastructure/
├── catalog-info.yaml          # Backstage catalog entry
├── README.md                  # Project documentation
├── main.tf                    # Root module configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Azure provider config
├── terraform.tfvars           # Environment values
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── modules/
    ├── networking/            # If enabled
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── containers/            # If enabled
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── storage/               # If enabled
    ├── database/              # If enabled
    ├── security/              # If enabled
    └── monitoring/            # If enabled
```

## Module Details

### Networking Module

Creates the foundational network infrastructure:

```hcl
# Resources created:
- azurerm_virtual_network
- azurerm_subnet (public, private, database, aks)
- azurerm_network_security_group
- azurerm_route_table
- azurerm_nat_gateway (if enabled)
- azurerm_public_ip
```

**Configuration:**

```hcl
variable "network_config" {
  address_space      = ["10.0.0.0/16"]
  enable_nat_gateway = true
  enable_bastion     = false
  enable_firewall    = false
}
```

### Containers Module

Creates AKS cluster with supporting resources:

```hcl
# Resources created:
- azurerm_kubernetes_cluster
- azurerm_container_registry
- azurerm_user_assigned_identity
- azurerm_role_assignment (ACR pull)
```

**Configuration:**

```hcl
variable "aks_config" {
  kubernetes_version = "1.29"
  default_node_pool = {
    vm_size    = "Standard_D4s_v5"
    node_count = 3
    min_count  = 2
    max_count  = 10
  }
  enable_azure_policy  = true
  enable_oms_agent     = true
  network_plugin       = "azure"
}
```

### Storage Module

Creates storage infrastructure:

```hcl
# Resources created:
- azurerm_storage_account
- azurerm_storage_container
- azurerm_storage_share
- azurerm_private_endpoint (if private)
```

### Database Module

Creates managed database services:

```hcl
# Resources created (based on selection):
- azurerm_postgresql_flexible_server
- azurerm_mssql_server + azurerm_mssql_database
- azurerm_cosmosdb_account
- azurerm_redis_cache
```

### Security Module

Creates security infrastructure:

```hcl
# Resources created:
- azurerm_key_vault
- azurerm_key_vault_access_policy
- azurerm_user_assigned_identity
- azurerm_private_endpoint (if private)
```

### Monitoring Module

Creates observability stack:

```hcl
# Resources created:
- azurerm_log_analytics_workspace
- azurerm_application_insights
- azurerm_monitor_action_group
- azurerm_monitor_metric_alert
- azurerm_monitor_diagnostic_setting
```

## Environment Configuration

### Development (dev.tfvars)

```hcl
environment = "dev"

# Cost optimization
enable_high_availability = false
enable_dr               = false
enable_auto_shutdown    = true
auto_shutdown_schedule  = "0 19 * * 1-5"

# Smaller SKUs
aks_node_count = 1
aks_vm_size    = "Standard_D2s_v5"
sql_sku        = "GP_S_Gen5_1"
```

### Staging (staging.tfvars)

```hcl
environment = "stg"

enable_high_availability = true
enable_dr               = false
enable_auto_shutdown    = false

aks_node_count = 2
aks_vm_size    = "Standard_D4s_v5"
sql_sku        = "GP_Gen5_2"
```

### Production (prod.tfvars)

```hcl
environment = "prod"

enable_high_availability = true
enable_dr               = true
enable_auto_shutdown    = false

aks_node_count = 3
aks_vm_size    = "Standard_D4s_v5"
sql_sku        = "GP_Gen5_4"

# Zone redundancy
zones = ["1", "2", "3"]
```

## Deployment

### Prerequisites

1. Azure CLI installed and authenticated
2. Terraform >= 1.5.0
3. Appropriate Azure permissions

### Deploy

```bash
# Initialize
terraform init

# Plan with environment
terraform plan -var-file=environments/prod.tfvars

# Apply
terraform apply -var-file=environments/prod.tfvars
```

### CI/CD Integration

The generated project includes GitHub Actions workflow:

```yaml
# .github/workflows/terraform.yml
name: Terraform
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan
```

## Customization

### Adding Custom Modules

1. Create module directory in `modules/`
2. Add reference in `main.tf`
3. Add variables in `variables.tf`
4. Add outputs in `outputs.tf`

### Modifying Defaults

Edit `terraform.tfvars` or environment-specific files.

## Architecture Diagram

```
                           ┌─────────────────┐
                           │   Azure Front   │
                           │      Door       │
                           └────────┬────────┘
                                    │
┌───────────────────────────────────┼───────────────────────────────────┐
│                              VNet │                                    │
│                                   │                                    │
│  ┌─────────────────┐    ┌────────┴────────┐    ┌─────────────────┐  │
│  │  Public Subnet  │    │  Private Subnet │    │ Database Subnet │  │
│  │                 │    │                 │    │                 │  │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │  │
│  │  │    NAT    │  │    │  │    AKS    │  │    │  │  Postgres │  │  │
│  │  │  Gateway  │  │    │  │  Cluster  │  │    │  │ (Private) │  │  │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │  │
│  │                 │    │                 │    │                 │  │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │  │
│  │  │    LB     │  │    │  │    ACR    │  │    │  │   Redis   │  │  │
│  │  └───────────┘  │    │  │ (Private) │  │    │  │ (Private) │  │  │
│  │                 │    │  └───────────┘  │    │  └───────────┘  │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Supporting Services                           │ │
│  │                                                                  │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │ │
│  │  │Key Vault │  │ Storage  │  │   Log    │  │   App Insights   │ │ │
│  │  │          │  │ Account  │  │Analytics │  │                  │ │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

## Cost Estimation

| Environment | Estimated Monthly Cost |
|-------------|----------------------|
| Development | $200-400 |
| Staging | $500-800 |
| Production | $1,500-3,000+ |

*Costs vary based on usage, regions, and enabled modules.*
