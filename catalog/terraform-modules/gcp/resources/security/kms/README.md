# GCP Key Management Service

Terraform module for provisioning GCP Key Management Service.

## Overview

This module creates and manages GCP Key Management Service with production-ready defaults and best practices.

## Usage

```hcl
module "kms" {
  source = "path/to/modules/google/resources/security/kms"

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

| Name               | Description      | Type  | Required    |
| ------------------ | ---------------- | ----- | ----------- |
| `project_name`     | See variables.tf | `any` | See default |
| `project_id`       | See variables.tf | `any` | See default |
| `environment`      | See variables.tf | `any` | See default |
| `location`         | See variables.tf | `any` | See default |
| `key_ring_name`    | See variables.tf | `any` | See default |
| `crypto_keys`      | See variables.tf | `any` | See default |
| `key_iam_bindings` | See variables.tf | `any` | See default |
| `labels`           | See variables.tf | `any` | See default |

## Outputs

| Name               | Description    |
| ------------------ | -------------- |
| `key_ring_id`      | See outputs.tf |
| `key_ring_name`    | See outputs.tf |
| `crypto_key_ids`   | See outputs.tf |
| `crypto_key_names` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
