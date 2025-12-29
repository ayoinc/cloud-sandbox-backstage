# GCP Service Account

Terraform module for provisioning GCP Service Account.

## Overview

This module creates and manages GCP Service Account with production-ready defaults and best practices.

## Usage

```hcl
module "service_account" {
  source = "path/to/modules/google/resources/core/service-account"

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

| Name            | Description      | Type  | Required    |
| --------------- | ---------------- | ----- | ----------- |
| `project_name`  | See variables.tf | `any` | See default |
| `project_id`    | See variables.tf | `any` | See default |
| `environment`   | See variables.tf | `any` | See default |
| `account_id`    | See variables.tf | `any` | See default |
| `display_name`  | See variables.tf | `any` | See default |
| `description`   | See variables.tf | `any` | See default |
| `project_roles` | See variables.tf | `any` | See default |
| `create_key`    | See variables.tf | `any` | See default |
| `key_algorithm` | See variables.tf | `any` | See default |
| `impersonators` | See variables.tf | `any` | See default |

## Outputs

| Name                        | Description    |
| --------------------------- | -------------- |
| `service_account_id`        | See outputs.tf |
| `service_account_email`     | See outputs.tf |
| `service_account_name`      | See outputs.tf |
| `service_account_unique_id` | See outputs.tf |
| `private_key`               | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
