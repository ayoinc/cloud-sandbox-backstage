# GCP Cloud Spanner

Terraform module for provisioning GCP Cloud Spanner.

## Overview

This module creates and manages GCP Cloud Spanner with production-ready defaults and best practices.

## Usage

```hcl
module "spanner" {
  source = "path/to/modules/google/resources/database/spanner"

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

| Name                    | Description      | Type  | Required    |
| ----------------------- | ---------------- | ----- | ----------- |
| `project_name`          | See variables.tf | `any` | See default |
| `project_id`            | See variables.tf | `any` | See default |
| `environment`           | See variables.tf | `any` | See default |
| `instance_name`         | See variables.tf | `any` | See default |
| `display_name`          | See variables.tf | `any` | See default |
| `config`                | See variables.tf | `any` | See default |
| `num_nodes`             | See variables.tf | `any` | See default |
| `processing_units`      | See variables.tf | `any` | See default |
| `databases`             | See variables.tf | `any` | See default |
| `instance_iam_bindings` | See variables.tf | `any` | See default |
| `database_iam_bindings` | See variables.tf | `any` | See default |
| `labels`                | See variables.tf | `any` | See default |

## Outputs

| Name              | Description    |
| ----------------- | -------------- |
| `instance_id`     | See outputs.tf |
| `instance_name`   | See outputs.tf |
| `instance_state`  | See outputs.tf |
| `database_ids`    | See outputs.tf |
| `database_states` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
