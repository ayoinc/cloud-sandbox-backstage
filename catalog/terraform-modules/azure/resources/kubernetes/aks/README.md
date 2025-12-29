# Azure Kubernetes Service (AKS)

Terraform module for provisioning Azure Kubernetes Service (AKS).

## Overview

This module creates and manages Azure Kubernetes Service (AKS) with production-ready defaults and best practices.

## Usage

```hcl
module "aks" {
  source = "path/to/modules/azurerm/resources/kubernetes/aks"

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
