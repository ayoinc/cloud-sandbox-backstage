# AWS Elastic Container Registry

Terraform module for provisioning AWS Elastic Container Registry.

## Overview

This module creates and manages AWS Elastic Container Registry with production-ready defaults and best practices.

## Usage

```hcl
module "ecr" {
  source = "path/to/modules/aws/resources/containers/ecr"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

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
