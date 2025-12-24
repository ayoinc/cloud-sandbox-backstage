# GCP VPC Network Template

This template creates a Virtual Private Cloud (VPC) network on Google Cloud Platform with subnets, firewall rules, Cloud NAT, and Cloud Router using Terraform.

## Overview

A VPC provides networking functionality for your cloud resources. This template creates a production-ready network foundation with security best practices.

## Features

### Network Components

- Custom mode VPC network
- Regional subnets with secondary ranges
- Cloud Router for dynamic routing
- Cloud NAT for outbound internet access
- Firewall rules with proper segmentation

### Configuration Options

| Parameter     | Description            | Default     |
| ------------- | ---------------------- | ----------- |
| `cidrRange`   | Primary CIDR block     | 10.0.0.0/16 |
| `region`      | GCP region             | us-central1 |
| `environment` | Deployment environment | development |

### Subnet Design

The template creates the following subnets:

| Subnet  | Purpose                       | CIDR Range |
| ------- | ----------------------------- | ---------- |
| Public  | Load balancers, bastion hosts | /24        |
| Private | Application workloads         | /20        |
| Data    | Databases, internal services  | /22        |

## Getting Started

### Prerequisites

- GCP project with billing enabled
- Compute Engine API enabled
- Terraform >= 1.0

### Deployment

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Review the plan**

   ```bash
   terraform plan
   ```

3. **Apply the configuration**
   ```bash
   terraform apply
   ```

### Verify Network

```bash
# List VPC networks
gcloud compute networks list

# View subnets
gcloud compute networks subnets list --network=VPC_NAME

# Check firewall rules
gcloud compute firewall-rules list --filter="network=VPC_NAME"
```

## Architecture

```d2
direction: down

vpc: VPC Network {
  style.fill: "#e3f2fd"

  public: Public Subnet (/24) {
    style.fill: "#c8e6c9"
    label: "Public Subnet\n/24\n- LB\n- NAT GW\n- Bastion"
  }

  private: Private Subnet (/20) {
    style.fill: "#b3e5fc"
    label: "Private Subnet\n/20\n- Apps\n- GKE\n- VMs"
  }

  data: Data Subnet (/22) {
    style.fill: "#fff3e0"
    label: "Data Subnet\n/22\n- DBs\n- Redis\n- Internal"
  }

  router: Cloud Router + NAT {
    style.fill: "#f3e5f5"
  }

  public -> router
  private -> router
  data -> router
}

internet: Internet {
  style.fill: "#ffcdd2"
}

vpc.router -> internet
```

## Firewall Rules

The template configures layered firewall rules:

### Ingress Rules

- Allow HTTPS (443) from internet to load balancers
- Allow internal communication between subnets
- Allow SSH from IAP for secure bastion access

### Egress Rules

- Allow outbound to internet via Cloud NAT
- Allow internal subnet communication
- Deny direct internet egress from private subnets

## Cloud NAT Configuration

Cloud NAT provides outbound internet access for private instances:

```hcl
resource "google_compute_router_nat" "nat" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

## Private Google Access

Private Google Access is enabled on all subnets, allowing VMs without external IPs to access Google APIs and services.

## Security Best Practices

1. **Least Privilege**: Firewall rules are specific to required ports
2. **Defense in Depth**: Multiple security layers
3. **Logging**: VPC Flow Logs enabled for monitoring
4. **Private Access**: Resources in private subnets by default

## Related Templates

- [GCP GKE Cluster](../gcp-gke) - Deploy Kubernetes in this VPC
- [GCP Cloud Run](../gcp-cloud-run) - Connect Cloud Run via VPC connector
