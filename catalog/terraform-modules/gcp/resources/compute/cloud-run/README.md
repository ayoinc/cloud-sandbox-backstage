# GCP Cloud Run

Terraform module for provisioning GCP Cloud Run.

## Overview

This module creates and manages GCP Cloud Run with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_run" {
  source = "path/to/modules/google/resources/compute/cloud-run"

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
| `service_name` | See variables.tf | `any` | See default |
| `description` | See variables.tf | `any` | See default |
| `image` | See variables.tf | `any` | See default |
| `cpu` | See variables.tf | `any` | See default |
| `memory` | See variables.tf | `any` | See default |
| `port` | See variables.tf | `any` | See default |
| `min_instance_count` | See variables.tf | `any` | See default |
| `max_instance_count` | See variables.tf | `any` | See default |
| `timeout_seconds` | See variables.tf | `any` | See default |
| `service_account_email` | See variables.tf | `any` | See default |
| `env_vars` | See variables.tf | `any` | See default |
| `secrets` | See variables.tf | `any` | See default |
| `volumes` | See variables.tf | `any` | See default |
| `vpc_access_connector` | See variables.tf | `any` | See default |
| `vpc_access_egress` | See variables.tf | `any` | See default |
| `ingress` | See variables.tf | `any` | See default |
| `allow_unauthenticated` | See variables.tf | `any` | See default |
| `traffic_allocations` | See variables.tf | `any` | See default |
| `labels` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `service_id` | See outputs.tf |
| `service_name` | See outputs.tf |
| `service_uri` | See outputs.tf |
| `latest_ready_revision` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
