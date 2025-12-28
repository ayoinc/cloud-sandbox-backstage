# GCP GKE Module

Creates a production-ready Google Kubernetes Engine cluster with node pools, Workload Identity, and security hardening following GKE best practices.

## Features

- Regional or zonal cluster deployment
- Release channel management
- Managed node pools with autoscaling
- Workload Identity for pod authentication
- Network policy (Calico)
- Private cluster support
- Shielded GKE nodes
- Binary Authorization support
- Managed Prometheus monitoring
- GCS Fuse and Persistent Disk CSI drivers

## Usage

### Basic Usage

```hcl
module "gke" {
  source = "../../../gcp/resources/kubernetes/gke"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_self_links["gke"]
}
```

### Production Configuration

```hcl
module "gke" {
  source = "../../../gcp/resources/kubernetes/gke"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"

  network             = module.vpc.network_name
  subnetwork          = module.vpc.subnet_self_links["gke"]
  pods_range_name     = "pods"
  services_range_name = "services"

  release_channel = "REGULAR"

  # Private cluster
  enable_private_nodes    = true
  enable_private_endpoint = false
  master_ipv4_cidr_block  = "172.16.0.0/28"

  master_authorized_networks = [
    {
      display_name = "Office"
      cidr_block   = "203.0.113.0/24"
    }
  ]

  # Security
  enable_workload_identity     = true
  enable_network_policy        = true
  enable_binary_authorization  = true
  enable_shielded_nodes        = true

  node_pools = {
    general = {
      machine_type       = "n2-standard-4"
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      image_type         = "COS_CONTAINERD"
      initial_node_count = 1
      min_count          = 2
      max_count          = 10
      labels = {
        workload = "general"
      }
    }
    spot = {
      machine_type = "n2-standard-4"
      disk_size_gb = 50
      spot         = true
      min_count    = 0
      max_count    = 20
      labels = {
        workload = "batch"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  maintenance_start_time = "03:00"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"

  labels = {
    team = "platform"
  }
}
```

### Development Configuration

```hcl
module "gke" {
  source = "../../../gcp/resources/kubernetes/gke"

  project_id  = "my-dev-project"
  name        = "myapp"
  environment = "dev"
  region      = "us-central1"
  zones       = ["us-central1-a"]  # Single zone for cost savings

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_self_links["default"]

  release_channel = "RAPID"

  node_pools = {
    default = {
      machine_type = "e2-medium"
      disk_size_gb = 50
      spot         = true
      min_count    = 1
      max_count    = 3
    }
  }

  enable_network_policy       = false
  enable_binary_authorization = false
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | GCP Project ID | `string` | - | Yes |
| `name` | Name prefix for resources | `string` | - | Yes |
| `environment` | Environment (dev, staging, prod) | `string` | - | Yes |
| `region` | GCP region | `string` | `"us-central1"` | No |
| `zones` | Zones (empty for regional) | `list(string)` | `[]` | No |
| `network` | VPC network name | `string` | - | Yes |
| `subnetwork` | Subnetwork name | `string` | - | Yes |
| `pods_range_name` | Secondary range for pods | `string` | `null` | No |
| `services_range_name` | Secondary range for services | `string` | `null` | No |
| `release_channel` | Release channel (RAPID, REGULAR, STABLE) | `string` | `"REGULAR"` | No |
| `enable_private_nodes` | Enable private nodes | `bool` | `true` | No |
| `enable_private_endpoint` | Enable private endpoint | `bool` | `false` | No |
| `master_ipv4_cidr_block` | Master CIDR block | `string` | `"172.16.0.0/28"` | No |
| `enable_workload_identity` | Enable Workload Identity | `bool` | `true` | No |
| `enable_network_policy` | Enable network policy | `bool` | `true` | No |
| `node_pools` | Node pool configurations | `map(object)` | See below | No |
| `labels` | Labels to apply | `map(string)` | `{}` | No |

### Node Pool Configuration

```hcl
node_pools = {
  pool_name = {
    machine_type       = "n2-standard-4"
    disk_size_gb       = 100
    disk_type          = "pd-standard"    # pd-standard, pd-ssd, pd-balanced
    image_type         = "COS_CONTAINERD"
    initial_node_count = 1
    min_count          = 1
    max_count          = 10
    preemptible        = false
    spot               = false
    labels             = {}
    taints = [{
      key    = "dedicated"
      value  = "gpu"
      effect = "NO_SCHEDULE"
    }]
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | GKE cluster ID |
| `cluster_name` | GKE cluster name |
| `cluster_endpoint` | GKE cluster endpoint (sensitive) |
| `cluster_ca_certificate` | Cluster CA certificate (sensitive) |
| `cluster_location` | Cluster location |
| `cluster_master_version` | Kubernetes version |
| `node_pools` | List of node pool names |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      GKE Cluster                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  Control Plane                          │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐    │  │
│  │  │   API   │  │  etcd   │  │  Controller Manager │    │  │
│  │  │ Server  │  │         │  │     + Scheduler     │    │  │
│  │  └─────────┘  └─────────┘  └─────────────────────┘    │  │
│  │                                                         │  │
│  │  Master CIDR: 172.16.0.0/28 (Private)                  │  │
│  └────────────────────────────────────────────────────────┘  │
│                              │                                │
│                    ┌─────────┴─────────┐                     │
│                    │ Workload Identity │                     │
│                    │   (OIDC Provider) │                     │
│                    └───────────────────┘                     │
└──────────────────────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────┴───────┐      ┌───────┴───────┐      ┌───────┴───────┐
│  Node Pool    │      │  Node Pool    │      │  Node Pool    │
│   (general)   │      │    (spot)     │      │    (gpu)      │
│               │      │               │      │               │
│ n2-standard-4 │      │ n2-standard-4 │      │ n1-standard-8 │
│   2-10 nodes  │      │   0-20 nodes  │      │  + GPU        │
│               │      │               │      │               │
│ ┌───┐ ┌───┐  │      │ ┌───┐ ┌───┐  │      │ ┌───┐ ┌───┐  │
│ │Pod│ │Pod│  │      │ │Pod│ │Pod│  │      │ │Pod│ │Pod│  │
│ └───┘ └───┘  │      │ └───┘ └───┘  │      │ └───┘ └───┘  │
└───────────────┘      └───────────────┘      └───────────────┘
```

## Security Features

### Workload Identity

Secure pod authentication to Google Cloud services:

```hcl
# Enable on cluster
enable_workload_identity = true

# Configure service account binding
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[namespace/ksa-name]"
  ]
}
```

### Network Policy

Calico network policy for pod-level firewall:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Shielded Nodes

- Secure Boot enabled
- Integrity Monitoring enabled
- Legacy instance metadata disabled

### Binary Authorization

Enforce container image signing policies.

## Add-ons

### Default Add-ons (Enabled)

| Add-on | Purpose |
|--------|---------|
| HTTP Load Balancing | Ingress controller |
| Horizontal Pod Autoscaler | Pod autoscaling |
| GCE Persistent Disk CSI | Persistent volumes |
| GCS Fuse CSI | Cloud Storage mounting |
| Managed Prometheus | Metrics collection |

## Connecting to Cluster

```bash
# Get credentials
gcloud container clusters get-credentials myapp-prod-gke \
  --region us-central1 \
  --project my-project

# Verify connection
kubectl get nodes
```

## Cost Considerations

| Component | Cost Factor |
|-----------|-------------|
| Control Plane | Free (Standard), ~$73/month (Autopilot) |
| Node Pools | GCE instance pricing |
| Network | Egress charges |
| Cloud NAT | Per VM + data processing |

**Tips:**
- Use Spot VMs for fault-tolerant workloads (60-91% discount)
- Use E2 machine types for cost-effective general workloads
- Consider regional clusters for production (3x control plane)
- Use cluster autoscaler to right-size node pools
