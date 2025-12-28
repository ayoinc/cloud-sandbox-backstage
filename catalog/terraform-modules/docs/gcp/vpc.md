# GCP VPC Module

Creates a production-ready VPC network with subnets, Cloud NAT, Cloud Router, and firewall rules following Google Cloud best practices.

## Features

- Custom mode VPC network
- Multiple subnets with configurable CIDR ranges
- Secondary IP ranges for GKE pods/services
- Cloud Router and Cloud NAT for outbound internet access
- Customizable firewall rules
- VPC Flow Logs support
- Private Google Access
- IAP SSH access by default

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "../../../gcp/resources/network/vpc"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"
}
```

### Production Configuration with GKE Support

```hcl
module "vpc" {
  source = "../../../gcp/resources/network/vpc"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"

  routing_mode = "GLOBAL"

  subnets = {
    gke = {
      ip_cidr_range            = "10.0.0.0/20"
      region                   = "us-central1"
      private_ip_google_access = true
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
      log_config = {
        aggregation_interval = "INTERVAL_5_SEC"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
    database = {
      ip_cidr_range            = "10.3.0.0/24"
      region                   = "us-central1"
      private_ip_google_access = true
    }
  }

  enable_nat = true

  firewall_rules = {
    allow-health-checks = {
      description   = "Allow GCP health checks"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443", "8080"]
      }]
    }
  }

  labels = {
    team = "platform"
  }
}
```

### Development Configuration

```hcl
module "vpc" {
  source = "../../../gcp/resources/network/vpc"

  project_id  = "my-dev-project"
  name        = "myapp"
  environment = "dev"
  region      = "us-central1"

  subnets = {
    default = {
      ip_cidr_range = "10.0.0.0/24"
    }
  }

  enable_nat = true
}
```

## Variables

| Name                      | Description                       | Type          | Default         | Required |
| ------------------------- | --------------------------------- | ------------- | --------------- | -------- |
| `project_id`              | GCP Project ID                    | `string`      | -               | Yes      |
| `name`                    | Name prefix for resources         | `string`      | -               | Yes      |
| `environment`             | Environment (dev, staging, prod)  | `string`      | -               | Yes      |
| `region`                  | GCP region                        | `string`      | `"us-central1"` | No       |
| `routing_mode`            | Routing mode (GLOBAL or REGIONAL) | `string`      | `"GLOBAL"`      | No       |
| `auto_create_subnetworks` | Auto-create subnetworks           | `bool`        | `false`         | No       |
| `subnets`                 | Subnet configurations             | `map(object)` | See below       | No       |
| `enable_nat`              | Enable Cloud NAT                  | `bool`        | `true`          | No       |
| `nat_ip_allocate_option`  | NAT IP allocation                 | `string`      | `"AUTO_ONLY"`   | No       |
| `firewall_rules`          | Custom firewall rules             | `map(object)` | `{}`            | No       |
| `labels`                  | Labels to apply                   | `map(string)` | `{}`            | No       |

### Subnet Configuration

```hcl
subnets = {
  subnet_name = {
    ip_cidr_range            = "10.0.0.0/24"
    region                   = "us-central1"           # Optional, defaults to var.region
    private_ip_google_access = true                    # Optional, defaults to true
    secondary_ip_ranges = [                            # Optional, for GKE
      {
        range_name    = "pods"
        ip_cidr_range = "10.1.0.0/16"
      }
    ]
    log_config = {                                     # Optional, for flow logs
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}
```

## Outputs

| Name                | Description                       |
| ------------------- | --------------------------------- |
| `network_id`        | VPC network ID                    |
| `network_name`      | VPC network name                  |
| `network_self_link` | VPC network self link             |
| `subnet_ids`        | Map of subnet names to IDs        |
| `subnet_self_links` | Map of subnet names to self links |
| `subnet_regions`    | Map of subnet names to regions    |
| `router_id`         | Cloud Router ID                   |
| `nat_id`            | Cloud NAT ID                      |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        VPC Network                            │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                     Cloud Router                        │  │
│  │                         │                               │  │
│  │                    Cloud NAT                            │  │
│  └────────────────────────────────────────────────────────┘  │
│                           │                                   │
│     ┌─────────────────────┼─────────────────────┐            │
│     │                     │                     │            │
│ ┌───┴────────┐      ┌────┴───────┐      ┌─────┴──────┐     │
│ │   Subnet   │      │   Subnet   │      │   Subnet   │     │
│ │   (GKE)    │      │ (Compute)  │      │ (Database) │     │
│ │            │      │            │      │            │     │
│ │ Primary:   │      │ Primary:   │      │ Primary:   │     │
│ │ 10.0.0.0/20│      │ 10.3.0.0/24│      │ 10.4.0.0/24│     │
│ │            │      │            │      │            │     │
│ │ Secondary: │      └────────────┘      └────────────┘     │
│ │ - pods     │                                              │
│ │ - services │                                              │
│ └────────────┘                                              │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Firewall Rules                        │  │
│  │  ✓ allow-internal    ✓ allow-ssh-iap    ✓ custom      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Security Features

### Default Firewall Rules

1. **Allow Internal** - All TCP/UDP/ICMP between subnets
2. **Allow SSH via IAP** - SSH access from IAP source ranges (35.235.240.0/20)

### Private Google Access

Enabled by default on all subnets, allowing VMs without external IPs to access Google APIs.

### VPC Flow Logs

Optional per-subnet flow logging for network monitoring and forensics:

```hcl
log_config = {
  aggregation_interval = "INTERVAL_5_SEC"
  flow_sampling        = 0.5
  metadata             = "INCLUDE_ALL_METADATA"
}
```

## GKE Integration

For GKE clusters, configure secondary IP ranges:

```hcl
subnets = {
  gke = {
    ip_cidr_range = "10.0.0.0/20"
    secondary_ip_ranges = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.1.0.0/16"    # /16 for pods
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.2.0.0/20"    # /20 for services
      }
    ]
  }
}
```

## Cost Considerations

| Component    | Cost Factor               |
| ------------ | ------------------------- |
| VPC Network  | Free                      |
| Cloud NAT    | Per VM + per GB processed |
| Cloud Router | Per hour                  |
| Flow Logs    | Log ingestion costs       |

**Tips:**

- Cloud NAT charges per VM using it
- VPC Flow Logs can generate significant log volume
- Use REGIONAL routing for simpler setups
