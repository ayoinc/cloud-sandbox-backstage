# GCP Cloud Storage

Terraform module for provisioning GCP Cloud Storage.

## Overview

This module creates and manages GCP Cloud Storage with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_storage" {
  source = "path/to/modules/google/resources/storage/cloud-storage"

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
