# Azure PostgreSQL

Terraform module for provisioning Azure PostgreSQL.

## Overview

This module creates and manages Azure PostgreSQL with production-ready defaults and best practices.

## Usage

```hcl
module "postgresql" {
  source = "path/to/modules/azurerm/resources/database/postgresql"

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
| `server_name` | See variables.tf | `any` | See default |
| `administrator_login` | See variables.tf | `any` | See default |
| `administrator_password` | See variables.tf | `any` | See default |
| `sku_name` | See variables.tf | `any` | See default |
| `storage_mb` | See variables.tf | `any` | See default |
| `version` | See variables.tf | `any` | See default |
| `zone` | See variables.tf | `any` | See default |
| `high_availability_mode` | See variables.tf | `any` | See default |
| `standby_availability_zone` | See variables.tf | `any` | See default |
| `backup_retention_days` | See variables.tf | `any` | See default |
| `geo_redundant_backup_enabled` | See variables.tf | `any` | See default |
| `delegated_subnet_id` | See variables.tf | `any` | See default |
| `private_dns_zone_id` | See variables.tf | `any` | See default |
| `maintenance_window` | See variables.tf | `any` | See default |
| `databases` | See variables.tf | `any` | See default |
| `configurations` | See variables.tf | `any` | See default |
| `firewall_rules` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `server_id` | See outputs.tf |
| `server_name` | See outputs.tf |
| `server_fqdn` | See outputs.tf |
| `database_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
