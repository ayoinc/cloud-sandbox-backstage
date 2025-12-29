# Azure Event Hub

Terraform module for provisioning Azure Event Hub.

## Overview

This module creates and manages Azure Event Hub with production-ready defaults and best practices.

## Usage

```hcl
module "event_hub" {
  source = "path/to/modules/azurerm/resources/messaging/event-hub"

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

| Name                       | Description      | Type  | Required    |
| -------------------------- | ---------------- | ----- | ----------- |
| `project_name`             | See variables.tf | `any` | See default |
| `environment`              | See variables.tf | `any` | See default |
| `resource_group_name`      | See variables.tf | `any` | See default |
| `location`                 | See variables.tf | `any` | See default |
| `namespace_name`           | See variables.tf | `any` | See default |
| `sku`                      | See variables.tf | `any` | See default |
| `capacity`                 | See variables.tf | `any` | See default |
| `auto_inflate_enabled`     | See variables.tf | `any` | See default |
| `maximum_throughput_units` | See variables.tf | `any` | See default |
| `zone_redundant`           | See variables.tf | `any` | See default |
| `eventhubs`                | See variables.tf | `any` | See default |
| `consumer_groups`          | See variables.tf | `any` | See default |
| `authorization_rules`      | See variables.tf | `any` | See default |
| `tags`                     | See variables.tf | `any` | See default |

## Outputs

| Name                                | Description    |
| ----------------------------------- | -------------- |
| `namespace_id`                      | See outputs.tf |
| `namespace_name`                    | See outputs.tf |
| `default_primary_connection_string` | See outputs.tf |
| `eventhub_ids`                      | See outputs.tf |
| `consumer_group_ids`                | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
