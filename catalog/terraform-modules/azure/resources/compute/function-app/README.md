# Azure Function App

Terraform module for provisioning Azure Function App.

## Overview

This module creates and manages Azure Function App with production-ready defaults and best practices.

## Usage

```hcl
module "function_app" {
  source = "path/to/modules/azurerm/resources/compute/function-app"

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
| `function_app_name` | See variables.tf | `any` | See default |
| `os_type` | See variables.tf | `any` | See default |
| `sku_name` | See variables.tf | `any` | See default |
| `storage_account_name` | See variables.tf | `any` | See default |
| `storage_account_access_key` | See variables.tf | `any` | See default |
| `runtime_stack` | See variables.tf | `any` | See default |
| `runtime_version` | See variables.tf | `any` | See default |
| `app_settings` | See variables.tf | `any` | See default |
| `application_insights_connection_string` | See variables.tf | `any` | See default |
| `enable_system_identity` | See variables.tf | `any` | See default |
| `vnet_integration_subnet_id` | See variables.tf | `any` | See default |
| `cors_allowed_origins` | See variables.tf | `any` | See default |
| `https_only` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `service_plan_id` | See outputs.tf |
| `function_app_id` | See outputs.tf |
| `function_app_name` | See outputs.tf |
| `default_hostname` | See outputs.tf |
| `identity_principal_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
