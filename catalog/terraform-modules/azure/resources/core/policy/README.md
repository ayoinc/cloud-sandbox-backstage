# Azure Azure Policy

Terraform module for provisioning Azure Azure Policy.

## Overview

This module creates and manages Azure Azure Policy with production-ready defaults and best practices.

## Usage

```hcl
module "policy" {
  source = "path/to/modules/azurerm/resources/core/policy"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `custom_policies` | See variables.tf | `any` | See default |
| `policy_set_definitions` | See variables.tf | `any` | See default |
| `policy_assignments` | See variables.tf | `any` | See default |
| `enable_remediation` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `policy_definition_ids` | See outputs.tf |
| `policy_definitions` | See outputs.tf |
| `policy_set_definition_ids` | See outputs.tf |
| `policy_set_definitions` | See outputs.tf |
| `policy_assignment_ids` | See outputs.tf |
| `policy_assignments` | See outputs.tf |
| `remediation_ids` | See outputs.tf |
| `remediations` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
