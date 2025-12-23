# Azure Virtual Network Template

This template creates an Azure Virtual Network (VNet) with subnets, network security groups, and peering configurations.

## Features

- **Virtual Network** - Configurable address space and DNS settings
- **Subnets** - Multiple subnet support with service endpoints
- **Network Security Groups** - Pre-configured security rules
- **VNet Peering** - Connect to other virtual networks
- **Private DNS** - Optional private DNS zone integration

## Prerequisites

- Azure Subscription
- Terraform >= 1.5
- Azure CLI configured
- Appropriate RBAC permissions

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Azure VNet                           │
│                   10.0.0.0/16                           │
│                                                         │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Public Subnet  │  │  Private Subnet │              │
│  │  10.0.1.0/24    │  │  10.0.2.0/24    │              │
│  │                 │  │                 │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │    NSG    │  │  │  │    NSG    │  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  └─────────────────┘  └─────────────────┘              │
│                                                         │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │ Database Subnet │  │   AKS Subnet    │              │
│  │  10.0.3.0/24    │  │  10.0.4.0/22    │              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `vnet_name` | Name of the virtual network | - |
| `resource_group_name` | Azure resource group | - |
| `location` | Azure region | `eastus` |
| `address_space` | VNet address space | `["10.0.0.0/16"]` |
| `subnets` | Subnet configurations | See variables.tf |

## Subnet Configuration

```hcl
subnets = {
  public = {
    address_prefix = "10.0.1.0/24"
    service_endpoints = ["Microsoft.Storage"]
  }
  private = {
    address_prefix = "10.0.2.0/24"
    service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]
  }
}
```

## Outputs

- `vnet_id` - Virtual Network resource ID
- `vnet_name` - Virtual Network name
- `subnet_ids` - Map of subnet names to IDs

## Support

Contact the Platform Team for assistance.
