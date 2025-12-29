# Azure Container Registry

Terraform module for provisioning Azure Container Registry.

## Overview

This module creates and manages Azure Container Registry with production-ready defaults and best practices.

## Usage

```hcl
module "container_registry" {
  source = "path/to/modules/azurerm/resources/containers/container-registry"

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
