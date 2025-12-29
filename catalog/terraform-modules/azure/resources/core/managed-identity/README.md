# Azure Managed Identity

Terraform module for provisioning Azure Managed Identity.

## Overview

This module creates and manages Azure Managed Identity with production-ready defaults and best practices.

## Usage

```hcl
module "managed_identity" {
  source = "path/to/modules/azurerm/resources/core/managed-identity"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `resource_group_name` | See variables.tf | `any` | See default |
| `location` | See variables.tf | `any` | See default |
| `identity_name` | See variables.tf | `any` | See default |
| `role_assignments` | See variables.tf | `any` | See default |
| `federated_identity_credentials` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `identity_id` | See outputs.tf |
| `identity_name` | See outputs.tf |
| `principal_id` | See outputs.tf |
| `client_id` | See outputs.tf |
| `tenant_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
