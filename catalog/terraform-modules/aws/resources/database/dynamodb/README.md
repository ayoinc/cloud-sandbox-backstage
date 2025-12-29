# AWS DynamoDB

Terraform module for provisioning AWS DynamoDB.

## Overview

This module creates and manages AWS DynamoDB with production-ready defaults and best practices.

## Usage

```hcl
module "dynamodb" {
  source = "path/to/modules/aws/resources/database/dynamodb"

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
| `table_name` | See variables.tf | `any` | See default |
| `billing_mode` | See variables.tf | `any` | See default |
| `read_capacity` | See variables.tf | `any` | See default |
| `write_capacity` | See variables.tf | `any` | See default |
| `hash_key` | See variables.tf | `any` | See default |
| `hash_key_type` | See variables.tf | `any` | See default |
| `range_key` | See variables.tf | `any` | See default |
| `range_key_type` | See variables.tf | `any` | See default |
| `attributes` | See variables.tf | `any` | See default |
| `global_secondary_indexes` | See variables.tf | `any` | See default |
| `local_secondary_indexes` | See variables.tf | `any` | See default |
| `enable_point_in_time_recovery` | See variables.tf | `any` | See default |
| `enable_encryption` | See variables.tf | `any` | See default |
| `kms_key_arn` | See variables.tf | `any` | See default |
| `ttl_attribute_name` | See variables.tf | `any` | See default |
| `enable_streams` | See variables.tf | `any` | See default |
| `stream_view_type` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `table_id` | See outputs.tf |
| `table_arn` | See outputs.tf |
| `table_name` | See outputs.tf |
| `table_stream_arn` | See outputs.tf |
| `table_stream_label` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
