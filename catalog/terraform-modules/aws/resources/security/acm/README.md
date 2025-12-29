# AWS Certificate Manager

Terraform module for provisioning AWS Certificate Manager.

## Overview

This module creates and manages AWS Certificate Manager with production-ready defaults and best practices.

## Usage

```hcl
module "acm" {
  source = "path/to/modules/aws/resources/security/acm"

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
| `domain_name`               | See variables.tf | `any` | See default |
| `subject_alternative_names` | See variables.tf | `any` | See default |
| `validation_method`         | See variables.tf | `any` | See default |
| `create_route53_records`    | See variables.tf | `any` | See default |
| `route53_zone_id`           | See variables.tf | `any` | See default |
| `wait_for_validation`       | See variables.tf | `any` | See default |
| `tags`                      | See variables.tf | `any` | See default |

## Outputs

| Name                        | Description    |
| --------------------------- | -------------- |
| `certificate_arn`           | See outputs.tf |
| `certificate_domain_name`   | See outputs.tf |
| `certificate_status`        | See outputs.tf |
| `domain_validation_options` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
