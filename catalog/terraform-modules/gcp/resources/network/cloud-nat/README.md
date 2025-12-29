# GCP Cloud NAT

Terraform module for provisioning GCP Cloud NAT.

## Overview

This module creates and manages GCP Cloud NAT with production-ready defaults and best practices.

## Usage

```hcl
module "cloud_nat" {
  source = "path/to/modules/google/resources/network/cloud-nat"

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
| `router_name` | See variables.tf | `any` | See default |
| `nat_name` | See variables.tf | `any` | See default |
| `nat_ip_allocate_option` | See variables.tf | `any` | See default |
| `nat_ips` | See variables.tf | `any` | See default |
| `source_subnetwork_ip_ranges_to_nat` | See variables.tf | `any` | See default |
| `subnetworks` | See variables.tf | `any` | See default |
| `min_ports_per_vm` | See variables.tf | `any` | See default |
| `max_ports_per_vm` | See variables.tf | `any` | See default |
| `enable_dynamic_port_allocation` | See variables.tf | `any` | See default |
| `enable_endpoint_independent_mapping` | See variables.tf | `any` | See default |
| `udp_idle_timeout_sec` | See variables.tf | `any` | See default |
| `tcp_established_idle_timeout_sec` | See variables.tf | `any` | See default |
| `tcp_transitory_idle_timeout_sec` | See variables.tf | `any` | See default |
| `tcp_time_wait_timeout_sec` | See variables.tf | `any` | See default |
| `icmp_idle_timeout_sec` | See variables.tf | `any` | See default |
| `log_config_enable` | See variables.tf | `any` | See default |
| `log_config_filter` | See variables.tf | `any` | See default |

## Outputs

| Name | Description |
|------|-------------|
| `nat_id` | See outputs.tf |
| `nat_name` | See outputs.tf |

## Features

- Production-ready configuration
- Best practices security defaults
- Comprehensive tagging support
- Modular and reusable design

## License

MIT License
