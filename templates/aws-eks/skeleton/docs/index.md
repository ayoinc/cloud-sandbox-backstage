# ${{ values.name }}

${{ values.description }}

## Overview

This EKS cluster is managed by Terraform for the **${{ values.environment }}** environment.

## Configuration

| Setting            | Value                           |
| ------------------ | ------------------------------- |
| Kubernetes Version | ${{ values.kubernetesVersion }} |
| Node Instance Type | ${{ values.nodeInstanceType }}  |
| Desired Nodes      | ${{ values.nodeDesiredSize }}   |
| Max Nodes          | ${{ values.nodeMaxSize }}       |
| Region             | ${{ values.region }}            |

## Getting Started

### Configure kubectl

```bash
aws eks update-kubeconfig --region ${{ values.region }} --name ${{ values.name }}-${{ values.environment }}
```

### Verify Connection

```bash
kubectl get nodes
kubectl get namespaces
```

### Deploy an Application

```bash
kubectl create namespace my-app
kubectl apply -f deployment.yaml -n my-app
```

## Features

- **Managed Node Groups**: Auto-scaling worker nodes
- **IRSA**: IAM Roles for Service Accounts enabled
- **Cluster Autoscaler Ready**: Nodes scale based on demand
- **Private Endpoint**: Control plane is in private subnets
- **Logging**: All control plane logs sent to CloudWatch

## Security

- Nodes run in private subnets
- Control plane endpoint is private (production) or public (dev/staging)
- OIDC provider configured for pod-level IAM

## Owner

This resource is owned by **${{ values.owner }}**.
