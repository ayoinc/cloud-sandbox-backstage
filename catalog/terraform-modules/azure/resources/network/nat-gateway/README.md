# Azure NAT Gateway

Terraform module for provisioning Azure NAT Gateway.

## Overview

This module creates and manages Azure NAT Gateway with production-ready defaults and best practices.

## Usage

```hcl
module "nat_gateway" {
  source = "path/to/modules/azurerm/resources/network/nat-gateway"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `resource_group_name` | See variables.tf | `any` | See default |
| `location` | See variables.tf | `any` | See default |
| `name` | See variables.tf | `any` | See default |
| `sku_name` | See variables.tf | `any` | See default |
| `idle_timeout_in_minutes` | See variables.tf | `any` | See default |
| `zones` | See variables.tf | `any` | See default |
| `public_ip_count` | See variables.tf | `any` | See default |
| `use_public_ip_prefix` | See variables.tf | `any` | See default |
| `public_ip_prefix_length` | See variables.tf | `any` | See default |
| `subnet_ids` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `nat_gateway_id` | See outputs.tf |
| `nat_gateway_name` | See outputs.tf |
| `public_ip_addresses` | See outputs.tf |
| `public_ip_prefix_id` | See outputs.tf |
| `resource_guid` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
