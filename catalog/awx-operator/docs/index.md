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

```d2
direction: down

title: Kubernetes Operator Pattern - AWX Operator {
  shape: text
  near: top-center
  style: {
    font-size: 24
    bold: true
  }
}

k8s_api: Kubernetes API Server {
  style.fill: "#e3f2fd"
  
  crds: Custom Resource Definitions (CRDs) {
    style.fill: "#bbdefb"
    awx_crd: AWX {
      shape: document
      style.fill: "#90caf9"
    }
    backup_crd: AWXBackup {
      shape: document
      style.fill: "#90caf9"
    }
    restore_crd: AWXRestore {
      shape: document
      style.fill: "#90caf9"
    }
  }
}

operator: AWX Operator Controller {
  style.fill: "#e8f5e9"
  
  awx_controller: AWX\nController {
    shape: hexagon
    style.fill: "#a5d6a7"
  }
  backup_controller: Backup\nController {
    shape: hexagon
    style.fill: "#a5d6a7"
  }
  restore_controller: Restore\nController {
    shape: hexagon
    style.fill: "#a5d6a7"
  }
}

reconcile_loop: Reconciliation Loop {
  style.fill: "#fff3e0"
  
  watch: Watch for Changes {
    shape: rectangle
    style.fill: "#ffe0b2"
  }
  compare: Compare Desired\nvs Actual State {
    shape: diamond
    style.fill: "#ffcc80"
  }
  apply: Apply Changes {
    shape: rectangle
    style.fill: "#ffb74d"
  }
  
  watch -> compare -> apply
  apply -> watch: Requeue
}

managed_resources: Managed Resources {
  style.fill: "#f3e5f5"
  
  workloads: Workloads {
    style.fill: "#e1bee7"
    deployment: Deployments {
      shape: rectangle
    }
    statefulset: StatefulSets {
      shape: rectangle
    }
  }
  
  networking: Networking {
    style.fill: "#e1bee7"
    services: Services {
      shape: rectangle
    }
    ingress: Ingress {
      shape: rectangle
    }
  }
  
  config: Configuration {
    style.fill: "#e1bee7"
    configmaps: ConfigMaps {
      shape: rectangle
    }
    secrets: Secrets {
      shape: rectangle
    }
    pvcs: PVCs {
      shape: cylinder
    }
  }
}

awx_instance: AWX Instance {
  style.fill: "#c8e6c9"
  
  web: AWX Web {
    shape: rectangle
  }
  task: AWX Task {
    shape: rectangle
  }
  postgres: PostgreSQL {
    shape: cylinder
  }
  redis: Redis {
    shape: cylinder
  }
}

k8s_api.crds -> operator: Watch/Reconcile
operator -> reconcile_loop: Execute
operator.awx_controller -> managed_resources: Creates/Manages
operator.backup_controller -> managed_resources
operator.restore_controller -> managed_resources
managed_resources -> awx_instance: Deploys
```

## Operator Lifecycle

```d2
direction: down

reconciliation: Reconciliation Loop {
  watch: 1. Watch for Changes {
    cr_changes: AWX CR created/updated/deleted
    child_changes: Child resources changed
    requeue: Periodic requeue
  }
  
  reconcile: 2. Reconcile {
    compare: Compare desired state (CR spec) with actual state
    create: Create missing resources
    update: Update changed resources
    delete: Delete orphaned resources
  }
  
  status: 3. Update Status {
    conditions: Set conditions (Ready, Progressing, Degraded)
    generation: Update observed generation
    events: Record events
  }
  
  watch -> reconcile -> status
  status -> watch: requeue {
    style.stroke-dash: 3
  }
}
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
