# GCP Firestore

Terraform module for provisioning GCP Firestore.

## Overview

This module creates and manages GCP Firestore with production-ready defaults and best practices.

## Usage

```hcl
module "firestore" {
  source = "path/to/modules/google/resources/database/firestore"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `project_id` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `location_id` | See variables.tf | `any` | See default |
| `database_id` | See variables.tf | `any` | See default |
| `type` | See variables.tf | `any` | See default |
| `concurrency_mode` | See variables.tf | `any` | See default |
| `app_engine_integration_mode` | See variables.tf | `any` | See default |
| `point_in_time_recovery_enablement` | See variables.tf | `any` | See default |
| `delete_protection_state` | See variables.tf | `any` | See default |
| `cmek_key_name` | See variables.tf | `any` | See default |
| `indexes` | See variables.tf | `any` | See default |
| `field_configs` | See variables.tf | `any` | See default |
| `labels` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `database_id` | See outputs.tf |
| `database_name` | See outputs.tf |
| `uid` | See outputs.tf |
| `create_time` | See outputs.tf |
| `update_time` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
