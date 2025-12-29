# GCP Compute Instance

Terraform module for provisioning GCP Compute Instance.

## Overview

This module creates and manages GCP Compute Instance with production-ready defaults and best practices.

## Usage

```hcl
module "compute_instance" {
  source = "path/to/modules/google/resources/compute/compute-instance"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `project_id` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `zone` | See variables.tf | `any` | See default |
| `instance_name` | See variables.tf | `any` | See default |
| `machine_type` | See variables.tf | `any` | See default |
| `boot_disk_image` | See variables.tf | `any` | See default |
| `boot_disk_size_gb` | See variables.tf | `any` | See default |
| `boot_disk_type` | See variables.tf | `any` | See default |
| `network` | See variables.tf | `any` | See default |
| `subnetwork` | See variables.tf | `any` | See default |
| `network_tags` | See variables.tf | `any` | See default |
| `external_ip` | See variables.tf | `any` | See default |
| `preemptible` | See variables.tf | `any` | See default |
| `spot` | See variables.tf | `any` | See default |
| `automatic_restart` | See variables.tf | `any` | See default |
| `on_host_maintenance` | See variables.tf | `any` | See default |
| `service_account_email` | See variables.tf | `any` | See default |
| `service_account_scopes` | See variables.tf | `any` | See default |
| `metadata` | See variables.tf | `any` | See default |
| `metadata_startup_script` | See variables.tf | `any` | See default |
| `enable_shielded_vm` | See variables.tf | `any` | See default |
| `enable_secure_boot` | See variables.tf | `any` | See default |
| `enable_vtpm` | See variables.tf | `any` | See default |
| `enable_integrity_monitoring` | See variables.tf | `any` | See default |
| `additional_disks` | See variables.tf | `any` | See default |
| `labels` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | See outputs.tf |
| `instance_name` | See outputs.tf |
| `self_link` | See outputs.tf |
| `internal_ip` | See outputs.tf |
| `external_ip` | See outputs.tf |
| `instance_zone` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
