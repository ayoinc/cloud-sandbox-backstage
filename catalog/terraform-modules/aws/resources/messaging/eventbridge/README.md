# AWS EventBridge

Terraform module for provisioning AWS EventBridge.

## Overview

This module creates and manages AWS EventBridge with production-ready defaults and best practices.

## Usage

```hcl
module "eventbridge" {
  source = "path/to/modules/aws/resources/messaging/eventbridge"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `event_bus_name` | See variables.tf | `any` | See default |
| `rules` | See variables.tf | `any` | See default |
| `enable_archive` | See variables.tf | `any` | See default |
| `archive_retention_days` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `event_bus_name` | See outputs.tf |
| `event_bus_arn` | See outputs.tf |
| `rule_arns` | See outputs.tf |
| `archive_arn` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
