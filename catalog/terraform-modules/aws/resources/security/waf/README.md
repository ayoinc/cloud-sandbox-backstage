# AWS Web Application Firewall

Terraform module for provisioning AWS Web Application Firewall.

## Overview

This module creates and manages AWS Web Application Firewall with production-ready defaults and best practices.

## Usage

```hcl
module "waf" {
  source = "path/to/modules/aws/resources/security/waf"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `name` | See variables.tf | `any` | See default |
| `scope` | See variables.tf | `any` | See default |
| `default_action` | See variables.tf | `any` | See default |
| `managed_rule_groups` | See variables.tf | `any` | See default |
| `rate_limit_rules` | See variables.tf | `any` | See default |
| `ip_set_rules` | See variables.tf | `any` | See default |
| `custom_rules` | See variables.tf | `any` | See default |
| `enable_logging` | See variables.tf | `any` | See default |
| `log_destination_arns` | See variables.tf | `any` | See default |
| `logging_filter` | See variables.tf | `any` | See default |
| `redacted_fields` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_id` | See outputs.tf |
| `web_acl_arn` | See outputs.tf |
| `web_acl_capacity` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
