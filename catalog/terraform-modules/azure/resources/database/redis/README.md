# Azure Redis Cache

Terraform module for provisioning Azure Redis Cache.

## Overview

This module creates and manages Azure Redis Cache with production-ready defaults and best practices.

## Usage

```hcl
module "redis" {
  source = "path/to/modules/azurerm/resources/database/redis"

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

| Name                         | Description      | Type  | Required    |
| ---------------------------- | ---------------- | ----- | ----------- |
| `project_name`               | See variables.tf | `any` | See default |
| `environment`                | See variables.tf | `any` | See default |
| `resource_group_name`        | See variables.tf | `any` | See default |
| `location`                   | See variables.tf | `any` | See default |
| `redis_name`                 | See variables.tf | `any` | See default |
| `capacity`                   | See variables.tf | `any` | See default |
| `family`                     | See variables.tf | `any` | See default |
| `sku_name`                   | See variables.tf | `any` | See default |
| `enable_non_ssl_port`        | See variables.tf | `any` | See default |
| `minimum_tls_version`        | See variables.tf | `any` | See default |
| `shard_count`                | See variables.tf | `any` | See default |
| `replicas_per_master`        | See variables.tf | `any` | See default |
| `redis_configuration`        | See variables.tf | `any` | See default |
| `zones`                      | See variables.tf | `any` | See default |
| `private_static_ip_address`  | See variables.tf | `any` | See default |
| `subnet_id`                  | See variables.tf | `any` | See default |
| `private_endpoint_subnet_id` | See variables.tf | `any` | See default |
| `private_dns_zone_id`        | See variables.tf | `any` | See default |
| `firewall_rules`             | See variables.tf | `any` | See default |
| `tags`                       | See variables.tf | `any` | See default |

## Outputs

| Name                        | Description    |
| --------------------------- | -------------- |
| `redis_id`                  | See outputs.tf |
| `redis_name`                | See outputs.tf |
| `hostname`                  | See outputs.tf |
| `ssl_port`                  | See outputs.tf |
| `primary_access_key`        | See outputs.tf |
| `primary_connection_string` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
