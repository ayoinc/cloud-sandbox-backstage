# GCP Secret Manager

Terraform module for provisioning GCP Secret Manager.

## Overview

This module creates and manages GCP Secret Manager with production-ready defaults and best practices.

## Usage

```hcl
module "secret_manager" {
  source = "path/to/modules/google/resources/security/secret-manager"

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
| `secrets` | See variables.tf | `any` | See default |
| `labels` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `secret_ids` | See outputs.tf |
| `secret_names` | See outputs.tf |
| `secret_version_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
