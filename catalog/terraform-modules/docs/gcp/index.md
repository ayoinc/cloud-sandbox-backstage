# GCP Modules

Enterprise-grade Google Cloud infrastructure modules following GCP best practices and Cloud Architecture Framework.

## Available Modules

| Module                            | Description              | Key Features                                   |
| --------------------------------- | ------------------------ | ---------------------------------------------- |
| [VPC](vpc.md)                     | Virtual Private Cloud    | Subnets, Cloud NAT, Firewall rules             |
| [GKE](gke.md)                     | Google Kubernetes Engine | Node pools, Workload Identity, Private cluster |
| [Cloud Storage](cloud-storage.md) | Object Storage           | Versioning, Lifecycle, Encryption              |
| [Cloud SQL](cloud-sql.md)         | Managed Database         | HA, Point-in-time recovery, Query Insights     |

## Architecture Patterns

### Standard Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      VPC Network                            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Cloud Load Balancer                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Subnet    │  │   Subnet    │  │   Subnet    │        │
│  │  (GKE/GCE)  │  │  (GKE/GCE)  │  │  (GKE/GCE)  │        │
│  │  us-central1│  │  us-east1   │  │  us-west1   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                │                │                │
│         └────────────────┼────────────────┘                │
│                          │                                 │
│              ┌───────────┴───────────┐                    │
│              │       Cloud NAT       │                    │
│              └───────────────────────┘                    │
│                          │                                 │
│              ┌───────────┴───────────┐                    │
│              │      Cloud SQL        │                    │
│              │   (Private Service)   │                    │
│              └───────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Provider Requirements

All GCP modules require:

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}
```

## Security Best Practices

### Identity & Access

- Workload Identity for GKE pods
- Service accounts with least-privilege
- IAM Conditions for fine-grained access
- No service account keys

### Network Security

- Private Google Access enabled
- Cloud NAT for outbound traffic
- VPC Service Controls (optional)
- IAP for administrative access

### Data Protection

- Customer-managed encryption keys (CMEK)
- VPC-native networking
- Private services access
- SSL/TLS enforcement

## Project Structure

Recommended project organization:

```
projects/
├── prod-networking/     # Shared VPC host project
├── prod-gke/           # GKE workloads
├── prod-data/          # Databases and storage
└── prod-security/      # Security resources
```

## Labels Strategy

All modules apply consistent labels:

```hcl
labels = {
  environment = var.environment
  managed_by  = "terraform"
  project     = var.name
  cost_center = "infrastructure"
}
```

## Cost Optimization

### Development Environments

```hcl
# Use preemptible/spot VMs
preemptible = true
spot        = true

# Smaller machine types
tier         = "db-f1-micro"
machine_type = "e2-small"

# Single zone
availability_type = "ZONAL"
```

### Production Environments

```hcl
# Standard VMs
preemptible = false

# Right-sized instances
tier         = "db-custom-4-16384"
machine_type = "n2-standard-4"

# Regional HA
availability_type = "REGIONAL"
```

## Related Resources

- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
