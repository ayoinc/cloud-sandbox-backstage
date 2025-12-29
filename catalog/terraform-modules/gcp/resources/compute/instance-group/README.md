# GCP Instance Group

Terraform module for provisioning GCP Instance Group.

## Overview

This module creates and manages GCP Instance Group with production-ready defaults and best practices.

## Usage

```hcl
module "instance_group" {
  source = "path/to/modules/google/resources/compute/instance-group"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| google    | >= 5.0  |

## Inputs

| Name                        | Description      | Type  | Required    |
| --------------------------- | ---------------- | ----- | ----------- |
| `project_name`              | See variables.tf | `any` | See default |
| `project_id`                | See variables.tf | `any` | See default |
| `environment`               | See variables.tf | `any` | See default |
| `region`                    | See variables.tf | `any` | See default |
| `name`                      | See variables.tf | `any` | See default |
| `machine_type`              | See variables.tf | `any` | See default |
| `source_image`              | See variables.tf | `any` | See default |
| `disk_size_gb`              | See variables.tf | `any` | See default |
| `disk_type`                 | See variables.tf | `any` | See default |
| `network`                   | See variables.tf | `any` | See default |
| `subnetwork`                | See variables.tf | `any` | See default |
| `network_tags`              | See variables.tf | `any` | See default |
| `service_account_email`     | See variables.tf | `any` | See default |
| `service_account_scopes`    | See variables.tf | `any` | See default |
| `metadata`                  | See variables.tf | `any` | See default |
| `startup_script`            | See variables.tf | `any` | See default |
| `target_size`               | See variables.tf | `any` | See default |
| `base_instance_name`        | See variables.tf | `any` | See default |
| `distribution_policy_zones` | See variables.tf | `any` | See default |
| `named_ports`               | See variables.tf | `any` | See default |
| `auto_healing_health_check` | See variables.tf | `any` | See default |
| `initial_delay_sec`         | See variables.tf | `any` | See default |
| `enable_autoscaling`        | See variables.tf | `any` | See default |
| `min_replicas`              | See variables.tf | `any` | See default |
| `max_replicas`              | See variables.tf | `any` | See default |
| `cpu_target`                | See variables.tf | `any` | See default |
| `cooldown_period`           | See variables.tf | `any` | See default |
| `update_type`               | See variables.tf | `any` | See default |
| `max_surge_fixed`           | See variables.tf | `any` | See default |
| `max_unavailable_fixed`     | See variables.tf | `any` | See default |
| `labels`                    | See variables.tf | `any` | See default |

## Outputs

| Name                               | Description    |
| ---------------------------------- | -------------- |
| `instance_template_id`             | See outputs.tf |
| `instance_template_self_link`      | See outputs.tf |
| `instance_group_manager_id`        | See outputs.tf |
| `instance_group_manager_self_link` | See outputs.tf |
| `instance_group`                   | See outputs.tf |
| `autoscaler_id`                    | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
