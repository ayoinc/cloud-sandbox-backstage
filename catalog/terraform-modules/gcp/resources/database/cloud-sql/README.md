# GCP Cloud SQL

Terraform module for provisioning GCP Cloud SQL.

## Overview

This module creates and manages GCP Cloud SQL with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_sql" {
  source = "path/to/modules/google/resources/database/cloud-sql"

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
