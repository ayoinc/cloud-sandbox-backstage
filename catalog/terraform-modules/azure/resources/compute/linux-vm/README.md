# Azure Linux Virtual Machine

Terraform module for provisioning Azure Linux Virtual Machine.

## Overview

This module creates and manages Azure Linux Virtual Machine with production-ready defaults and best practices.

## Usage

```hcl
module "linux_vm" {
  source = "path/to/modules/azurerm/resources/compute/linux-vm"

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
