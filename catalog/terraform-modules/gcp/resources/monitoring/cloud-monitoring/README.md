# GCP Cloud Monitoring

Terraform module for provisioning GCP Cloud Monitoring.

## Overview

This module creates and manages GCP Cloud Monitoring with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_monitoring" {
  source = "path/to/modules/google/resources/monitoring/cloud-monitoring"

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

| Name                    | Description      | Type  | Required    |
| ----------------------- | ---------------- | ----- | ----------- |
| `project_name`          | See variables.tf | `any` | See default |
| `project_id`            | See variables.tf | `any` | See default |
| `environment`           | See variables.tf | `any` | See default |
| `notification_channels` | See variables.tf | `any` | See default |
| `alert_policies`        | See variables.tf | `any` | See default |
| `uptime_checks`         | See variables.tf | `any` | See default |
| `dashboards`            | See variables.tf | `any` | See default |
| `resource_groups`       | See variables.tf | `any` | See default |
| `custom_services`       | See variables.tf | `any` | See default |
| `slos`                  | See variables.tf | `any` | See default |

## Outputs

| Name                         | Description    |
| ---------------------------- | -------------- |
| `notification_channel_ids`   | See outputs.tf |
| `notification_channel_names` | See outputs.tf |
| `alert_policy_ids`           | See outputs.tf |
| `alert_policy_names`         | See outputs.tf |
| `uptime_check_ids`           | See outputs.tf |
| `uptime_check_names`         | See outputs.tf |
| `dashboard_ids`              | See outputs.tf |
| `group_ids`                  | See outputs.tf |
| `group_names`                | See outputs.tf |
| `custom_service_ids`         | See outputs.tf |
| `custom_service_names`       | See outputs.tf |
| `slo_ids`                    | See outputs.tf |
| `slo_names`                  | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
