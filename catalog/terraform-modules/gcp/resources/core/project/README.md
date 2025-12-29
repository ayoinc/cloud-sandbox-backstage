# GCP GCP Project

Terraform module for provisioning GCP GCP Project.

## Overview

This module creates and manages GCP GCP Project with production-ready defaults and best practices.

## Usage

```hcl
module "project" {
  source = "path/to/modules/google/resources/core/project"

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
| `org_id`                  | See variables.tf | `any` | See default |
| `folder_id`               | See variables.tf | `any` | See default |
| `billing_account`         | See variables.tf | `any` | See default |
| `auto_create_network`     | See variables.tf | `any` | See default |
| `activate_apis`           | See variables.tf | `any` | See default |
| `default_service_account` | See variables.tf | `any` | See default |
| `project_metadata`        | See variables.tf | `any` | See default |
| `labels`                  | See variables.tf | `any` | See default |

## Outputs

| Name             | Description    |
| ---------------- | -------------- |
| `project_id`     | See outputs.tf |
| `project_number` | See outputs.tf |
| `project_name`   | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
