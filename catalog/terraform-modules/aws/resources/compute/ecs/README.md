# AWS Elastic Container Service

Terraform module for provisioning AWS Elastic Container Service.

## Overview

This module creates and manages AWS Elastic Container Service with production-ready defaults and best practices.

## Usage

```hcl
module "ecs" {
  source = "path/to/modules/aws/resources/compute/ecs"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Inputs

| Name                                 | Description      | Type  | Required    |
| ------------------------------------ | ---------------- | ----- | ----------- |
| `project_name`                       | See variables.tf | `any` | See default |
| `environment`                        | See variables.tf | `any` | See default |
| `tags`                               | See variables.tf | `any` | See default |
| `cluster_name`                       | See variables.tf | `any` | See default |
| `enable_container_insights`          | See variables.tf | `any` | See default |
| `capacity_providers`                 | See variables.tf | `any` | See default |
| `task_family`                        | See variables.tf | `any` | See default |
| `cpu`                                | See variables.tf | `any` | See default |
| `memory`                             | See variables.tf | `any` | See default |
| `network_mode`                       | See variables.tf | `any` | See default |
| `requires_compatibilities`           | See variables.tf | `any` | See default |
| `execution_role_arn`                 | See variables.tf | `any` | See default |
| `task_role_arn`                      | See variables.tf | `any` | See default |
| `container_definitions`              | See variables.tf | `any` | See default |
| `service_name`                       | See variables.tf | `any` | See default |
| `desired_count`                      | See variables.tf | `any` | See default |
| `subnets`                            | See variables.tf | `any` | See default |
| `security_groups`                    | See variables.tf | `any` | See default |
| `assign_public_ip`                   | See variables.tf | `any` | See default |
| `target_group_arn`                   | See variables.tf | `any` | See default |
| `container_name`                     | See variables.tf | `any` | See default |
| `container_port`                     | See variables.tf | `any` | See default |
| `health_check_grace_period_seconds`  | See variables.tf | `any` | See default |
| `deployment_minimum_healthy_percent` | See variables.tf | `any` | See default |
| `deployment_maximum_percent`         | See variables.tf | `any` | See default |
| `enable_execute_command`             | See variables.tf | `any` | See default |
| `enable_service_discovery`           | See variables.tf | `any` | See default |
| `service_discovery_vpc_id`           | See variables.tf | `any` | See default |

## Outputs

| Name                              | Description    |
| --------------------------------- | -------------- |
| `cluster_id`                      | See outputs.tf |
| `cluster_arn`                     | See outputs.tf |
| `cluster_name`                    | See outputs.tf |
| `task_definition_arn`             | See outputs.tf |
| `task_definition_family`          | See outputs.tf |
| `task_definition_revision`        | See outputs.tf |
| `service_id`                      | See outputs.tf |
| `service_name`                    | See outputs.tf |
| `service_arn`                     | See outputs.tf |
| `cloudwatch_log_group_name`       | See outputs.tf |
| `cloudwatch_log_group_arn`        | See outputs.tf |
| `service_discovery_namespace_id`  | See outputs.tf |
| `service_discovery_namespace_arn` | See outputs.tf |
| `service_discovery_service_arn`   | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
