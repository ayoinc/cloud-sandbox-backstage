# Azure Diagnostic Settings

Terraform module for provisioning Azure Diagnostic Settings.

## Overview

This module creates and manages Azure Diagnostic Settings with production-ready defaults and best practices.

## Usage

```hcl
module "diagnostic_settings" {
  source = "path/to/modules/azurerm/resources/monitoring/diagnostic-settings"

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
| `name` | See variables.tf | `any` | See default |
| `target_resource_id` | See variables.tf | `any` | See default |
| `log_analytics_workspace_id` | See variables.tf | `any` | See default |
| `storage_account_id` | See variables.tf | `any` | See default |
| `eventhub_authorization_rule_id` | See variables.tf | `any` | See default |
| `eventhub_name` | See variables.tf | `any` | See default |
| `partner_solution_id` | See variables.tf | `any` | See default |
| `enabled_logs` | See variables.tf | `any` | See default |
| `metrics` | See variables.tf | `any` | See default |
| `log_analytics_destination_type` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `diagnostic_setting_id` | See outputs.tf |
| `diagnostic_setting_name` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
