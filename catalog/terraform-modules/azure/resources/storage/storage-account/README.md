# Azure Storage Account

Terraform module for provisioning Azure Storage Account.

## Overview

This module creates and manages Azure Storage Account with production-ready defaults and best practices.

## Usage

```hcl
module "storage_account" {
  source = "path/to/modules/azurerm/resources/storage/storage-account"

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
