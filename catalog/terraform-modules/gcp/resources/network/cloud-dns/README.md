# GCP Cloud DNS

Terraform module for provisioning GCP Cloud DNS.

## Overview

This module creates and manages GCP Cloud DNS with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_dns" {
  source = "path/to/modules/google/resources/network/cloud-dns"

  project_name = "my-project"
  environment  = "production"

  # Add required variables here
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| google    | >= 5.0  |

## Inputs

| Name                                    | Description      | Type  | Required    |
| --------------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                          | See variables.tf | `any` | See default |
| `project_id`                            | See variables.tf | `any` | See default |
| `environment`                           | See variables.tf | `any` | See default |
| `zone_name`                             | See variables.tf | `any` | See default |
| `dns_name`                              | See variables.tf | `any` | See default |
| `description`                           | See variables.tf | `any` | See default |
| `visibility`                            | See variables.tf | `any` | See default |
| `private_visibility_config_networks`    | See variables.tf | `any` | See default |
| `dnssec_state`                          | See variables.tf | `any` | See default |
| `forwarding_config_target_name_servers` | See variables.tf | `any` | See default |
| `peering_config_target_network`         | See variables.tf | `any` | See default |
| `records`                               | See variables.tf | `any` | See default |
| `dns_policies`                          | See variables.tf | `any` | See default |
| `labels`                                | See variables.tf | `any` | See default |

## Outputs

| Name             | Description    |
| ---------------- | -------------- |
| `zone_id`        | See outputs.tf |
| `zone_name`      | See outputs.tf |
| `name_servers`   | See outputs.tf |
| `dns_policy_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
