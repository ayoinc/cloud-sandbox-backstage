# GCP Memorystore

Terraform module for provisioning GCP Memorystore.

## Overview

This module creates and manages GCP Memorystore with production-ready defaults and best practices.

## Usage

```hcl
module "memorystore" {
  source = "path/to/modules/google/resources/database/memorystore"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| google    | >= 5.0  |

## Inputs

| Name                      | Description      | Type  | Required    |
| ------------------------- | ---------------- | ----- | ----------- |
| `project_name`            | See variables.tf | `any` | See default |
| `project_id`              | See variables.tf | `any` | See default |
| `environment`             | See variables.tf | `any` | See default |
| `region`                  | See variables.tf | `any` | See default |
| `name`                    | See variables.tf | `any` | See default |
| `display_name`            | See variables.tf | `any` | See default |
| `tier`                    | See variables.tf | `any` | See default |
| `memory_size_gb`          | See variables.tf | `any` | See default |
| `redis_version`           | See variables.tf | `any` | See default |
| `authorized_network`      | See variables.tf | `any` | See default |
| `connect_mode`            | See variables.tf | `any` | See default |
| `reserved_ip_range`       | See variables.tf | `any` | See default |
| `auth_enabled`            | See variables.tf | `any` | See default |
| `transit_encryption_mode` | See variables.tf | `any` | See default |
| `customer_managed_key`    | See variables.tf | `any` | See default |
| `persistence_mode`        | See variables.tf | `any` | See default |
| `rdb_snapshot_period`     | See variables.tf | `any` | See default |
| `rdb_snapshot_start_time` | See variables.tf | `any` | See default |
| `maintenance_day`         | See variables.tf | `any` | See default |
| `maintenance_start_hour`  | See variables.tf | `any` | See default |
| `redis_configs`           | See variables.tf | `any` | See default |
| `replica_count`           | See variables.tf | `any` | See default |
| `read_replicas_mode`      | See variables.tf | `any` | See default |
| `labels`                  | See variables.tf | `any` | See default |

## Outputs

| Name                       | Description    |
| -------------------------- | -------------- |
| `instance_id`              | See outputs.tf |
| `instance_name`            | See outputs.tf |
| `host`                     | See outputs.tf |
| `port`                     | See outputs.tf |
| `current_location_id`      | See outputs.tf |
| `auth_string`              | See outputs.tf |
| `persistence_iam_identity` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
