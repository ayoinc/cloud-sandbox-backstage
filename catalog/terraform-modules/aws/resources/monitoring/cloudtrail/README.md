# AWS CloudTrail

Terraform module for provisioning AWS CloudTrail.

## Overview

This module creates and manages AWS CloudTrail with production-ready defaults and best practices.

## Usage

```hcl
module "cloudtrail" {
  source = "path/to/modules/aws/resources/monitoring/cloudtrail"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Inputs

| Name                            | Description      | Type  | Required    |
| ------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                  | See variables.tf | `any` | See default |
| `environment`                   | See variables.tf | `any` | See default |
| `trail_name`                    | See variables.tf | `any` | See default |
| `s3_bucket_name`                | See variables.tf | `any` | See default |
| `s3_key_prefix`                 | See variables.tf | `any` | See default |
| `include_global_service_events` | See variables.tf | `any` | See default |
| `is_multi_region_trail`         | See variables.tf | `any` | See default |
| `is_organization_trail`         | See variables.tf | `any` | See default |
| `enable_log_file_validation`    | See variables.tf | `any` | See default |
| `kms_key_id`                    | See variables.tf | `any` | See default |
| `cloud_watch_logs_group_arn`    | See variables.tf | `any` | See default |
| `cloud_watch_logs_role_arn`     | See variables.tf | `any` | See default |
| `enable_logging`                | See variables.tf | `any` | See default |
| `event_selectors`               | See variables.tf | `any` | See default |
| `insight_selectors`             | See variables.tf | `any` | See default |
| `tags`                          | See variables.tf | `any` | See default |

## Outputs

| Name                | Description    |
| ------------------- | -------------- |
| `trail_id`          | See outputs.tf |
| `trail_arn`         | See outputs.tf |
| `trail_home_region` | See outputs.tf |
| `trail_status`      | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
