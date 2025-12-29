# GCP Cloud Scheduler

Terraform module for provisioning GCP Cloud Scheduler.

## Overview

This module creates and manages GCP Cloud Scheduler with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_scheduler" {
  source = "path/to/modules/google/resources/messaging/cloud-scheduler"

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

| Name           | Description      | Type  | Required    |
| -------------- | ---------------- | ----- | ----------- |
| `project_name` | See variables.tf | `any` | See default |
| `project_id`   | See variables.tf | `any` | See default |
| `environment`  | See variables.tf | `any` | See default |
| `region`       | See variables.tf | `any` | See default |
| `jobs`         | See variables.tf | `any` | See default |

## Outputs

| Name        | Description    |
| ----------- | -------------- |
| `job_ids`   | See outputs.tf |
| `job_names` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
