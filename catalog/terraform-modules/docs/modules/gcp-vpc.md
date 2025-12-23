# GCP VPC Module

This Terraform module creates a Google Cloud VPC with robust networking features including custom subnets, Cloud NAT, firewall rules, and Shared VPC support for enterprise multi-project architectures.

## Overview

Google Cloud VPC (Virtual Private Cloud) provides a scalable and flexible networking environment for your cloud resources. This module implements best practices for VPC design with support for:

### Google Cloud VPC Concepts

- **Global VPC Network**: A single VPC spans all regions without performance degradation
- **Custom Mode VPC**: Full control over subnets and IP ranges (recommended over auto mode)
- **Regional Subnets**: Each subnet is associated with a specific region and zone
- **Shared VPC**: Centralize network administration across multiple service projects
- **VPC Peering**: Private communication between VPC networks

### Key Benefits

- **Global by default**: Single VPC covers all GCP regions with low-latency connectivity
- **Software-defined networking**: No physical hardware management required
- **Granular control**: Custom subnets, firewall rules, and routing
- **Hybrid connectivity**: Cloud VPN, Cloud Interconnect for on-premises integration
- **Integration ready**: Native support for GKE, Cloud Run, Cloud SQL, and Load Balancing

## Features

### Core Networking
- Custom mode VPC with full subnet control
- Regional subnets with configurable IP CIDR ranges
- Support for up to 7500 internal IP addresses per VPC
- Global routing mode for cross-region communication

### GKE Integration
- Secondary IP ranges for Kubernetes pods and services
- IP aliasing support for efficient IP utilization
- Pod and service CIDR configuration per subnet
- Automatic route management for GKE

### Internet Access & Security
- Cloud NAT for private instance outbound connectivity
- Manual or automatic NAT IP allocation
- Multiple NAT IPs for high availability
- Private Google Access for API consumption without internet
- VPC-native load balancing support

### Advanced Networking
- Shared VPC host and service project configurations
- VPC peering setup for inter-network communication
- Import/export custom routes
- Firewall rule management with logging
- VPC Flow Logs for network analysis
- Support for 25 Gbps per VM network interface

## Architecture

### VPC Topology for GKE

```
┌─────────────────────────────────────────────────────────┐
│                   Global VPC Network                    │
│                                                         │
│  ┌─────────────┐            ┌─────────────┐           │
│  │ us-central1 │            │ europe-west1│           │
│  │  Subnet A   │            │  Subnet B   │           │
│  │ 10.0.1.0/24 │            │ 10.0.2.0/24 │           │
│  │             │            │             │           │
│  │ Secondary:  │            │ Secondary:  │           │
│  │ - Pods:     │            │ - Pods:     │           │
│  │  10.1.0.0/16│            │  10.3.0.0/16│           │
│  │ - Services: │            │ - Services: │           │
│  │  10.2.0.0/20│            │  10.4.0.0/20│           │
│  └──────┬──────┘            └──────┬──────┘           │
│         │                          │                  │
│         │                          │                  │
│  ┌──────▼──────┐            ┌──────▼──────┐          │
│  │  GKE Nodes  │            │  GKE Nodes  │          │
│  │  (VMs)      │            │  (VMs)      │          │
│  └──────┬──────┘            └──────┬──────┘          │
│         │                          │                 │
│         └──────────┬────────────────┘                 │
│                    │ Cloud NAT (Egress)               │
│                    │  (us-central1, europe-west1)    │
│                    │                                  │
└────────────────────┼──────────────────────────────────┘
                     │
              Private Google Access
                     │
              ┌──────▼────────┐
              │ GCP Services  │
              │ (GCS, APIs)   │
              └───────────────┘
```

### Shared VPC for Multi-Project

```
┌─────────────────────────────────────────┐
│         Host Project                    │
│  ┌─────────────────────────────────┐    │
│  │  Shared VPC Network              │    │
│  │  - Centralized Networking        │    │
│  │  - Firewall Rules                │    │
│  │  - Cloud NAT                     │    │
│  └──────────┬──────────────────────┘    │
│             │                           │
│             │ Shared VPC                │
└─────────────┼───────────────────────────┘
              │ IAM: compute.networkUser
              │
    ┌─────────▼────────┬──────────┬────────────┐
    │                  │          │            │
┌───▼───┐        ┌───▼───┐  ┌──▼──┐    ┌────▼────┐
│Service│        │Service│  │Service│   │Service │
│Proj 1 │        │Proj 2 │  │Proj 3 │   │Proj 4  │
│Dev    │        │Staging│  │Prod   │   │Data    │
└───────┘        └───────┘  └───────┘   └────────┘
```

**Use Cases for Shared VPC:**
- Centralized network administration by network team
- Cost optimization with shared Cloud NAT, VPN, Interconnect
- Security compliance with consistent firewall rules
- Service separation with project-level IAM

### VPC Peering

- Connect VPCs for private RFC 1918 communication
- No transitive peering (spoke-to-spoke requires direct peering)
- Import/export routes for custom route exchange
- Useful for: partner connectivity, service providers, multi-team architectures

## Usage

### Simple VPC for Development

```hcl
module "vpc_simple" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.project_id
  name       = "dev-vpc"

  subnets = [
    {
      name          = "dev-subnet"
      ip_cidr_range = "10.10.0.0/24"
      region        = "us-central1"
    }
  ]

  enable_cloud_nat = true
}
```

**Validate with gcloud:**
```bash
# List VPC networks
gcloud compute networks list

# Describe subnet details
gcloud compute networks subnets describe dev-subnet --region=us-central1

# Check Cloud NAT status
gcloud compute routers nats list --router=dev-vpc-router --region=us-central1
```

### GKE-Ready VPC with Secondary Ranges

```hcl
module "vpc_gke" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.project_id
  name       = "gke-vpc"

  subnets = [
    {
      name          = "gke-subnet-us-central1"
      ip_cidr_range = "10.0.1.0/24"
      region        = "us-central1"
      
      secondary_ip_ranges = [
        {
          range_name    = "us-central1-gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "us-central1-gke-services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
    },
    {
      name          = "gke-subnet-europe-west1"
      ip_cidr_range = "10.0.2.0/24"
      region        = "europe-west1"
      
      secondary_ip_ranges = [
        {
          range_name    = "europe-west1-gke-pods"
          ip_cidr_range = "10.3.0.0/16"
        },
        {
          range_name    = "europe-west1-gke-services"
          ip_cidr_range = "10.4.0.0/20"
        }
      ]
    }
  ]

  enable_cloud_nat          = true
  cloud_nat_min_ports_per_vm = 512
  cloud_nat_enable_logging   = true
  
  enable_private_google_access = true

  firewall_rules = [
    {
      name        = "gke-node-to-node"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["10.0.0.0/24", "10.0.1.0/24"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["1-65535"]
        },
        {
          protocol = "udp"
          ports    = ["1-65535"]
        }
      ]
      enable_logging = true
    },
    {
      name        = "allow-health-checks"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443", "8080", "8443"]
        }
      ]
      enable_logging = true
    }
  ]
}

module "gke_cluster" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/gke?ref=v1.0.0"
  
  vpc_network_name = module.vpc_gke.network_name
  subnet_name      = "gke-subnet-us-central1"
  pod_range_name   = "us-central1-gke-pods"
  service_range_name = "us-central1-gke-services"
  
  ip_allocation_policy = {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }
}
```

### Shared VPC Host Project

```hcl
# Host project configuration
module "vpc_host" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.host_project_id
  name       = "shared-vpc"

  subnets = [
    {
      name          = "production-subnet"
      ip_cidr_range = "10.50.0.0/16"
      region        = var.region
      
      secondary_ip_ranges = [
        {
          range_name    = "prod-gke-pods"
          ip_cidr_range = "10.60.0.0/16"
        },
        {
          range_name    = "prod-gke-services"
          ip_cidr_range = "10.70.0.0/20"
        }
      ]
    }
  ]

  shared_vpc_host = true
  enable_cloud_nat = true
  
  service_projects = [
    var.dev_project_id,
    var.staging_project_id,
    var.prod_project_id
  ]

  # Shared VPC IAM roles
  shared_vpc_subnet_iam = {
    "production-subnet" = [
      {
        role   = "roles/compute.networkUser"
        member = "serviceAccount:service-${var.dev_project_number}@compute-system.iam.gserviceaccount.com"
      },
      {
        role   = "roles/compute.networkUser"
        member = "group:dev-team@company.com"
      }
    ]
  }
}

# Service project uses the shared VPC
data "google_compute_network" "shared_vpc" {
  project = var.host_project_id
  name    = "shared-vpc"
}

module "gke_service_project" {
  source   = "git::https://github.com/company/terraform-modules.git//gcp/gke?ref=v1.0.0"
  
  network = data.google_compute_network.shared_vpc.self_link
  # ... other GKE configurations
}
```

### VPC Peering with Routes Import/Export

```hcl
# Create two VPCs
module "vpc1" {
  source     = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  project_id = var.project_id
  name       = "vpc1-application"
  subnets    = [/* ... */]
}

module "vpc2" {
  source     = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  project_id = var.project_id
  name       = "vpc2-shared-services"
  subnets    = [/* ... */]
}

# Create peering from vpc1 to vpc2
resource "google_compute_network_peering" "vpc1_to_vpc2" {
  name         = "peering-vpc1-to-vpc2"
  network      = module.vpc1.network_self_link
  peer_network = module.vpc2.network_self_link

  import_custom_routes = true
  export_custom_routes = true
}

# Create peering from vpc2 to vpc1 (required for bidirectional)
resource "google_compute_network_peering" "vpc2_to_vpc1" {
  name         = "peering-vpc2-to-vpc1"
  network      = module.vpc2.network_self_link
  peer_network = module.vpc1.network_self_link

  import_custom_routes = true
  export_custom_routes = true
}
```

## Inputs

### Required Inputs

#### project_id
- **Description**: GCP Project ID where the VPC will be created
- **Type**: `string`
- **Example**: `"my-gcp-project-12345"`
- **CLI Check**: `gcloud projects list`

#### name
- **Description**: Name of the VPC network
- **Type**: `string`
- **Constraints**: Must be lowercase, alphanumeric with hyphens
- **Example**: `"production-vpc"`, `"shared-vpc-host"`

#### subnets
- **Description**: List of subnet configurations
- **Type**: `list(object({...}))`
- **Example**: See comprehensive example below

```hcl
subnets = [
  {
    name          = string  # "production-subnet"
    ip_cidr_range = string  # "10.0.1.0/24" (Must be RFC 1918 range)
    region        = string  # "us-central1"
    
    # Optional: Secondary ranges for GKE
    secondary_ip_ranges = list(object({
      range_name    = string  # "us-central1-pods"
      ip_cidr_range = string  # "10.1.0.0/16"
    }))
    
    # Optional: Flow logs for network analysis
    enable_flow_logs = bool  # true/false
    
    # Optional: Private Google Access
    private_ip_google_access = bool  # true/false
  }
]
```

### Optional Inputs

#### enable_cloud_nat
- **Description**: Enable Cloud NAT for outbound internet access
- **Type**: `bool`
- **Default**: `true`
- **Use Case**: Required for private instances without external IPs

#### cloud_nat_min_ports_per_vm
- **Description**: Minimum ports allocated per VM for NAT
- **Type**: `number`
- **Default**: `64`
- **Range**: `2-65536`
- **Considerations**: 
  - GKE nodes: `512-2048` recommended
  - Standard VMs: `64-256` sufficient
  - High traffic: Increase to prevent port exhaustion

#### cloud_nat_max_ports_per_vm
- **Description**: Maximum ports per VM (auto-allocation mode)
- **Type**: `number`
- **Default**: `65536`

#### cloud_nat_auto_allocate_ips
- **Description**: Automatically allocate NAT external IPs
- **Type**: `bool`
- **Default**: `true`
- **Alternative**: Set `false` and use `cloud_nat_ips` for manual IPs

#### cloud_nat_ips
- **Description**: List of manually assigned NAT IP addresses
- **Type**: `list(string)`
- **Example**: `["35.192.10.5", "35.192.10.6"]`
- **Prerequisite**: Reserve IPs first with `google_compute_address`

#### cloud_nat_enable_logging
- **Description**: Enable Cloud NAT logging for monitoring
- **Type**: `bool`
- **Default**: `false`
- **Log Types**: `TRANSLATION`, `ERRORS_ONLY`, `ALL`
- **Destination**: Cloud Logging for analysis

#### routing_mode
- **Description**: VPC routing mode for cross-region communication
- **Type**: `string`
- **Default**: `"REGIONAL"`
- **Options**: `"REGIONAL"`, `"GLOBAL"`
- **Recommendation**: Use `GLOBAL` for multi-region architectures

#### enable_private_google_access
- **Description**: Enable Private Google Access on all subnets
- **Type**: `bool`
- **Default**: `true`
- **Benefit**: Access Google APIs without internet/NAT
- **Scope**: Applies to all subnets (override per subnet if needed)

#### shared_vpc_host
- **Description**: Enable this project as Shared VPC host
- **Type**: `bool`
- **Default**: `false`
- **Impact**: Project becomes Shared VPC host, can't be undone via Terraform

#### service_projects
- **Description**: List of service project IDs to attach to Shared VPC
- **Type**: `list(string)`
- **Example**: `["dev-project-123", "prod-project-456"]`
- **Requirement**: Must have Shared VPC Admin permissions

#### shared_vpc_subnet_iam
- **Description**: IAM bindings for service projects on specific subnets
- **Type**: `map(list(object({ role = string, member = string })))`
- **Example**:
```hcl
shared_vpc_subnet_iam = {
  "production-subnet" = [
    {
      role   = "roles/compute.networkUser"
      member = "serviceAccount:service-12345@compute-system.iam.gserviceaccount.com"
    }
  ]
}
```

#### firewall_rules
- **Description**: List of firewall rules for network security
- **Type**: `list(object({...}))`
- **Example**:
```hcl
firewall_rules = [
  {
    name        = "allow-ssh"
    direction   = "INGRESS"
    priority    = 1000
    source_ranges = ["10.0.0.0/8"]
    
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    
    deny = []  # Optional
    
    target_tags = ["bastion-host"]
    
    enable_logging = true
    
    description = "Allow SSH from internal network"
  }
]
```

#### enable_flow_logs
- **Description**: Enable VPC Flow Logs for all subnets
- **Type**: `bool`
- **Default**: `false`
- **Use Cases**: Network analysis, security monitoring, cost attribution
- **Storage**: Cloud Logging with configurable sample rates

#### mtu
- **Description**: Maximum Transmission Unit for the VPC
- **Type**: `number`
- **Default**: `1460`
- **Options**: `1460`, `1500` (for jumbo frames)
- **Requirement**: Must match interconnect/VPN MTU settings

#### delete_default_internet_gateway_routes
- **Description**: Remove default route to internet gateway
- **Type**: `bool`
- **Default**: `false`
- **Security**: Use `true` for isolated VPCs without internet access

## Outputs

### network_id
- **Description**: The ID of the VPC network
- **Type**: `string`
- **Example Usage**:
```hcl
resource "google_compute_instance" "vm" {
  network_interface {
    network = module.vpc.network_id
  }
}
```

### network_name
- **Description**: The name of the VPC network
- **Type**: `string`
- **Use Case**: Reference in other modules (GKE, Cloud SQL)

### network_self_link
- **Description**: The self-link of the VPC network
- **Type**: `string`
- **Example**: `https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-vpc`

### subnets
- **Description**: Map of subnet names to subnet objects
- **Type**: `map(object({...}))`
- **Example Usage**:
```hcl
module "gke" {
  subnet_name = module.vpc.subnets["gke-subnet"].name
  pod_range_name = module.vpc.subnets["gke-subnet"].secondary_ip_range[0].range_name
}
```

### subnets_by_region
- **Description**: Map of region to list of subnet objects
- **Type**: `map(list(object({...})))`
- **Use Case**: Deploy region-specific resources

### cloud_router_name
- **Description**: Name of the Cloud Router (for Cloud NAT)
- **Type**: `string`
- **Usage**: Diagnostic commands
```bash
gcloud compute routers describe $(terraform output -raw cloud_router_name) --region=us-central1
```

### cloud_nat_name
- **Description**: Name of the Cloud NAT gateway
- **Type**: `string`

### cloud_nat_ips
- **Description**: List of external IPs used by Cloud NAT
- **Type**: `list(string)`
- **Usage**: Allowlist these IPs in external firewalls

### region_routers
- **Description**: Map of region to Cloud Router details
- **Type**: `map(object({...}))`

## Subnet Design

### Primary and Secondary IP Ranges for GKE

Subnets require careful IP planning for GKE clusters:

#### Primary Subnet Range
```
Purpose: Node IP addresses
Size: /24 (256 IPs) supports ~110 nodes (accounting for reserved IPs)
Example: 10.0.1.0/24
```

#### Secondary Ranges
```
Pods Range:
  - Purpose: Kubernetes pod IPs
  - Size: /16 (65,536 IPs) for up to ~1000 nodes
  - Maximum pods per node: 110 (GKE default)
  - Example: 10.1.0.0/16

Services Range:
  - Purpose: Kubernetes services ClusterIPs
  - Size: /20 (4096 IPs) sufficient for most clusters
  - Example: 10.2.0.0/20
```

### Planning Subnet Sizes

```hcl
# Development cluster (small scale)
{
  name          = "dev-subnet"
  ip_cidr_range = "10.0.1.0/26"      # 62 usable IPs
  secondary_ip_ranges = [
    {
      range_name    = "dev-pods"
      ip_cidr_range = "10.1.0.0/18"  # 16,382 pods
    },
    {
      range_name    = "dev-services"
      ip_cidr_range = "10.2.0.0/22"  # 1022 services
    }
  ]
}

# Production cluster (large scale)
{
  name          = "prod-subnet"
  ip_cidr_range = "10.0.1.0/22"      # 1018 usable IPs (400+ nodes)
  secondary_ip_ranges = [
    {
      range_name    = "prod-pods"
      ip_cidr_range = "10.1.0.0/14"  # 262,142 pods (2000+ nodes)
    },
    {
      range_name    = "prod-services"
      ip_cidr_range = "10.5.0.0/19"  # 8190 services
    }
  ]
}
```

### Multiple GKE Clusters per Subnet

```hcl
# Development clusters share subnet
secondary_ip_ranges = [
  {
    range_name    = "cluster1-pods"
    ip_cidr_range = "10.1.0.0/17"   # 32,766 IPs
  },
  {
    range_name    = "cluster1-services"
    ip_cidr_range = "10.2.0.0/21"   # 2046 IPs
  },
  {
    range_name    = "cluster2-pods"
    ip_cidr_range = "10.3.0.0/17"   # 32,766 IPs
  },
  {
    range_name    = "cluster2-services"
    ip_cidr_range = "10.4.0.0/21"   # 2046 IPs
  }
]
```

### Non-RFC 1918 Ranges

```hcl
# Use when RFC 1918 is exhausted
subnets = [
  {
    name          = "non-rfc-1918-subnet"
    ip_cidr_range = "100.64.0.0/24"    # Shared address space
  }
]
```

## Cloud NAT

### When to Use Cloud NAT

**Use Cases:**
- Private GKE clusters without external IPs
- Secure VMs in private subnets
- Compliance requiring no public IPs
- Cost optimization (pay-per-use vs per-IP)

**Don't Use When:**
- Instances need inbound internet access (use Cloud Load Balancing)
- You need fixed egress IPs for allowlisting (use multiple static NAT IPs)

### Configuration Options

#### Basic Cloud NAT (Auto IPs)
```hcl
enable_cloud_nat = true
cloud_nat_auto_allocate_ips = true
cloud_nat_min_ports_per_vm = 64
```

#### High Availability Cloud NAT (Multiple IPs)
```hcl
# Reserve IPs first
resource "google_compute_address" "nat_ips" {
  count  = 3
  name   = "nat-ip-${count.index}"
  region = var.region
}

# Configure NAT with manual IPs
enable_cloud_nat = true
cloud_nat_auto_allocate_ips = false
cloud_nat_ips = google_compute_address.nat_ips[*].self_link
cloud_nat_min_ports_per_vm = 512
```

#### GKE Optimized NAT
```hcl
# GKE nodes need more ports due to multiple pods
enable_cloud_nat = true
cloud_nat_min_ports_per_vm = 2048          # High port count
cloud_nat_max_ports_per_vm = 65536         # Auto-scale
cloud_nat_enable_endpoint_independent_mapping = false  # Better performance
```

#### Regional Cloud NAT (Recommended)
```hcl
# Per-region NAT for multi-region VPC
subnets = [
  {
    name          = "us-subnet"
    region        = "us-central1"
    ip_cidr_range = "10.0.1.0/24"
  },
  {
    name          = "eu-subnet"
    region        = "europe-west1"
    ip_cidr_range = "10.0.2.0/24"
  }
]

# Module creates NAT gateways per region automatically
enable_cloud_nat = true
```

### Manual vs Auto NAT IPs

| Feature | Auto IPs | Manual IPs |
|---------|----------|------------|
| Setup | Simple, no pre-configuration | Must reserve IPs first |
| Cost | Pay per GB data processed | Pay per GB + IP reservation cost |
| Allowlisting | IPs change on recreation | Static IPs for external allowlists |
| Quota | Automatic quota management | Manual quota tracking required |
| High Availability | Created automatically | Manual IP selection needed |

### Monitoring NAT

```bash
# Check NAT configuration
gcloud compute routers nats describe prod-nat --router=prod-router --region=us-central1

# View NAT usage metrics
gcloud compute routers describe prod-router --region=us-central1 --format="yaml(nats)"

# Monitor port allocation
gcloud monitoring time-series list \
  --filter='metric.type="compute.googleapis.com/nat/port_usage"' \
  --aggregation='{"alignmentPeriod": "300s","perSeriesAligner": "ALIGN_MEAN"}'
```

### Troubleshooting NAT Port Exhaustion

**Symptoms:**
- Connection timeouts from private instances
- `SYN_SENT` connections stuck
- GCP monitoring alerts for high port usage

**Solutions:**
1. Increase `cloud_nat_min_ports_per_vm`
2. Add more NAT IPs: `cloud_nat_ips = [...]`
3. Reduce idle timeout: `cloud_nat_tcp_established_idle_timeout_sec = 600`
4. Implement connection pooling in applications

## Shared VPC

### Host and Service Project Setup

#### Step 1: Enable Shared VPC Host
```hcl
module "shared_vpc_host" {
  source         = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  project_id     = var.host_project_id
  name           = "shared-vpc-network"
  shared_vpc_host = true
  
  subnets = [/* subnet configuration */]
}
```

**Verify with gcloud:**
```bash
# Enable host project (one-time setup)
gcloud compute shared-vpc enable host-project-id

# List service projects
gcloud compute shared-vpc list-associated-resources host-project-id

# Check subnet IAM
gcloud compute networks subnets get-iam-policy production-subnet --region=us-central1
```

#### Step 2: Configure Service Project Attachments
```hcl
# Grant IAM roles to service projects
resource "google_project_iam_member" "service_projects" {
  for_each = toset(var.service_project_ids)
  
  project = module.vpc_host.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.service[each.key].number}@compute-system.iam.gserviceaccount.com"
}

# Or use module's built-in IAM management
deploy_service_projects = true
service_projects = ["dev-123", "prod-456"]
```

### IAM Roles Required

**In Host Project:**
```hcl
# For network administrators
roles/compute.networkAdmin        # Manage Shared VPC
roles/compute.xpnAdmin           # Enable/disable Shared VPC
roles/compute.securityAdmin      # Manage firewall rules

# For service accounts
roles/compute.networkUser        # Use subnets in service projects
```

**In Service Projects:**
```hcl
# For GKE
echo "service-{PROJECT_NUMBER}@container-engine-robot.iam.gserviceaccount.com" | 
  gcloud projects add-iam-policy-binding host-project-id \
    --member="serviceAccount:{GKE_SERVICE_ACCOUNT}" \
    --role="roles/compute.networkUser"

# For Dataflow
echo "service-{PROJECT_NUMBER}@dataflow-service-producer-prod.iam.gserviceaccount.com" |
  gcloud projects add-iam-policy-binding host-project-id \
    --member="serviceAccount:{DATAFLOW_SERVICE_ACCOUNT}" \
    --role="roles/compute.networkUser"
```

### Use Cases

#### 1. Centralized Security
```hcl
# Host project manages all network security
module "shared_vpc" {
  shared_vpc_host = true
  
  firewall_rules = [
    {
      name        = "deny-all-egress"
      direction   = "EGRESS"
      priority    = 65535
      destination_ranges = ["0.0.0.0/0"]
      deny = [{ protocol = "all" }]
    }
  ]
}

# Service projects inherit security policies
```

#### 2. Cost Optimization
```hcl
# Single Cloud NAT for all service projects
module "shared_vpc" {
  enable_cloud_nat = true
  
  # 3 NAT IPs shared across 10 service projects
  cloud_nat_auto_allocate_ips = false
  cloud_nat_ips = [
    google_compute_address.nat-1.self_link,
    google_compute_address.nat-2.self_link,
    google_compute_address.nat-3.self_link
  ]
}
```

#### 3. Multi-Environment Isolation
```hcl
# Different subnets for each environment
subnets = [
  {
    name          = "dev-subnet"
    ip_cidr_range = "10.10.0.0/16"
  },
  {
    name          = "staging-subnet"
    ip_cidr_range = "10.20.0.0/16"
  },
  {
    name          = "prod-subnet"
    ip_cidr_range = "10.30.0.0/16"
  }
]

shared_vpc_subnet_iam = {
  "dev-subnet" = [
    {
      role   = "roles/compute.networkUser"
      member = "serviceAccount:service-${dev_project_number}@compute-system.iam.gserviceaccount.com"
    }
  ]
  "staging-subnet" = [ /* staging service account */ ]
  "prod-subnet" = [ /* prod service account */ ]
}
```

### Shared VPC Limitations

- **Max Service Projects**: 100 per Shared VPC host
- **Subnet Limits**: 100 shared subnets per host
- **Regional Restriction**: Service projects limited to same org
- **Network Admin**: Must reside in host project
- **Firewall Rules**: Managed only in host project (service projects can't override)

## Security

### Firewall Rules

#### Best Practices
```hcl
firewall_rules = [
  # 1. Deny all egress by default (whitelist approach)
  {
    name        = "default-deny-egress"
    direction   = "EGRESS"
    priority    = 65535
    destination_ranges = ["0.0.0.0/0"]
    deny = [{ protocol = "all" }]
    enable_logging = true
  },
  
  # 2. Allow specific egress
  {
    name        = "allow-egress-gcp-apis"
    direction   = "EGRESS"
    priority    = 1000
    destination_ranges = ["199.36.153.4/30", "199.36.153.8/30"]  # Private Google Access
    allow = [{
      protocol = "tcp"
      ports    = ["443"]
    }]
  },
  
  # 3. Allow ingress (specific)
  {
    name        = "allow-ssh-from-bastion"
    direction   = "INGRESS"
    priority    = 1000
    source_ranges = [module.vpc.subnets["bastion-subnet"].ip_cidr_range]
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    target_tags = ["ssh-accessible"]
  },
  
  # 4. Allow GKE health checks
  {
    name        = "allow-health-checks"
    direction   = "INGRESS"
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
    allow = [{
      protocol = "tcp"
      ports    = ["80", "443", "8080"]
    }]
  },
  
  # 5. Allow internal communication
  {
    name        = "allow-internal"
    direction   = "INGRESS"
    source_ranges = ["10.0.0.0/8"]
    allow = [
      { protocol = "tcp", ports = ["0-65535"] },
      { protocol = "udp", ports = ["0-65535"] },
      { protocol = "icmp" }
    ]
  }
]
```

### VPC Service Controls

```hcl
# Requires separate VPC Service Controls module
module "vpc_sc" {
  source = "terraform-google-modules/vpc-service-controls/google"
  
  parent_id = var.organization_id
  
  access_levels = [/* ... */]
  
  ingress_policies = [{
    from = {
      sources = [
        { access_level = "*" }
      ]
      identity_type = "ANY_IDENTITY"
    }
    to = {
      resources = ["*"]
      operations = [{
        service_name = "storage.googleapis.com"
        method_selectors = ["*"]
      }]
    }
  }]
  
  egress_policies = [/* ... */]
}
```

### Private Google Access

```hcl
# Enable on subnet level
subnets = [
  {
    name          = "private-subnet"
    ip_cidr_range = "10.0.1.0/24"
    region        = "us-central1"
    private_ip_google_access = true  # Enable here
  }
]

# Enable globally (module default)
enable_private_google_access = true

# Requires no external IPs on instances
# Access Google APIs via private IPs: 199.36.153.4/30
```

**Verify Private Google Access:**
```bash
# From VM without external IP
curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/

# Should succeed even without internet connectivity
```

### Firewall Rules Priority Guidelines

| Priority Range | Use Case |
|---------------|----------|
| 0-999 | Emergency deny rules (block malicious traffic) |
| 1000-4999 | Application-specific rules |
| 5000-5999 | Environment-specific rules (dev/staging/prod) |
| 6000-65534 | General rules |
| 65535 | Default deny rules (implicit) |

## Examples

### Real-World Scenario: GKE with Microservices

```hcl
module "vpc_microservices" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.project_id
  name       = "microservices-vpc"

  subnets = [
    # Frontend/public tier
    {
      name          = "frontend-subnet"
      ip_cidr_range = "10.10.0.0/24"
      region        = "us-central1"
      secondary_ip_ranges = [
        {
          range_name    = "frontend-pods"
          ip_cidr_range = "10.11.0.0/16"
        },
        {
          range_name    = "frontend-services"
          ip_cidr_range = "10.12.0.0/20"
        }
      ]
    },
    
    # Backend/private tier
    {
      name          = "backend-subnet"
      ip_cidr_range = "10.20.0.0/24"
      region        = "us-central1"
      secondary_ip_ranges = [
        {
          range_name    = "backend-pods"
          ip_cidr_range = "10.21.0.0/16"
        },
        {
          range_name    = "backend-services"
          ip_cidr_range = "10.22.0.0/20"
        }
      ]
    },
    
    # Data tier
    {
      name          = "data-subnet"
      ip_cidr_range = "10.30.0.0/24"
      region        = "us-central1"
      private_ip_google_access = true
    }
  ]

  # Cloud NAT for outbound
  enable_cloud_nat = true
  cloud_nat_min_ports_per_vm = 2048
  
  # Private Google Access
  enable_private_google_access = true

  # Firewall rules for security zones
  firewall_rules = [
    # Frontend -> Backend
    {
      name        = "frontend-to-backend"
      direction   = "EGRESS"
      priority    = 2000
      source_ranges = ["10.10.0.0/24"]
      destination_ranges = ["10.20.0.0/24"]
      allow = [{
        protocol = "tcp"
        ports    = ["8080", "9090"]
      }]
    },
    
    # Backend -> Data
    {
      name        = "backend-to-data"
      direction   = "EGRESS"
      priority    = 2000
      source_ranges = ["10.20.0.0/24"]
      destination_ranges = ["10.30.0.0/24"]
      allow = [{
        protocol = "tcp"
        ports    = ["5432", "6379", "9200"]  # PostgreSQL, Redis, Elasticsearch
      }]
    },
    
    # Deny frontend direct data access
    {
      name        = "deny-frontend-to-data"
      direction   = "EGRESS"
      priority    = 1000
      source_ranges = ["10.10.0.0/24"]
      destination_ranges = ["10.30.0.0/24"]
      deny = [{ protocol = "all" }]
    }
  ]
}
```

### Real-World Scenario: Cloud Run with VPC Connector

```hcl
module "vpc_cloudrun" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.project_id
  name       = "cloudrun-vpc"

  subnets = [
    {
      name          = "serverless-subnet"
      ip_cidr_range = "10.8.0.0/28"   # /28 minimum for VPC connectors
      region        = "us-central1"
    }
  ]

  enable_cloud_nat = true
  enable_private_google_access = true

  # Firewall rules for Cloud Run
  firewall_rules = [
    {
      name        = "allow-cloudrun-ingress"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["107.178.230.64/26", "35.199.224.0/19"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443", "8080"]
      }]
    }
  ]
}

# Create VPC connector
resource "google_vpc_access_connector" "connector" {
  name          = "cloudrun-connector"
  region        = "us-central1"
  ip_cidr_range = "10.8.0.0/28"
  network       = module.vpc_cloudrun.network_self_link
  
  depends_on = [module.vpc_cloudrun]
}

# Deploy Cloud Run service
resource "google_cloud_run_service" "service" {
  name     = "internal-api"
  location = "us-central1"
  
  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
    
    spec {
      containers {
        image = "gcr.io/myproject/internal-api:v1"
      }
    }
  }
}
```

### Real-World Scenario: Data Pipeline with Cloud Composer

```hcl
module "vpc_data" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"

  project_id = var.project_id
  name       = "data-pipeline-vpc"

  subnets = [
    {
      name          = "composer-subnet"
      ip_cidr_range = "10.40.0.0/21"      # Large for Composer environment
      region        = "us-central1"
      
      secondary_ip_ranges = [
        {
          range_name    = "composer-pods"
          ip_cidr_range = "10.41.0.0/16"  # GKE-based Composer
        },
        {
          range_name    = "composer-services"
          ip_cidr_range = "10.42.0.0/20"
        }
      ]
      
      private_ip_google_access = true
      enable_flow_logs = true
    },
    {
      name          = "dataflow-subnet"
      ip_cidr_range = "10.43.0.0/24"
      region        = "us-central1"
      private_ip_google_access = true
    },
    {
      name          = "dataproc-subnet"
      ip_cidr_range = "10.44.0.0/24"
      region        = "us-central1"
    }
  ]

  enable_cloud_nat = true
  cloud_nat_min_ports_per_vm = 1024  # Dataflow workers need many ports

  # Firewall for data services
  firewall_rules = [
    {
      name        = "allow-composer-to-dataproc"
      direction   = "EGRESS"
      priority    = 2000
      source_ranges = ["10.40.0.0/21"]
      destination_ranges = ["10.44.0.0/24"]
      allow = [{
        protocol = "tcp"
        ports    = ["8080"]  # Dataproc web interfaces
      }]
    },
    {
      name        = "allow-dataproc-internal"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["10.44.0.0/24"]
      allow = [
        { protocol = "tcp" },
        { protocol = "udp" },
        { protocol = "icmp" }
      ]
        enable_logging = true
    }
  ]
}
```

## Integration

### Working with Other Modules

#### GKE Module Integration
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  name   = "gke-vpc"
  subnets = [{
    name          = "gke-subnet"
    ip_cidr_range = "10.0.1.0/24"
    region        = "us-central1"
    secondary_ip_ranges = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "10.2.0.0/20"
      }
    ]
  }]
}

module "gke_cluster" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/gke?ref=v1.0.0"
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets["gke-subnet"].name
  
  ip_allocation_policy = {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
    cluster_secondary_range_name  = module.vpc.subnets["gke-subnet"].secondary_ip_range[0].range_name
    services_secondary_range_name = module.vpc.subnets["gke-subnet"].secondary_ip_range[1].range_name
  }
}
```

#### Cloud SQL Module Integration
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  name   = "database-vpc"
  subnets = [{
    name          = "database-subnet"
    ip_cidr_range = "10.50.1.0/24"
    region        = "us-central1"
  }]
}

module "cloud_sql" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/cloud-sql?ref=v1.0.0"
  
  network = module.vpc.network_self_link
  
  # Private IP configuration
  ip_configuration = {
    ipv4_enabled        = false
    private_network     = module.vpc.network_self_link
    require_ssl         = true
    authorized_networks = []
  }
  
  depends_on = [module.vpc]  # Ensure VPC created first
}
```

#### Load Balancing Integration
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  name   = "lb-vpc"
  subnets = [
    {
      name          = "proxy-only-subnet"
      ip_cidr_range = "10.100.0.0/24"  # For HTTP(S) load balancers
      region        = "us-central1"
      purpose       = "REGIONAL_MANAGED_PROXY"
    },
    {
      name          = "backend-subnet"
      ip_cidr_range = "10.0.1.0/24"
      region        = "us-central1"
    }
  ]
}

module "lb" {
  source = "terraform-google-modules/lb-http/google"
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets["backend-subnet"].name
}
```

### Network Patterns

#### Hub and Spoke with Shared VPC
```
Hub (Host Project):
- Shared VPC with centralized security
- Cloud NAT for outbound
- VPN/Interconnect for hybrid
- Firewall rule enforcement

Spokes (Service Projects):
- GKE clusters for applications
- Service-specific data stores
- No direct internet access
- VPN access through hub
```

#### Multi-Region Pattern
```hcl
module "vpc_global" {
  subnets = [
    {
      name          = "us-primary-subnet"
      region        = "us-central1"
      ip_cidr_range = "10.0.1.0/24"
    },
    {
      name          = "eu-secondary-subnet"
      region        = "europe-west1"
      ip_cidr_range = "10.0.2.0/24"
    },
    {
      name          = "asia-dr-subnet"
      region        = "asia-northeast1"
      ip_cidr_range = "10.0.3.0/24"
    }
  ]
  
  routing_mode = "GLOBAL"  # Cross-region routing
}
```

#### Production Staging Separation
```hcl
# Production VPC
module "vpc_prod" {
  name = "production-vpc"
  subnets = [{
    name          = "prod-subnet"
    ip_cidr_range = "10.10.0.0/16"
  }]
}

# Staging VPC
module "vpc_staging" {
  name = "staging-vpc"
  subnets = [{
    name          = "staging-subnet"
    ip_cidr_range = "10.20.0.0/16"
  }]
}

# VPC peering for data sync
google_compute_network_peering.prod_to_staging = {
  network      = module.vpc_prod.network_self_link
  peer_network = module.vpc_staging.network_self_link
}
```

## Pricing

### VPC Free Tier
```yaml
VPC Network:
  - VPC creation: Free
  - Subnets: Free
  - Routes: Free
  - Firewall rules: Free
  - VPC Flow Logs: Free
```

### Cloud NAT Pricing
```yaml
NAT Gateway Pricing:
  - Per gateway per zone: $0.0014/hour
  - Example: 1 gateway in us-central1-a = ~$1/month
  
NAT IP Pricing:
  - Auto-allocated IPs: No IP reservation cost
  - Manual IPs: Standard static IP pricing
  
Data Processing:
  - First 1 GB: Free
  - Beyond 1 GB: $0.045/GB (region dependent)
  
Example Costs:
  Small deployment (100GB/month): ~$4.5/month
  Medium deployment (1TB/month): ~$45/month
  Large deployment (10TB/month): ~$450/month
```

### Egress Costs
```yaml
Internal Egress:
  - Same zone: Free
  - Same region, different zone: $0.01/GB
  - Cross-region: $0.01-$0.12/GB (region dependent)

Internet Egress:
  - First 10 TB: $0.12/GB
  - Next 90 TB: $0.11/GB
  - Over 100 TB: $0.08/GB

Special Cases:
  - VPN/Interconnect: Separate pricing
  - Cloud Storage: Different egress rates
  - Cloud CDN: Caching affects egress
```

### Cost Optimization Tips

1. **Reduce NAT Costs**:
   ```hcl
   # Consolidate to single NAT gateway per region
   enable_cloud_nat = true
   cloud_nat_auto_allocate_ips = true  # Avoid manual IP costs
   ```

2. **Minimize Cross-Region Traffic**:
   ```hcl
   # Deploy services in same region as data
   subnet_region = "us-central1"
   gcs_bucket_location = "US-CENTRAL1"
   ```

3. **Use Private Google Access**:
   ```hcl
   # Eliminate NAT costs for GCP API traffic
   enable_private_google_access = true
   ```

4. **Right-Size NAT Ports**:
   ```hcl
   # Don't over-allocate ports
   cloud_nat_min_ports_per_vm = 64  # Standard VMs
   cloud_nat_min_ports_per_vm = 2048  # GKE nodes only
   ```

5. **Monitor with Budget Alerts**:
   ```bash
   gcloud alpha billing budgets create \
     --billing-account=XXXXXX-XXXXXX-XXXXXX \
     --display-name="NAT-Egress-Alert" \
     --budget-amount=100USD \
     --threshold-rule=percent=0.8 \
     --threshold-rule=percent=1.0
   ```

## Troubleshooting

### Common Issues

#### 1. Subnet IP Exhaustion

**Symptoms:**
- Cannot create new instances: `IP_SPACE_EXHAUSTED`
- GKE node pool creation fails
- Error: `Requested range conflicts with allocated ranges`

**Causes:**
- Subnet too small for workload
- GKE secondary ranges exhausted
- No available IPs in region

**Solutions:**
```bash
# Check subnet usage
gcloud compute networks subnets describe my-subnet --region=us-central1 \
  --format="yaml(ipCidrRange,secondaryIpRanges,creationTimestamp)"

# Expand subnet (if not production)
# Note: Cannot shrink, only expand
gcloud compute networks subnets expand-ip-range my-subnet \
  --region=us-central1 \
  --prefix-length=20  # From /24 to /20

# Add new subnet
terraform apply -var='add_additional_subnet=true'
```

**Terraform Fix:**
```hcl
# Add new subnet with larger range
subnets = concat(var.existing_subnets, [{
  name          = "expansion-subnet"
  ip_cidr_range = "10.100.0.0/20"  # 4094 IPs
}])

# For GKE: Add new secondary range
secondary_ip_ranges = concat(var.existing_ranges, [{
  range_name    = "expansion-pods"
  ip_cidr_range = "10.99.0.0/16"
}])
```

#### 2. Cloud NAT Port Exhaustion

**Symptoms:**
- Intermittent connection failures
- `connect()` timeouts
- High `dropped_packets` in monitoring

**Diagnosis:**
```bash
# Check NAT metrics
gcloud compute routers get-status prod-router \
  --region=us-central1 \
  --format="yaml(result.natStatus)"

# Check port usage per VM
gcloud compute routers describe prod-router \
  --region=us-central1 \
  --format="table(nats.name, nats.numVmEndpoints, nats.rules.action)"
```

**Solutions:**
```hcl
# Increase ports per VM
cloud_nat_min_ports_per_vm = 4096  # Was 64

# Add more NAT IPs
cloud_nat_ips = concat(
  google_compute_address.nat-ips-1[*].self_link,
  google_compute_address.nat-ips-2[*].self_link
)

# Reduce TCP timeout to release ports faster
cloud_nat_tcp_established_idle_timeout_sec = 600  # 10 minutes (default 1200)
```

#### 3. Firewall Rule Conflicts

**Symptoms:**
- Traffic blocked unexpectedly
- Rule not taking effect
- Ambiguous deny/allow behavior

**Diagnosis:**
```bash
# List firewall rules with priorities
gcloud compute firewall-rules list \
  --filter="network:my-vpc" \
  --sort-by=~priority \
  --format="table(name,priority,direction,sourceRanges.disabled)"

# Simulate connectivity
 gcloud compute firewall-rules describe suspicious-rule

# Test from VM
gcloud compute ssh vm-instance \
  --command="curl -v http://target:8080"
```

**Solutions:**
```hcl
# Use explicit priorities
firewall_rules = [
  {
    name      = "high-priority-allow"
    priority  = 100  # Lower number = higher priority
    # ...
  },
  {
    name      = "low-priority-deny"
    priority  = 5000
    # ...
  }
]

# Use descriptive rule names
name = "application-tier-to-database-tier-tcp-5432"
```

#### 4. Shared VPC Permission Errors

**Symptoms:**
- Error: `Missing necessary permission compute.networkUser`
- GKE cluster creation fails in service project
- Dataflow jobs fail with network access errors

**Diagnosis:**
```bash
# Check Shared VPC host status
gcloud compute shared-vpc organizations list-host-projects \
  --organization=123456789012

# Verify service project attachment
gcloud compute shared-vpc get-host-project service-project-id

# Check IAM permissions
gcloud projects get-iam-policy host-project-id \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/compute.networkUser" \
  --format="value(bindings.members)"
```

**Solutions:**
```bash
# Fix 1: Enable host project (one time)
gcloud compute shared-vpc enable host-project-id

# Fix 2: Grant networkUser role
gcloud projects add-iam-policy-binding host-project-id \
  --member="serviceAccount:service-SERVICE_PROJECT_NUMBER@compute-system.iam.gserviceaccount.com" \
  --role="roles/compute.networkUser"

# Fix 3: For GKE service account
gcloud projects add-iam-policy-binding host-project-id \
  --member="serviceAccount:service-SERVICE_PROJECT_NUMBER@container-engine-robot.iam.gserviceaccount.com" \
  --role="roles/compute.networkUser"
```

**Terraform:**
```hcl
# Use module's shared VPC IAM management
shared_vpc_subnet_iam = {
  "shared-subnet" = [
    {
      role   = "roles/compute.networkUser"
      member = "serviceAccount:service-${data.google_project.service.number}@compute-system.iam.gserviceaccount.com"
    },
    {
      role   = "roles/compute.networkUser"
      member = "serviceAccount:service-${data.google_project.service.number}@container-engine-robot.iam.gserviceaccount.com"
    }
  ]
}
```

#### 5. Private Google Access Issues

**Symptoms:**
- Cannot access Google APIs from private instances
- `curl metadata.google.internal` fails
- GCS bucket access denied

**Diagnosis:**
```bash
# Verify Private Google Access enabled
gcloud compute networks subnets describe my-subnet \
  --region=us-central1 \
  --format="value(privateIpGoogleAccess)"

# Test connectivity
gcloud compute ssh private-vm \
  --command="curl -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/"

# Check DNS resolution
nslookup storage.googleapis.com
# Should resolve to 199.36.153.x for Private Google Access
```

**Solutions:**
```hcl
# Enable Private Google Access
enable_private_google_access = true

# Or enable per subnet
subnets = [{
  private_ip_google_access = true
}]
```

```bash
# Reserve public IPs (required for some services)
gcloud compute addresses create reserved-ip \
  --region=us-central1

# Use in NAT configuration
terraform apply -var='cloud_nat_ips=["projects/my-project/regions/us-central1/addresses/reserved-ip"]'
```

### Debug Commands

```bash
# Network connectivity test
gcloud compute networks vpc-access connectors describe my-connector --region=us-central1

# View VPC routing table
gcloud compute routes list --filter="network:my-vpc" --limit=20

# Check subnet capacity
gcloud compute networks subnets list-usable my-subnet --region=us-central1

# Monitor NAT in real-time
gcloud logging read "resource.type=nat_gateway" --limit=10 --format=json
```

## References

### Google Cloud Documentation
- [VPC Overview](https://cloud.google.com/vpc/docs/overview)
- [VPC Subnet Management](https://cloud.google.com/vpc/docs/vpc)
- [Cloud NAT Documentation](https://cloud.google.com/nat/docs/overview)
- [Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc)
- [GKE VPC-Native Clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips)
- [VPC Service Controls](https://cloud.google.com/vpc-service-controls)

### Terraform Providers
- [Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Google Beta Provider](https://registry.terraform.io/providers/hashicorp/google-beta/latest)

### Related Modules
- [GKE Module](https://github.com/company/terraform-modules/tree/main/gcp/gke)
- [Cloud SQL Module](https://github.com/company/terraform-modules/tree/main/gcp/cloud-sql)
- [Load Balancing Module](https://github.com/company/terraform-modules/tree/main/gcp/load-balancing)
- [VPC Service Controls Module](https://github.com/terraform-google-modules/terraform-google-vpc-service-controls)
- [Cloud Router Module](https://github.com/terraform-google-modules/terraform-google-cloud-router)

### Best Practices Guides
- [GCP Network Design](https://cloud.google.com/architecture/building-scalable-and-secure-network-architecture)
- [GKE Network Security](https://cloud.google.com/kubernetes-engine/docs/concepts/network-overview)
- [Cost Optimization](https://cloud.google.com/architecture/framework/cost-optimization)
- [Enterprise Foundations](https://github.com/terraform-google-modules/terraform-example-foundation)

### API References
- [Compute API - Networks](https://cloud.google.com/compute/docs/reference/rest/v1/networks)
- [Compute API - Subnetworks](https://cloud.google.com/compute/docs/reference/rest/v1/subnetworks)
- [Compute API - Firewalls](https://cloud.google.com/compute/docs/reference/rest/v1/firewalls)
- [Cloud NAT API](https://cloud.google.com/compute/docs/reference/rest/v1/routers)

### Community Resources
- [Google Cloud Community](https://www.googlecloudcommunity.com/)
- [Terraform Google Modules](https://github.com/terraform-google-modules)
- [GitHub Issues](https://github.com/company/terraform-modules/issues)
- [Architecture Center Patterns](https://cloud.google.com/architecture)
