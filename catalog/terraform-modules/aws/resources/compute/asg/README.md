# AWS Auto Scaling Group

Terraform module for provisioning AWS Auto Scaling Group.

## Overview

This module creates and manages AWS Auto Scaling Group with production-ready defaults and best practices.

## Usage

```hcl
module "asg" {
  source = "path/to/modules/aws/resources/compute/asg"

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

| Name                        | Description      | Type  | Required    |
| --------------------------- | ---------------- | ----- | ----------- |
| `project_name`              | See variables.tf | `any` | See default |
| `environment`               | See variables.tf | `any` | See default |
| `ami_id`                    | See variables.tf | `any` | See default |
| `instance_type`             | See variables.tf | `any` | See default |
| `min_size`                  | See variables.tf | `any` | See default |
| `max_size`                  | See variables.tf | `any` | See default |
| `desired_capacity`          | See variables.tf | `any` | See default |
| `vpc_zone_identifier`       | See variables.tf | `any` | See default |
| `security_group_ids`        | See variables.tf | `any` | See default |
| `key_name`                  | See variables.tf | `any` | See default |
| `iam_instance_profile_arn`  | See variables.tf | `any` | See default |
| `user_data_base64`          | See variables.tf | `any` | See default |
| `health_check_type`         | See variables.tf | `any` | See default |
| `health_check_grace_period` | See variables.tf | `any` | See default |
| `target_group_arns`         | See variables.tf | `any` | See default |
| `enable_spot_instances`     | See variables.tf | `any` | See default |
| `spot_allocation_strategy`  | See variables.tf | `any` | See default |
| `on_demand_percentage`      | See variables.tf | `any` | See default |
| `tags`                      | See variables.tf | `any` | See default |

## Outputs

| Name                     | Description    |
| ------------------------ | -------------- |
| `launch_template_id`     | See outputs.tf |
| `launch_template_arn`    | See outputs.tf |
| `autoscaling_group_id`   | See outputs.tf |
| `autoscaling_group_arn`  | See outputs.tf |
| `autoscaling_group_name` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
