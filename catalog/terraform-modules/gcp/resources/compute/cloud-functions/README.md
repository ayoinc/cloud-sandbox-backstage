# GCP Cloud Functions

Terraform module for provisioning GCP Cloud Functions.

## Overview

This module creates and manages GCP Cloud Functions with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_functions" {
  source = "path/to/modules/google/resources/compute/cloud-functions"

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

| Name                            | Description      | Type  | Required    |
| ------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                  | See variables.tf | `any` | See default |
| `project_id`                    | See variables.tf | `any` | See default |
| `environment`                   | See variables.tf | `any` | See default |
| `region`                        | See variables.tf | `any` | See default |
| `function_name`                 | See variables.tf | `any` | See default |
| `description`                   | See variables.tf | `any` | See default |
| `runtime`                       | See variables.tf | `any` | See default |
| `entry_point`                   | See variables.tf | `any` | See default |
| `source_bucket`                 | See variables.tf | `any` | See default |
| `source_archive_object`         | See variables.tf | `any` | See default |
| `source_dir`                    | See variables.tf | `any` | See default |
| `available_memory`              | See variables.tf | `any` | See default |
| `available_cpu`                 | See variables.tf | `any` | See default |
| `timeout_seconds`               | See variables.tf | `any` | See default |
| `max_instance_count`            | See variables.tf | `any` | See default |
| `min_instance_count`            | See variables.tf | `any` | See default |
| `service_account_email`         | See variables.tf | `any` | See default |
| `environment_variables`         | See variables.tf | `any` | See default |
| `secret_environment_variables`  | See variables.tf | `any` | See default |
| `vpc_connector`                 | See variables.tf | `any` | See default |
| `vpc_connector_egress_settings` | See variables.tf | `any` | See default |
| `ingress_settings`              | See variables.tf | `any` | See default |
| `trigger_type`                  | See variables.tf | `any` | See default |
| `pubsub_topic`                  | See variables.tf | `any` | See default |
| `storage_bucket_trigger`        | See variables.tf | `any` | See default |
| `event_type`                    | See variables.tf | `any` | See default |
| `allow_unauthenticated`         | See variables.tf | `any` | See default |
| `labels`                        | See variables.tf | `any` | See default |

## Outputs

| Name                    | Description    |
| ----------------------- | -------------- |
| `function_id`           | See outputs.tf |
| `function_name`         | See outputs.tf |
| `function_uri`          | See outputs.tf |
| `service_account_email` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
