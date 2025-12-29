# Azure Azure Firewall

Terraform module for provisioning Azure Azure Firewall.

## Overview

This module creates and manages Azure Azure Firewall with production-ready defaults and best practices.

## Usage

```hcl
module "firewall" {
  source = "path/to/modules/azurerm/resources/network/firewall"

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
| `sku_tier` | See variables.tf | `any` | See default |
| `subnet_id` | See variables.tf | `any` | See default |
| `zones` | See variables.tf | `any` | See default |
| `threat_intel_mode` | See variables.tf | `any` | See default |
| `dns_servers` | See variables.tf | `any` | See default |
| `dns_proxy_enabled` | See variables.tf | `any` | See default |
| `network_rule_collections` | See variables.tf | `any` | See default |
| `application_rule_collections` | See variables.tf | `any` | See default |
| `nat_rule_collections` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `firewall_id` | See outputs.tf |
| `firewall_name` | See outputs.tf |
| `firewall_private_ip` | See outputs.tf |
| `firewall_public_ip` | See outputs.tf |
| `firewall_policy_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
