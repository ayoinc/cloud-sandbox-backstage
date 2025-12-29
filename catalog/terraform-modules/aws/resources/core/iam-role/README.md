# AWS IAM Role

Terraform module for provisioning AWS IAM Role.

## Overview

This module creates and manages AWS IAM Role with production-ready defaults and best practices.

## Usage

```hcl
module "iam_role" {
  source = "path/to/modules/aws/resources/core/iam-role"

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

## Outputs

| Name | Description |
|------|-------------|

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
