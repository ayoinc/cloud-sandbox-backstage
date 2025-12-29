# GCP Cloud Router

Terraform module for provisioning GCP Cloud Router.

## Overview

This module creates and manages GCP Cloud Router with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_router" {
  source = "path/to/modules/google/resources/network/cloud-router"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | See variables.tf | `any` | See default |
| `project_id` | See variables.tf | `any` | See default |
| `environment` | See variables.tf | `any` | See default |
| `region` | See variables.tf | `any` | See default |
| `name` | See variables.tf | `any` | See default |
| `network` | See variables.tf | `any` | See default |
| `description` | See variables.tf | `any` | See default |
| `bgp_asn` | See variables.tf | `any` | See default |
| `bgp_advertise_mode` | See variables.tf | `any` | See default |
| `bgp_advertised_groups` | See variables.tf | `any` | See default |
| `bgp_advertised_ip_ranges` | See variables.tf | `any` | See default |
| `bgp_keepalive_interval` | See variables.tf | `any` | See default |
| `router_interfaces` | See variables.tf | `any` | See default |
| `router_peers` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `router_id` | See outputs.tf |
| `router_self_link` | See outputs.tf |
| `router_creation_timestamp` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
