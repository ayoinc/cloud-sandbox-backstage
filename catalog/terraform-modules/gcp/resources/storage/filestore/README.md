# GCP Filestore

Terraform module for provisioning GCP Filestore.

## Overview

This module creates and manages GCP Filestore with production-ready defaults and best practices.

## Usage

```hcl
module "filestore" {
  source = "path/to/modules/google/resources/storage/filestore"

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

| Name                | Description      | Type  | Required    |
| ------------------- | ---------------- | ----- | ----------- |
| `project_name`      | See variables.tf | `any` | See default |
| `project_id`        | See variables.tf | `any` | See default |
| `environment`       | See variables.tf | `any` | See default |
| `zone`              | See variables.tf | `any` | See default |
| `name`              | See variables.tf | `any` | See default |
| `description`       | See variables.tf | `any` | See default |
| `tier`              | See variables.tf | `any` | See default |
| `file_shares`       | See variables.tf | `any` | See default |
| `network`           | See variables.tf | `any` | See default |
| `connect_mode`      | See variables.tf | `any` | See default |
| `reserved_ip_range` | See variables.tf | `any` | See default |
| `kms_key_name`      | See variables.tf | `any` | See default |
| `labels`            | See variables.tf | `any` | See default |

## Outputs

| Name            | Description    |
| --------------- | -------------- |
| `instance_id`   | See outputs.tf |
| `instance_name` | See outputs.tf |
| `networks`      | See outputs.tf |
| `file_shares`   | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
