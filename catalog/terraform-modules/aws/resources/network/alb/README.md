# AWS Application Load Balancer

Terraform module for provisioning AWS Application Load Balancer.

## Overview

This module creates and manages AWS Application Load Balancer with production-ready defaults and best practices.

## Usage

```hcl
module "alb" {
  source = "path/to/modules/aws/resources/network/alb"

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

| Name                         | Description      | Type  | Required    |
| ---------------------------- | ---------------- | ----- | ----------- |
| `project_name`               | See variables.tf | `any` | See default |
| `environment`                | See variables.tf | `any` | See default |
| `internal`                   | See variables.tf | `any` | See default |
| `subnets`                    | See variables.tf | `any` | See default |
| `security_groups`            | See variables.tf | `any` | See default |
| `enable_deletion_protection` | See variables.tf | `any` | See default |
| `idle_timeout`               | See variables.tf | `any` | See default |
| `enable_access_logs`         | See variables.tf | `any` | See default |
| `access_logs_bucket`         | See variables.tf | `any` | See default |
| `access_logs_prefix`         | See variables.tf | `any` | See default |
| `certificate_arn`            | See variables.tf | `any` | See default |
| `ssl_policy`                 | See variables.tf | `any` | See default |
| `target_group_port`          | See variables.tf | `any` | See default |
| `target_group_protocol`      | See variables.tf | `any` | See default |
| `target_type`                | See variables.tf | `any` | See default |
| `health_check_path`          | See variables.tf | `any` | See default |
| `health_check_interval`      | See variables.tf | `any` | See default |
| `health_check_timeout`       | See variables.tf | `any` | See default |
| `healthy_threshold`          | See variables.tf | `any` | See default |
| `unhealthy_threshold`        | See variables.tf | `any` | See default |
| `deregistration_delay`       | See variables.tf | `any` | See default |
| `vpc_id`                     | See variables.tf | `any` | See default |
| `tags`                       | See variables.tf | `any` | See default |

## Outputs

| Name                 | Description    |
| -------------------- | -------------- |
| `lb_id`              | See outputs.tf |
| `lb_arn`             | See outputs.tf |
| `lb_dns_name`        | See outputs.tf |
| `lb_zone_id`         | See outputs.tf |
| `http_listener_arn`  | See outputs.tf |
| `https_listener_arn` | See outputs.tf |
| `target_group_arn`   | See outputs.tf |
| `target_group_name`  | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
