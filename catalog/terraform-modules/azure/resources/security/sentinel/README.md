# Azure Microsoft Sentinel

Terraform module for provisioning Azure Microsoft Sentinel.

## Overview

This module creates and manages Azure Microsoft Sentinel with production-ready defaults and best practices.

## Usage

```hcl
module "sentinel" {
  source = "path/to/modules/azurerm/resources/security/sentinel"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| azurerm   | >= 5.0  |

## Inputs

| Name                                   | Description      | Type  | Required    |
| -------------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                         | See variables.tf | `any` | See default |
| `environment`                          | See variables.tf | `any` | See default |
| `resource_group_name`                  | See variables.tf | `any` | See default |
| `log_analytics_workspace_id`           | See variables.tf | `any` | See default |
| `log_analytics_workspace_name`         | See variables.tf | `any` | See default |
| `enable_aad_connector`                 | See variables.tf | `any` | See default |
| `enable_asc_connector`                 | See variables.tf | `any` | See default |
| `enable_mcas_connector`                | See variables.tf | `any` | See default |
| `enable_office365_connector`           | See variables.tf | `any` | See default |
| `enable_threat_intelligence_connector` | See variables.tf | `any` | See default |
| `office365_exchange_enabled`           | See variables.tf | `any` | See default |
| `office365_sharepoint_enabled`         | See variables.tf | `any` | See default |
| `office365_teams_enabled`              | See variables.tf | `any` | See default |
| `alert_rules`                          | See variables.tf | `any` | See default |
| `automation_rules`                     | See variables.tf | `any` | See default |

## Outputs

| Name                     | Description    |
| ------------------------ | -------------- |
| `sentinel_onboarding_id` | See outputs.tf |
| `data_connector_ids`     | See outputs.tf |
| `alert_rule_ids`         | See outputs.tf |
| `automation_rule_ids`    | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
