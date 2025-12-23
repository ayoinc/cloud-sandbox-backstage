# AWX Operator

Kubernetes Operator for deploying and managing AWX instances using the Operator pattern for automated lifecycle management.

## Quick Start

```bash
# Install AWX Operator using kubectl
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/2.12.0/deploy/awx-operator.yaml

# Create namespace
kubectl create namespace awx

# Deploy AWX Operator
kubectl apply -k github.com/ansible/awx-operator/config/default?ref=2.12.0

# Verify operator is running
kubectl get pods -n awx -l control-plane=controller-manager

# Create AWX instance
cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
EOF

# Watch deployment progress
kubectl get awx -n awx -w

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d
```

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Declarative Management** | Define AWX state via CRDs | GitOps-friendly |
| **Automated Upgrades** | Seamless version upgrades | Zero-downtime updates |
| **Self-Healing** | Automatic pod recovery | High availability |
| **Scaling** | Horizontal pod scaling | Handle load increases |
| **Backup/Restore** | Built-in backup CRD | Disaster recovery |
| **External DB Support** | Connect to existing PostgreSQL | Enterprise integration |
| **TLS Management** | Automatic certificate handling | Secure by default |
| **Resource Tuning** | Fine-grained resource control | Optimized performance |

## Custom Resource Definitions

| CRD | API Version | Purpose |
|-----|-------------|---------|
| **AWX** | awx.ansible.com/v1beta1 | AWX instance deployment |
| **AWXBackup** | awx.ansible.com/v1beta1 | Database and secret backup |
| **AWXRestore** | awx.ansible.com/v1beta1 | Restore from backup |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       AWX Operator Architecture                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Kubernetes API Server                        │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │    Custom Resource Definitions (CRDs)                   │   │     │
│  │  │    - AWX                                                 │   │     │
│  │  │    - AWXBackup                                          │   │     │
│  │  │    - AWXRestore                                         │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│                                    │ Watch/Reconcile                     │
│                                    ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    AWX Operator Controller                      │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │ AWX         │  │ Backup      │  │ Restore             │    │     │
│  │  │ Controller  │  │ Controller  │  │ Controller          │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│                                    │ Creates/Manages                     │
│                                    ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Managed Resources                            │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │ Deployments │  │ Services    │  │ ConfigMaps/Secrets  │    │     │
│  │  │ StatefulSet │  │ Ingress     │  │ PVCs                │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Operator Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                     Reconciliation Loop                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   1. Watch for Changes                                            │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  - AWX CR created/updated/deleted                       │    │
│   │  - Child resources changed                               │    │
│   │  - Periodic requeue                                      │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│   2. Reconcile              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  - Compare desired state (CR spec) with actual state    │    │
│   │  - Create missing resources                              │    │
│   │  - Update changed resources                              │    │
│   │  - Delete orphaned resources                             │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│   3. Update Status          ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  - Set conditions (Ready, Progressing, Degraded)        │    │
│   │  - Update observed generation                            │    │
│   │  - Record events                                         │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| AWX Operator | 2.12+ | Latest stable |
| Kubernetes | 1.24+ | Required |
| Kustomize | 5.0+ | For installation |
| AWX | 24.0+ | Deployed version |

## Installation Methods

| Method | Best For | Command |
|--------|----------|---------|
| **Kustomize** | Direct install | `kubectl apply -k` |
| **Helm** | Package management | `helm install` |
| **OLM** | OpenShift/OLM clusters | OperatorHub |
| **Manual** | Air-gapped environments | YAML manifests |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and CRD reference
- [Usage](usage.md) - Deployment examples and operations
