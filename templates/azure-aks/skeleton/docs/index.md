# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Kubernetes Service (AKS) cluster is managed by Terraform for the **${{ values.environment }}** environment.

## Configuration

| Setting            | Value                           |
| ------------------ | ------------------------------- |
| Kubernetes Version | ${{ values.kubernetesVersion }} |
| Node VM Size       | ${{ values.nodeVmSize }}        |
| Initial Node Count | ${{ values.nodeCount }}         |
| Max Node Count     | ${{ values.maxNodeCount }}      |
| Location           | ${{ values.location }}          |

## Features

- **Azure RBAC**: Integrated with Azure Active Directory
- **Container Registry**: Private ACR included with AcrPull permissions
- **Monitoring**: Log Analytics workspace with diagnostics enabled
- **Autoscaling**: Cluster autoscaler configured
- **Network Policy**: Calico enabled for pod-level security
- **Dual Node Pools**: System pool and User pool for workload isolation

## Getting Started

### Get Credentials

```bash
az aks get-credentials \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --name aks-${{ values.name }}-${{ values.environment }}
```

### Verify Connection

```bash
kubectl get nodes
kubectl get namespaces
```

### Push Image to ACR

```bash
# Login to ACR
az acr login --name acr${{ values.name }}${{ values.environment }}

# Tag and push
docker tag myapp:latest acr${{ values.name }}${{ values.environment }}.azurecr.io/myapp:latest
docker push acr${{ values.name }}${{ values.environment }}.azurecr.io/myapp:latest
```

### Deploy Application

```bash
kubectl create namespace my-app
kubectl apply -f deployment.yaml -n my-app
```

## Node Pools

| Pool   | Purpose                          | Taints |
| ------ | -------------------------------- | ------ |
| system | System workloads (CoreDNS, etc.) | None   |
| user   | Application workloads            | None   |

## Monitoring

Access logs and metrics via Azure Portal or query Log Analytics:

```kusto
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error"
| project TimeGenerated, LogEntry, ContainerID
```

## Owner

This resource is owned by **${{ values.owner }}**.
