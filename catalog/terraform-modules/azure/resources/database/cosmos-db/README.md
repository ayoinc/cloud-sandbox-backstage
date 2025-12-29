# Azure Cosmos DB

Terraform module for provisioning Azure Cosmos DB.

## Overview

This module creates and manages Azure Cosmos DB with production-ready defaults and best practices.

## Usage

```hcl
module "cosmos_db" {
  source = "path/to/modules/azurerm/resources/database/cosmos-db"

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

| Name                                | Description      | Type  | Required    |
| ----------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                      | See variables.tf | `any` | See default |
| `environment`                       | See variables.tf | `any` | See default |
| `resource_group_name`               | See variables.tf | `any` | See default |
| `location`                          | See variables.tf | `any` | See default |
| `account_name`                      | See variables.tf | `any` | See default |
| `offer_type`                        | See variables.tf | `any` | See default |
| `kind`                              | See variables.tf | `any` | See default |
| `consistency_level`                 | See variables.tf | `any` | See default |
| `max_interval_in_seconds`           | See variables.tf | `any` | See default |
| `max_staleness_prefix`              | See variables.tf | `any` | See default |
| `geo_locations`                     | See variables.tf | `any` | See default |
| `enable_automatic_failover`         | See variables.tf | `any` | See default |
| `enable_multiple_write_locations`   | See variables.tf | `any` | See default |
| `enable_free_tier`                  | See variables.tf | `any` | See default |
| `capabilities`                      | See variables.tf | `any` | See default |
| `databases`                         | See variables.tf | `any` | See default |
| `enable_analytical_storage`         | See variables.tf | `any` | See default |
| `analytical_storage_schema_type`    | See variables.tf | `any` | See default |
| `backup_type`                       | See variables.tf | `any` | See default |
| `backup_interval_in_minutes`        | See variables.tf | `any` | See default |
| `backup_retention_in_hours`         | See variables.tf | `any` | See default |
| `backup_storage_redundancy`         | See variables.tf | `any` | See default |
| `ip_range_filter`                   | See variables.tf | `any` | See default |
| `is_virtual_network_filter_enabled` | See variables.tf | `any` | See default |
| `public_network_access_enabled`     | See variables.tf | `any` | See default |
| `virtual_network_rules`             | See variables.tf | `any` | See default |
| `private_endpoint_subnet_id`        | See variables.tf | `any` | See default |
| `private_endpoint_subresource`      | See variables.tf | `any` | See default |
| `private_dns_zone_ids`              | See variables.tf | `any` | See default |
| `identity_type`                     | See variables.tf | `any` | See default |
| `identity_ids`                      | See variables.tf | `any` | See default |
| `cors_rules`                        | See variables.tf | `any` | See default |
| `conflict_resolution_mode`          | See variables.tf | `any` | See default |
| `conflict_resolution_path`          | See variables.tf | `any` | See default |
| `conflict_resolution_procedure`     | See variables.tf | `any` | See default |
| `tags`                              | See variables.tf | `any` | See default |

## Outputs

| Name                              | Description    |
| --------------------------------- | -------------- |
| `account_id`                      | See outputs.tf |
| `account_name`                    | See outputs.tf |
| `endpoint`                        | See outputs.tf |
| `read_endpoints`                  | See outputs.tf |
| `write_endpoints`                 | See outputs.tf |
| `primary_key`                     | See outputs.tf |
| `secondary_key`                   | See outputs.tf |
| `primary_readonly_key`            | See outputs.tf |
| `secondary_readonly_key`          | See outputs.tf |
| `connection_strings`              | See outputs.tf |
| `primary_sql_connection_string`   | See outputs.tf |
| `secondary_sql_connection_string` | See outputs.tf |
| `database_ids`                    | See outputs.tf |
| `sql_container_ids`               | See outputs.tf |
| `mongodb_connection_string`       | See outputs.tf |
| `private_endpoint_id`             | See outputs.tf |
| `private_endpoint_ip_address`     | See outputs.tf |
| `identity_principal_id`           | See outputs.tf |
| `identity_tenant_id`              | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
