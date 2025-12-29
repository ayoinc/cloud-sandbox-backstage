# Azure Front Door

Terraform module for provisioning Azure Front Door.

## Overview

This module creates and manages Azure Front Door with production-ready defaults and best practices.

## Usage

```hcl
module "front_door" {
  source = "path/to/modules/azurerm/resources/network/front-door"

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

| Name                  | Description      | Type  | Required    |
| --------------------- | ---------------- | ----- | ----------- |
| `project_name`        | See variables.tf | `any` | See default |
| `environment`         | See variables.tf | `any` | See default |
| `resource_group_name` | See variables.tf | `any` | See default |
| `profile_name`        | See variables.tf | `any` | See default |
| `sku_name`            | See variables.tf | `any` | See default |
| `endpoints`           | See variables.tf | `any` | See default |
| `origin_groups`       | See variables.tf | `any` | See default |
| `origins`             | See variables.tf | `any` | See default |
| `routes`              | See variables.tf | `any` | See default |
| `custom_domains`      | See variables.tf | `any` | See default |
| `waf_policy_id`       | See variables.tf | `any` | See default |
| `tags`                | See variables.tf | `any` | See default |

## Outputs

| Name                  | Description    |
| --------------------- | -------------- |
| `profile_id`          | See outputs.tf |
| `profile_name`        | See outputs.tf |
| `endpoint_host_names` | See outputs.tf |
| `origin_group_ids`    | See outputs.tf |
| `custom_domain_ids`   | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
