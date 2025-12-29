# Azure Application Gateway

Terraform module for provisioning Azure Application Gateway.

## Overview

This module creates and manages Azure Application Gateway with production-ready defaults and best practices.

## Usage

```hcl
module "application_gateway" {
  source = "path/to/modules/azurerm/resources/network/application-gateway"

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

| Name                      | Description      | Type  | Required    |
| ------------------------- | ---------------- | ----- | ----------- |
| `project_name`            | See variables.tf | `any` | See default |
| `environment`             | See variables.tf | `any` | See default |
| `resource_group_name`     | See variables.tf | `any` | See default |
| `location`                | See variables.tf | `any` | See default |
| `name`                    | See variables.tf | `any` | See default |
| `sku_name`                | See variables.tf | `any` | See default |
| `sku_tier`                | See variables.tf | `any` | See default |
| `capacity`                | See variables.tf | `any` | See default |
| `enable_autoscaling`      | See variables.tf | `any` | See default |
| `min_capacity`            | See variables.tf | `any` | See default |
| `max_capacity`            | See variables.tf | `any` | See default |
| `subnet_id`               | See variables.tf | `any` | See default |
| `public_ip_address_id`    | See variables.tf | `any` | See default |
| `frontend_ports`          | See variables.tf | `any` | See default |
| `backend_address_pools`   | See variables.tf | `any` | See default |
| `backend_http_settings`   | See variables.tf | `any` | See default |
| `http_listeners`          | See variables.tf | `any` | See default |
| `request_routing_rules`   | See variables.tf | `any` | See default |
| `probes`                  | See variables.tf | `any` | See default |
| `ssl_certificates`        | See variables.tf | `any` | See default |
| `enable_waf`              | See variables.tf | `any` | See default |
| `waf_mode`                | See variables.tf | `any` | See default |
| `waf_rule_set_type`       | See variables.tf | `any` | See default |
| `waf_rule_set_version`    | See variables.tf | `any` | See default |
| `url_path_maps`           | See variables.tf | `any` | See default |
| `redirect_configurations` | See variables.tf | `any` | See default |
| `tags`                    | See variables.tf | `any` | See default |

## Outputs

| Name                           | Description    |
| ------------------------------ | -------------- |
| `application_gateway_id`       | See outputs.tf |
| `application_gateway_name`     | See outputs.tf |
| `backend_address_pool_ids`     | See outputs.tf |
| `frontend_ip_configuration_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
