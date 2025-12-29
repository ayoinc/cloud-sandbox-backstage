# AWS CloudWatch

Terraform module for provisioning AWS CloudWatch.

## Overview

This module creates and manages AWS CloudWatch with production-ready defaults and best practices.

## Usage

```hcl
module "cloudwatch" {
  source = "path/to/modules/aws/resources/monitoring/cloudwatch"

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
| `log_group_name` | See variables.tf | `any` | See default |
| `retention_in_days` | See variables.tf | `any` | See default |
| `kms_key_id` | See variables.tf | `any` | See default |
| `alarms` | See variables.tf | `any` | See default |
| `log_metric_filters` | See variables.tf | `any` | See default |
| `create_dashboard` | See variables.tf | `any` | See default |
| `dashboard_name` | See variables.tf | `any` | See default |
| `dashboard_body` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `log_group_arn` | See outputs.tf |
| `log_group_name` | See outputs.tf |
| `alarm_arns` | See outputs.tf |
| `dashboard_arn` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
