# GCP Load Balancer

Terraform module for provisioning GCP Load Balancer.

## Overview

This module creates and manages GCP Load Balancer with production-ready defaults and best practices.

## Usage

```hcl
module "load_balancer" {
  source = "path/to/modules/google/resources/network/load-balancer"

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

| Name                              | Description      | Type  | Required    |
| --------------------------------- | ---------------- | ----- | ----------- |
| `project_name`                    | See variables.tf | `any` | See default |
| `project_id`                      | See variables.tf | `any` | See default |
| `environment`                     | See variables.tf | `any` | See default |
| `name`                            | See variables.tf | `any` | See default |
| `enable_https`                    | See variables.tf | `any` | See default |
| `ssl_certificates`                | See variables.tf | `any` | See default |
| `managed_ssl_certificate_domains` | See variables.tf | `any` | See default |
| `backends`                        | See variables.tf | `any` | See default |
| `health_check`                    | See variables.tf | `any` | See default |
| `enable_cdn`                      | See variables.tf | `any` | See default |
| `cdn_cache_mode`                  | See variables.tf | `any` | See default |
| `security_policy`                 | See variables.tf | `any` | See default |
| `custom_request_headers`          | See variables.tf | `any` | See default |
| `custom_response_headers`         | See variables.tf | `any` | See default |
| `connection_draining_timeout_sec` | See variables.tf | `any` | See default |
| `log_config_enable`               | See variables.tf | `any` | See default |
| `log_config_sample_rate`          | See variables.tf | `any` | See default |

## Outputs

| Name                  | Description    |
| --------------------- | -------------- |
| `load_balancer_ip`    | See outputs.tf |
| `backend_service_id`  | See outputs.tf |
| `url_map_id`          | See outputs.tf |
| `http_proxy_id`       | See outputs.tf |
| `https_proxy_id`      | See outputs.tf |
| `forwarding_rule_id`  | See outputs.tf |
| `ssl_certificate_ids` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
