# AWS Organizations

Terraform module for provisioning AWS Organizations.

## Overview

This module creates and manages AWS Organizations with production-ready defaults and best practices.

## Usage

```hcl
module "organizations" {
  source = "path/to/modules/aws/resources/core/organizations"

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

| Name                            | Description      | Type  | Required    |
| ------------------------------- | ---------------- | ----- | ----------- |
| `feature_set`                   | See variables.tf | `any` | See default |
| `enabled_policy_types`          | See variables.tf | `any` | See default |
| `aws_service_access_principals` | See variables.tf | `any` | See default |
| `organizational_units`          | See variables.tf | `any` | See default |
| `accounts`                      | See variables.tf | `any` | See default |
| `service_control_policies`      | See variables.tf | `any` | See default |
| `tags`                          | See variables.tf | `any` | See default |

## Outputs

| Name                             | Description    |
| -------------------------------- | -------------- |
| `organization_id`                | See outputs.tf |
| `organization_arn`               | See outputs.tf |
| `organization_master_account_id` | See outputs.tf |
| `roots`                          | See outputs.tf |
| `organizational_unit_ids`        | See outputs.tf |
| `account_ids`                    | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
