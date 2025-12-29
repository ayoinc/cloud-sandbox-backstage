# AWS Elastic File System

Terraform module for provisioning AWS Elastic File System.

## Overview

This module creates and manages AWS Elastic File System with production-ready defaults and best practices.

## Usage

```hcl
module "efs" {
  source = "path/to/modules/aws/resources/storage/efs"

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
| `creation_token` | See variables.tf | `any` | See default |
| `encrypted` | See variables.tf | `any` | See default |
| `kms_key_id` | See variables.tf | `any` | See default |
| `performance_mode` | See variables.tf | `any` | See default |
| `throughput_mode` | See variables.tf | `any` | See default |
| `provisioned_throughput_in_mibps` | See variables.tf | `any` | See default |
| `lifecycle_policies` | See variables.tf | `any` | See default |
| `subnet_ids` | See variables.tf | `any` | See default |
| `security_group_ids` | See variables.tf | `any` | See default |
| `enable_backup` | See variables.tf | `any` | See default |
| `file_system_policy` | See variables.tf | `any` | See default |
| `access_points` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `file_system_id` | See outputs.tf |
| `file_system_arn` | See outputs.tf |
| `file_system_dns_name` | See outputs.tf |
| `mount_target_ids` | See outputs.tf |
| `mount_target_dns_names` | See outputs.tf |
| `access_point_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
