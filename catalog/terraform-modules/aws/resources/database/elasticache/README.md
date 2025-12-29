# AWS ElastiCache

Terraform module for provisioning AWS ElastiCache.

## Overview

This module creates and manages AWS ElastiCache with production-ready defaults and best practices.

## Usage

```hcl
module "elasticache" {
  source = "path/to/modules/aws/resources/database/elasticache"

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
| `engine` | See variables.tf | `any` | See default |
| `engine_version` | See variables.tf | `any` | See default |
| `node_type` | See variables.tf | `any` | See default |
| `num_cache_clusters` | See variables.tf | `any` | See default |
| `parameter_group_family` | See variables.tf | `any` | See default |
| `subnet_ids` | See variables.tf | `any` | See default |
| `security_group_ids` | See variables.tf | `any` | See default |
| `port` | See variables.tf | `any` | See default |
| `automatic_failover_enabled` | See variables.tf | `any` | See default |
| `multi_az_enabled` | See variables.tf | `any` | See default |
| `at_rest_encryption_enabled` | See variables.tf | `any` | See default |
| `transit_encryption_enabled` | See variables.tf | `any` | See default |
| `auth_token` | See variables.tf | `any` | See default |
| `snapshot_retention_limit` | See variables.tf | `any` | See default |
| `snapshot_window` | See variables.tf | `any` | See default |
| `maintenance_window` | See variables.tf | `any` | See default |
| `apply_immediately` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `replication_group_id` | See outputs.tf |
| `replication_group_arn` | See outputs.tf |
| `primary_endpoint_address` | See outputs.tf |
| `reader_endpoint_address` | See outputs.tf |
| `configuration_endpoint_address` | See outputs.tf |
| `port` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
