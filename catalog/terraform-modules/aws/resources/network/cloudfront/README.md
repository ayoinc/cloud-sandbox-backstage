# AWS CloudFront CDN

Terraform module for provisioning AWS CloudFront CDN.

## Overview

This module creates and manages AWS CloudFront CDN with production-ready defaults and best practices.

## Usage

```hcl
module "cloudfront" {
  source = "path/to/modules/aws/resources/network/cloudfront"

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
| `origin_domain_name` | See variables.tf | `any` | See default |
| `origin_id` | See variables.tf | `any` | See default |
| `origin_type` | See variables.tf | `any` | See default |
| `s3_origin_access_control` | See variables.tf | `any` | See default |
| `default_root_object` | See variables.tf | `any` | See default |
| `enabled` | See variables.tf | `any` | See default |
| `is_ipv6_enabled` | See variables.tf | `any` | See default |
| `price_class` | See variables.tf | `any` | See default |
| `viewer_protocol_policy` | See variables.tf | `any` | See default |
| `allowed_methods` | See variables.tf | `any` | See default |
| `cached_methods` | See variables.tf | `any` | See default |
| `default_ttl` | See variables.tf | `any` | See default |
| `max_ttl` | See variables.tf | `any` | See default |
| `min_ttl` | See variables.tf | `any` | See default |
| `compress` | See variables.tf | `any` | See default |
| `certificate_arn` | See variables.tf | `any` | See default |
| `aliases` | See variables.tf | `any` | See default |
| `web_acl_id` | See variables.tf | `any` | See default |
| `geo_restriction_type` | See variables.tf | `any` | See default |
| `geo_restriction_locations` | See variables.tf | `any` | See default |
| `custom_error_responses` | See variables.tf | `any` | See default |
| `tags` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | See outputs.tf |
| `distribution_arn` | See outputs.tf |
| `distribution_domain_name` | See outputs.tf |
| `distribution_hosted_zone_id` | See outputs.tf |
| `origin_access_control_id` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
