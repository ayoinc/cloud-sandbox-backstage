# Azure Defender for Cloud

Terraform module for provisioning Azure Defender for Cloud.

## Overview

This module creates and manages Azure Defender for Cloud with production-ready defaults and best practices.

## Usage

```hcl
module "defender" {
  source = "path/to/modules/azurerm/resources/security/defender"

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

| Name                         | Description      | Type  | Required    |
| ---------------------------- | ---------------- | ----- | ----------- |
| `project_name`               | See variables.tf | `any` | See default |
| `environment`                | See variables.tf | `any` | See default |
| `pricing_tier`               | See variables.tf | `any` | See default |
| `resource_type_pricing`      | See variables.tf | `any` | See default |
| `security_contact_email`     | See variables.tf | `any` | See default |
| `security_contact_phone`     | See variables.tf | `any` | See default |
| `alert_notifications`        | See variables.tf | `any` | See default |
| `alerts_to_admins`           | See variables.tf | `any` | See default |
| `auto_provisioning`          | See variables.tf | `any` | See default |
| `log_analytics_workspace_id` | See variables.tf | `any` | See default |
| `enable_mcas_integration`    | See variables.tf | `any` | See default |
| `enable_wdatp_integration`   | See variables.tf | `any` | See default |

## Outputs

| Name                   | Description    |
| ---------------------- | -------------- |
| `pricing_ids`          | See outputs.tf |
| `security_contact_id`  | See outputs.tf |
| `auto_provisioning_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
