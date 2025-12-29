# AWS Simple Notification Service

Terraform module for provisioning AWS Simple Notification Service.

## Overview

This module creates and manages AWS Simple Notification Service with production-ready defaults and best practices.

## Usage

```hcl
module "sns" {
  source = "path/to/modules/aws/resources/messaging/sns"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Inputs

| Name                          | Description      | Type  | Required    |
| ----------------------------- | ---------------- | ----- | ----------- |
| `project_name`                | See variables.tf | `any` | See default |
| `environment`                 | See variables.tf | `any` | See default |
| `topic_name`                  | See variables.tf | `any` | See default |
| `fifo_topic`                  | See variables.tf | `any` | See default |
| `content_based_deduplication` | See variables.tf | `any` | See default |
| `kms_master_key_id`           | See variables.tf | `any` | See default |
| `delivery_policy`             | See variables.tf | `any` | See default |
| `subscriptions`               | See variables.tf | `any` | See default |
| `allowed_aws_services`        | See variables.tf | `any` | See default |
| `tags`                        | See variables.tf | `any` | See default |

## Outputs

| Name                | Description    |
| ------------------- | -------------- |
| `topic_id`          | See outputs.tf |
| `topic_arn`         | See outputs.tf |
| `topic_name`        | See outputs.tf |
| `subscription_arns` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
