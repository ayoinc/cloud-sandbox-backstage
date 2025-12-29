# GCP Cloud Armor

Terraform module for provisioning GCP Cloud Armor.

## Overview

This module creates and manages GCP Cloud Armor with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_armor" {
  source = "path/to/modules/google/resources/security/cloud-armor"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `project_id` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `name` | See variables.tf | `any` | See default |
| `description` | See variables.tf | `any` | See default |
| `type` | See variables.tf | `any` | See default |
| `adaptive_protection_config` | See variables.tf | `any` | See default |
| `rules` | See variables.tf | `any` | See default |
| `default_rule_action` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `security_policy_id` | See outputs.tf |
| `security_policy_self_link` | See outputs.tf |
| `security_policy_fingerprint` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
