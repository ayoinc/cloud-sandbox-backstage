# Azure Resource Group

Terraform module for provisioning Azure Resource Group.

## Overview

This module creates and manages Azure Resource Group with production-ready defaults and best practices.

## Usage

```hcl
module "resource_group" {
  source = "path/to/modules/azurerm/resources/core/resource-group"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| azurerm   | >= 5.0  |

## Inputs

| Name | Description | Type | Required |
| ---- | ----------- | ---- | -------- |

## Outputs

| Name | Description |
| ---- | ----------- |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
