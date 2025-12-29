# Azure Bastion Host

Terraform module for provisioning Azure Bastion Host.

## Overview

This module creates and manages Azure Bastion Host with production-ready defaults and best practices.

## Usage

```hcl
module "bastion" {
  source = "path/to/modules/azurerm/resources/network/bastion"

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

| Name                     | Description      | Type  | Required    |
| ------------------------ | ---------------- | ----- | ----------- |
| `project_name`           | See variables.tf | `any` | See default |
| `environment`            | See variables.tf | `any` | See default |
| `resource_group_name`    | See variables.tf | `any` | See default |
| `location`               | See variables.tf | `any` | See default |
| `name`                   | See variables.tf | `any` | See default |
| `sku`                    | See variables.tf | `any` | See default |
| `subnet_id`              | See variables.tf | `any` | See default |
| `scale_units`            | See variables.tf | `any` | See default |
| `copy_paste_enabled`     | See variables.tf | `any` | See default |
| `file_copy_enabled`      | See variables.tf | `any` | See default |
| `ip_connect_enabled`     | See variables.tf | `any` | See default |
| `shareable_link_enabled` | See variables.tf | `any` | See default |
| `tunneling_enabled`      | See variables.tf | `any` | See default |
| `tags`                   | See variables.tf | `any` | See default |

## Outputs

| Name                | Description    |
| ------------------- | -------------- |
| `bastion_id`        | See outputs.tf |
| `bastion_name`      | See outputs.tf |
| `bastion_dns_name`  | See outputs.tf |
| `public_ip_address` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
