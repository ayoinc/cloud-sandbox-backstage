# Azure Service Bus

Terraform module for provisioning Azure Service Bus.

## Overview

This module creates and manages Azure Service Bus with production-ready defaults and best practices.

## Usage

```hcl
module "service_bus" {
  source = "path/to/modules/azurerm/resources/messaging/service-bus"

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
