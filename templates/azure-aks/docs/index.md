# Azure AKS Cluster Template

This template creates an Azure Kubernetes Service (AKS) cluster with production configurations.

## Features

- **Managed Kubernetes** - Azure-managed control plane
- **Node pools** - System and user node pools
- **Azure CNI** - Advanced networking
- **Azure AD integration** - RBAC with Azure AD
- **Container Insights** - Monitoring and logging
- **Auto-scaling** - Cluster and pod autoscaling

## Prerequisites

- Azure Subscription
- Terraform >= 1.5
- Azure CLI
- kubectl

## Quick Start

```bash
# Initialize and apply
terraform init
terraform apply

# Get credentials
az aks get-credentials --resource-group <rg> --name <cluster>

# Verify connection
kubectl get nodes
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | AKS cluster name | - |
| `kubernetes_version` | K8s version | `1.28` |
| `node_count` | Default node count | `3` |
| `vm_size` | Node VM size | `Standard_D2s_v3` |

## Outputs

- `cluster_id` - AKS cluster resource ID
- `kube_config` - Kubeconfig for kubectl
- `host` - Kubernetes API server URL

## Support

Contact the Platform Team for assistance.
