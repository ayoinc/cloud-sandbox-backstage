# GCP Cloud Logging

Terraform module for provisioning GCP Cloud Logging.

## Overview

This module creates and manages GCP Cloud Logging with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_logging" {
  source = "path/to/modules/google/resources/monitoring/cloud-logging"

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

| Name             | Description      | Type  | Required    |
| ---------------- | ---------------- | ----- | ----------- |
| `project_name`   | See variables.tf | `any` | See default |
| `project_id`     | See variables.tf | `any` | See default |
| `environment`    | See variables.tf | `any` | See default |
| `log_buckets`    | See variables.tf | `any` | See default |
| `log_sinks`      | See variables.tf | `any` | See default |
| `log_exclusions` | See variables.tf | `any` | See default |
| `log_metrics`    | See variables.tf | `any` | See default |

## Outputs

| Name                         | Description    |
| ---------------------------- | -------------- |
| `log_bucket_ids`             | See outputs.tf |
| `log_sink_ids`               | See outputs.tf |
| `log_sink_writer_identities` | See outputs.tf |
| `log_exclusion_ids`          | See outputs.tf |
| `log_metric_ids`             | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
