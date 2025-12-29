# Azure Windows Virtual Machine

Terraform module for provisioning Azure Windows Virtual Machine.

## Overview

This module creates and manages Azure Windows Virtual Machine with production-ready defaults and best practices.

## Usage

```hcl
module "windows_vm" {
  source = "path/to/modules/azurerm/resources/compute/windows-vm"

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

| Name                            | Description      | Type  | Required    |
| ------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                  | See variables.tf | `any` | See default |
| `environment`                   | See variables.tf | `any` | See default |
| `resource_group_name`           | See variables.tf | `any` | See default |
| `location`                      | See variables.tf | `any` | See default |
| `vm_name`                       | See variables.tf | `any` | See default |
| `size`                          | See variables.tf | `any` | See default |
| `admin_username`                | See variables.tf | `any` | See default |
| `admin_password`                | See variables.tf | `any` | See default |
| `source_image_reference`        | See variables.tf | `any` | See default |
| `custom_image_id`               | See variables.tf | `any` | See default |
| `os_disk_storage_type`          | See variables.tf | `any` | See default |
| `os_disk_size_gb`               | See variables.tf | `any` | See default |
| `os_disk_caching`               | See variables.tf | `any` | See default |
| `subnet_id`                     | See variables.tf | `any` | See default |
| `private_ip_address_allocation` | See variables.tf | `any` | See default |
| `private_ip_address`            | See variables.tf | `any` | See default |
| `public_ip_address_id`          | See variables.tf | `any` | See default |
| `enable_accelerated_networking` | See variables.tf | `any` | See default |
| `zone`                          | See variables.tf | `any` | See default |
| `enable_boot_diagnostics`       | See variables.tf | `any` | See default |
| `boot_diagnostics_storage_uri`  | See variables.tf | `any` | See default |
| `enable_system_identity`        | See variables.tf | `any` | See default |
| `enable_antimalware`            | See variables.tf | `any` | See default |
| `data_disks`                    | See variables.tf | `any` | See default |
| `tags`                          | See variables.tf | `any` | See default |

## Outputs

| Name                    | Description    |
| ----------------------- | -------------- |
| `vm_id`                 | See outputs.tf |
| `vm_name`               | See outputs.tf |
| `private_ip_address`    | See outputs.tf |
| `public_ip_address`     | See outputs.tf |
| `identity_principal_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
