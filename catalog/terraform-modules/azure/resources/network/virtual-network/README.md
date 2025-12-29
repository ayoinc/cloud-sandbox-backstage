# Azure Virtual Network

Terraform module for provisioning Azure Virtual Network.

## Overview

This module creates and manages Azure Virtual Network with production-ready defaults and best practices.

## Usage

```hcl
module "virtual_network" {
  source = "path/to/modules/azurerm/resources/network/virtual-network"

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
