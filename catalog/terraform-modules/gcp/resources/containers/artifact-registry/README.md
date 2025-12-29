# GCP Artifact Registry

Terraform module for provisioning GCP Artifact Registry.

## Overview

This module creates and manages GCP Artifact Registry with production-ready defaults and best practices.

## Usage

```hcl
module "artifact_registry" {
  source = "path/to/modules/google/resources/containers/artifact-registry"

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

| Name                     | Description      | Type  | Required    |
| ------------------------ | ---------------- | ----- | ----------- |
| `project_name`           | See variables.tf | `any` | See default |
| `project_id`             | See variables.tf | `any` | See default |
| `environment`            | See variables.tf | `any` | See default |
| `region`                 | See variables.tf | `any` | See default |
| `repository_id`          | See variables.tf | `any` | See default |
| `description`            | See variables.tf | `any` | See default |
| `format`                 | See variables.tf | `any` | See default |
| `mode`                   | See variables.tf | `any` | See default |
| `kms_key_name`           | See variables.tf | `any` | See default |
| `cleanup_policy_dry_run` | See variables.tf | `any` | See default |
| `cleanup_policies`       | See variables.tf | `any` | See default |
| `iam_members`            | See variables.tf | `any` | See default |
| `labels`                 | See variables.tf | `any` | See default |

## Outputs

| Name              | Description    |
| ----------------- | -------------- |
| `repository_id`   | See outputs.tf |
| `repository_name` | See outputs.tf |
| `create_time`     | See outputs.tf |
| `update_time`     | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
