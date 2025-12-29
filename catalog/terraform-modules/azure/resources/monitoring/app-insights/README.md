# Azure Application Insights

Terraform module for provisioning Azure Application Insights.

## Overview

This module creates and manages Azure Application Insights with production-ready defaults and best practices.

## Usage

```hcl
module "app_insights" {
  source = "path/to/modules/azurerm/resources/monitoring/app-insights"

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
| `name` | See variables.tf | `any` | See default |
| `application_type` | See variables.tf | `any` | See default |
| `workspace_id` | See variables.tf | `any` | See default |
| `retention_in_days` | See variables.tf | `any` | See default |
| `daily_data_cap_in_gb` | See variables.tf | `any` | See default |
| `daily_data_cap_notifications_disabled` | See variables.tf | `any` | See default |
| `sampling_percentage` | See variables.tf | `any` | See default |
| `disable_ip_masking` | See variables.tf | `any` | See default |
| `local_authentication_disabled` | See variables.tf | `any` | See default |
| `web_tests` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `app_insights_id` | See outputs.tf |
| `app_insights_name` | See outputs.tf |
| `instrumentation_key` | See outputs.tf |
| `connection_string` | See outputs.tf |
| `app_id` | See outputs.tf |
| `web_test_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
