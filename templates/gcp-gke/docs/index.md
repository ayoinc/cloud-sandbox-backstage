# GCP GKE Cluster Template

This template creates a Google Kubernetes Engine (GKE) cluster with enterprise-ready configurations using Terraform.

## Overview

GKE is a managed Kubernetes service that provides a production-ready environment for containerized applications. This template supports both Autopilot and Standard modes.

## Features

### Cluster Modes

#### Autopilot Mode (Recommended)

- Fully managed node infrastructure
- Automatic scaling and node management
- Optimized resource utilization
- Built-in security hardening

#### Standard Mode

- Custom node pool configurations
- Fine-grained control over resources
- Support for specialized workloads
- GPU and TPU support

### Configuration Options

| Parameter     | Description                        | Default       |
| ------------- | ---------------------------------- | ------------- |
| `clusterMode` | Autopilot or Standard              | autopilot     |
| `machineType` | Node machine type (Standard mode)  | e2-standard-2 |
| `nodeCount`   | Initial node count (Standard mode) | 3             |
| `region`      | GCP region                         | us-central1   |

### Security Features

- Workload Identity enabled by default
- Shielded GKE Nodes
- Network policies support
- Binary Authorization ready
- Private cluster option

## Getting Started

### Prerequisites

- GCP project with billing enabled
- GKE API enabled
- Terraform >= 1.0
- kubectl installed

### Deployment

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Configure variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Apply the configuration**

   ```bash
   terraform apply
   ```

4. **Configure kubectl**
   ```bash
   gcloud container clusters get-credentials CLUSTER_NAME --region=REGION
   ```

### Verify Cluster

```bash
# Check cluster status
kubectl cluster-info

# View nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

## Architecture

```d2
direction: right

internet: Internet {
  style.fill: "#e3f2fd"
}

cluster: GKE Cluster {
  style.fill: "#f5f5f5"

  control-plane: Control Plane (Managed by GCP) {
    style.fill: "#c8e6c9"
  }

  node1: Node {
    style.fill: "#b3e5fc"
  }

  node2: Node {
    style.fill: "#b3e5fc"
  }

  node3: Node {
    style.fill: "#b3e5fc"
  }

  control-plane -> node1
  control-plane -> node2
  control-plane -> node3
}

internet -> cluster.control-plane
```

## Workload Identity

Workload Identity allows your Kubernetes workloads to access Google Cloud services securely:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    iam.gke.io/gcp-service-account: my-gcp-sa@PROJECT.iam.gserviceaccount.com
```

## Monitoring and Logging

The cluster is configured with:

- Cloud Operations for GKE (formerly Stackdriver)
- Managed Prometheus for metrics
- Cloud Logging for centralized logs

## Cost Optimization

- Use Autopilot for automatic bin packing
- Configure cluster autoscaler appropriately
- Use preemptible/spot VMs for fault-tolerant workloads
- Right-size your node machine types

## Related Templates

- [GCP Cloud Run](../gcp-cloud-run) - For serverless container workloads
- [GCP VPC Network](../gcp-vpc) - For custom networking
- [Kubernetes Microservice](../kubernetes-microservice) - For deploying services to GKE
