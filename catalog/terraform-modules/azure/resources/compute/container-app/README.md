# Azure Container App

Terraform module for provisioning Azure Container App.

## Overview

This module creates and manages Azure Container App with production-ready defaults and best practices.

## Usage

```hcl
module "container_app" {
  source = "path/to/modules/azurerm/resources/compute/container-app"

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
| `container_app_environment_name` | See variables.tf | `any` | See default |
| `log_analytics_workspace_id` | See variables.tf | `any` | See default |
| `container_app_name` | See variables.tf | `any` | See default |
| `revision_mode` | See variables.tf | `any` | See default |
| `container_name` | See variables.tf | `any` | See default |
| `image` | See variables.tf | `any` | See default |
| `cpu` | See variables.tf | `any` | See default |
| `memory` | See variables.tf | `any` | See default |
| `min_replicas` | See variables.tf | `any` | See default |
| `max_replicas` | See variables.tf | `any` | See default |
| `target_port` | See variables.tf | `any` | See default |
| `external_enabled` | See variables.tf | `any` | See default |
| `ingress_transport` | See variables.tf | `any` | See default |
| `env_vars` | See variables.tf | `any` | See default |
| `secrets` | See variables.tf | `any` | See default |
| `enable_dapr` | See variables.tf | `any` | See default |
| `dapr_app_id` | See variables.tf | `any` | See default |
| `dapr_app_port` | See variables.tf | `any` | See default |
| `custom_domains` | See variables.tf | `any` | See default |
| `custom_scale_rules` | See variables.tf | `any` | See default |
| `http_scale_rules` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `environment_id` | See outputs.tf |
| `container_app_id` | See outputs.tf |
| `container_app_fqdn` | See outputs.tf |
| `latest_revision_name` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
