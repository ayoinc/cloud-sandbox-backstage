# Azure VM Scale Set

Terraform module for provisioning Azure VM Scale Set.

## Overview

This module creates and manages Azure VM Scale Set with production-ready defaults and best practices.

## Usage

```hcl
module "vmss" {
  source = "path/to/modules/azurerm/resources/compute/vmss"

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

| Name                               | Description      | Type  | Required    |
| ---------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                     | See variables.tf | `any` | See default |
| `environment`                      | See variables.tf | `any` | See default |
| `resource_group_name`              | See variables.tf | `any` | See default |
| `location`                         | See variables.tf | `any` | See default |
| `vmss_name`                        | See variables.tf | `any` | See default |
| `sku`                              | See variables.tf | `any` | See default |
| `instances`                        | See variables.tf | `any` | See default |
| `admin_username`                   | See variables.tf | `any` | See default |
| `admin_ssh_public_key`             | See variables.tf | `any` | See default |
| `subnet_id`                        | See variables.tf | `any` | See default |
| `source_image_reference`           | See variables.tf | `any` | See default |
| `os_disk_storage_type`             | See variables.tf | `any` | See default |
| `os_disk_size_gb`                  | See variables.tf | `any` | See default |
| `data_disks`                       | See variables.tf | `any` | See default |
| `enable_autoscale`                 | See variables.tf | `any` | See default |
| `min_instances`                    | See variables.tf | `any` | See default |
| `max_instances`                    | See variables.tf | `any` | See default |
| `scale_out_cpu_threshold`          | See variables.tf | `any` | See default |
| `scale_in_cpu_threshold`           | See variables.tf | `any` | See default |
| `health_probe_id`                  | See variables.tf | `any` | See default |
| `enable_automatic_instance_repair` | See variables.tf | `any` | See default |
| `enable_system_identity`           | See variables.tf | `any` | See default |
| `custom_data`                      | See variables.tf | `any` | See default |
| `tags`                             | See variables.tf | `any` | See default |

## Outputs

| Name                    | Description    |
| ----------------------- | -------------- |
| `vmss_id`               | See outputs.tf |
| `vmss_name`             | See outputs.tf |
| `unique_id`             | See outputs.tf |
| `identity_principal_id` | See outputs.tf |
| `autoscale_setting_id`  | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
