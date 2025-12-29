# GCP Pub/Sub

Terraform module for provisioning GCP Pub/Sub.

## Overview

This module creates and manages GCP Pub/Sub with production-ready defaults and best practices.

## Usage

```hcl
module "pub_sub" {
  source = "path/to/modules/google/resources/messaging/pub-sub"

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

| Name                         | Description      | Type  | Required    |
| ---------------------------- | ---------------- | ----- | ----------- |
| `project_name`               | See variables.tf | `any` | See default |
| `project_id`                 | See variables.tf | `any` | See default |
| `environment`                | See variables.tf | `any` | See default |
| `topic_name`                 | See variables.tf | `any` | See default |
| `message_retention_duration` | See variables.tf | `any` | See default |
| `kms_key_name`               | See variables.tf | `any` | See default |
| `schema_name`                | See variables.tf | `any` | See default |
| `schema_type`                | See variables.tf | `any` | See default |
| `schema_definition`          | See variables.tf | `any` | See default |
| `subscriptions`              | See variables.tf | `any` | See default |
| `topic_iam_bindings`         | See variables.tf | `any` | See default |
| `labels`                     | See variables.tf | `any` | See default |

## Outputs

| Name                 | Description    |
| -------------------- | -------------- |
| `topic_id`           | See outputs.tf |
| `topic_name`         | See outputs.tf |
| `subscription_ids`   | See outputs.tf |
| `subscription_paths` | See outputs.tf |
| `schema_id`          | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
