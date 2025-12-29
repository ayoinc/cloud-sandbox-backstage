# AWS EC2 Instance

Terraform module for provisioning AWS EC2 Instance.

## Overview

This module creates and manages AWS EC2 Instance with production-ready defaults and best practices.

## Usage

```hcl
module "ec2" {
  source = "path/to/modules/aws/resources/compute/ec2"

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

| Name                     | Description      | Type  | Required    |
| ------------------------ | ---------------- | ----- | ----------- |
| `project_name`           | See variables.tf | `any` | See default |
| `environment`            | See variables.tf | `any` | See default |
| `instance_type`          | See variables.tf | `any` | See default |
| `ami_id`                 | See variables.tf | `any` | See default |
| `subnet_id`              | See variables.tf | `any` | See default |
| `vpc_security_group_ids` | See variables.tf | `any` | See default |
| `key_name`               | See variables.tf | `any` | See default |
| `iam_instance_profile`   | See variables.tf | `any` | See default |
| `user_data`              | See variables.tf | `any` | See default |
| `root_volume_size`       | See variables.tf | `any` | See default |
| `root_volume_type`       | See variables.tf | `any` | See default |
| `ebs_optimized`          | See variables.tf | `any` | See default |
| `enable_imdsv2`          | See variables.tf | `any` | See default |
| `tags`                   | See variables.tf | `any` | See default |

## Outputs

| Name           | Description    |
| -------------- | -------------- |
| `instance_id`  | See outputs.tf |
| `instance_arn` | See outputs.tf |
| `private_ip`   | See outputs.tf |
| `public_ip`    | See outputs.tf |
| `private_dns`  | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
