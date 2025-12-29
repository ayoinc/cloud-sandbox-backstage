# GCP IAM

Terraform module for provisioning GCP IAM.

## Overview

This module creates and manages GCP IAM with production-ready defaults and best practices.

## Usage

```hcl
module "iam" {
  source = "path/to/modules/google/resources/core/iam"

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
| `project_iam_bindings` | See variables.tf | `any` | See default |
| `custom_roles` | See variables.tf | `any` | See default |
| `organization_id` | See variables.tf | `any` | See default |
| `organization_iam_bindings` | See variables.tf | `any` | See default |
| `folder_id` | See variables.tf | `any` | See default |
| `folder_iam_bindings` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `project_iam_member_ids` | See outputs.tf |
| `custom_role_ids` | See outputs.tf |
| `custom_role_names` | See outputs.tf |
| `organization_iam_member_ids` | See outputs.tf |
| `folder_iam_member_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
