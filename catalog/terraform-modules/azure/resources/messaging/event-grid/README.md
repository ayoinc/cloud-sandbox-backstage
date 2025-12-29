# Azure Event Grid

Terraform module for provisioning Azure Event Grid.

## Overview

This module creates and manages Azure Event Grid with production-ready defaults and best practices.

## Usage

```hcl
module "event_grid" {
  source = "path/to/modules/azurerm/resources/messaging/event-grid"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| azurerm   | >= 5.0  |

## Inputs

| Name                                  | Description      | Type  | Required    |
| ------------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                        | See variables.tf | `any` | See default |
| `environment`                         | See variables.tf | `any` | See default |
| `resource_group_name`                 | See variables.tf | `any` | See default |
| `location`                            | See variables.tf | `any` | See default |
| `topic_name`                          | See variables.tf | `any` | See default |
| `create_custom_topic`                 | See variables.tf | `any` | See default |
| `create_system_topic`                 | See variables.tf | `any` | See default |
| `system_topic_source_arm_resource_id` | See variables.tf | `any` | See default |
| `system_topic_type`                   | See variables.tf | `any` | See default |
| `input_schema`                        | See variables.tf | `any` | See default |
| `subscriptions`                       | See variables.tf | `any` | See default |
| `create_domain`                       | See variables.tf | `any` | See default |
| `domain_name`                         | See variables.tf | `any` | See default |
| `tags`                                | See variables.tf | `any` | See default |

## Outputs

| Name                                  | Description    |
| ------------------------------------- | -------------- |
| `topic_id`                            | See outputs.tf |
| `topic_endpoint`                      | See outputs.tf |
| `topic_primary_access_key`            | See outputs.tf |
| `topic_secondary_access_key`          | See outputs.tf |
| `system_topic_id`                     | See outputs.tf |
| `system_topic_metric_arm_resource_id` | See outputs.tf |
| `domain_id`                           | See outputs.tf |
| `domain_endpoint`                     | See outputs.tf |
| `domain_primary_access_key`           | See outputs.tf |
| `domain_secondary_access_key`         | See outputs.tf |
| `subscription_ids`                    | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
