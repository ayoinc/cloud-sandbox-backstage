# Azure Resource Group Module

Creates Azure Resource Groups with proper naming, tagging, and lifecycle management.

## Overview

This module creates an Azure Resource Group following Azure CAF naming conventions. It supports:

- Automatic naming with `rg-` prefix
- Tag inheritance and management
- Optional delete locks for production environments
- Support for managed-by relationships

## Module Location

```
azure/resources/core/resource-group/
```

## Usage

### Basic Usage

```hcl
module "resource_group" {
  source = "path/to/azure/resources/core/resource-group"

  name        = "my-project"
  location    = "eastus"
  project     = "my-project"
  environment = "dev"
  
  tags = {
    CostCenter = "engineering"
    Owner      = "platform-team"
  }
}
```

### Production with Delete Lock

```hcl
module "resource_group_prod" {
  source = "path/to/azure/resources/core/resource-group"

  name               = "my-project"
  location           = "eastus"
  project            = "my-project"
  environment        = "prod"
  enable_delete_lock = true
  
  tags = {
    CostCenter = "engineering"
    Owner      = "platform-team"
    SLA        = "24x7"
  }
}
```

## Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | - | Name suffix for the resource group |
| `location` | string | yes | - | Azure region |
| `project` | string | yes | - | Project name for naming convention |
| `environment` | string | yes | - | Environment (dev, staging, prod) |
| `tags` | map(string) | no | `{}` | Tags to apply to the resource group |
| `enable_delete_lock` | bool | no | `false` | Enable delete lock on the resource group |
| `managed_by` | string | no | `null` | Resource ID of the managing resource |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The ID of the resource group |
| `name` | The name of the resource group |
| `location` | The location of the resource group |
| `tags` | The tags applied to the resource group |

## Naming Convention

The module automatically generates the resource group name using Azure CAF conventions:

```
rg-<name>-<environment>-<location>
```

Examples:
- `rg-my-project-dev-eastus`
- `rg-my-project-prod-westeurope`

## Best Practices

1. **Use Delete Locks in Production**: Enable `enable_delete_lock = true` for production resource groups to prevent accidental deletion.

2. **Consistent Tagging**: Always include required tags like `Project`, `Environment`, `CostCenter`, and `Owner`.

3. **Environment Validation**: The module validates that environment is one of: `dev`, `staging`, `prod`, `test`, `sandbox`.

4. **Managed Resources**: Use the `managed_by` variable when the resource group is managed by another Azure resource (e.g., AKS managed resource group).

## Integration with Other Modules

This module is designed to be used as a foundational module that other modules depend on:

```hcl
# Create resource group first
module "resource_group" {
  source = "path/to/azure/resources/core/resource-group"
  # ... configuration
}

# Then use it in other modules
module "virtual_network" {
  source = "path/to/azure/resources/network/virtual-network"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  # ... rest of configuration
}
```

## Testing

Run native Terraform tests:

```bash
cd azure/resources/core/resource-group
terraform init -backend=false
terraform test
```
