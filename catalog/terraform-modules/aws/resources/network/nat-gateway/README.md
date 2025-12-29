# AWS NAT Gateway

Terraform module for provisioning AWS NAT Gateway.

## Overview

This module creates and manages AWS NAT Gateway with production-ready defaults and best practices.

## Usage

```hcl
module "nat_gateway" {
  source = "path/to/modules/aws/resources/network/nat-gateway"

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
| `project_name` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `subnet_ids` | See variables.tf | `any` | See default |
| `connectivity_type` | See variables.tf | `any` | See default |
| `create_eip` | See variables.tf | `any` | See default |
| `allocation_ids` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `nat_gateway_ids` | See outputs.tf |
| `nat_gateway_public_ips` | See outputs.tf |
| `eip_ids` | See outputs.tf |
| `eip_public_ips` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
