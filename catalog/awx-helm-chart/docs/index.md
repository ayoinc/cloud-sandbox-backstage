# AWX Helm Chart

Helm chart for deploying AWX (Ansible Web eXecutive) on Kubernetes clusters with production-ready configurations, high availability support, and seamless integration with the AWX Operator.

## Quick Start

```bash
# Add the AWX community Helm repository
helm repo add awx-community https://ansible.github.io/awx-operator/
helm repo update

# Create namespace
kubectl create namespace awx

# Install AWX using Helm (installs AWX Operator + AWX instance)
helm install awx awx-community/awx-operator \
  --namespace awx \
  --set AWX.enabled=true \
  --set AWX.name=awx \
  --set AWX.spec.admin_user=admin

# Watch the deployment
kubectl get pods -n awx -w

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d

# Access AWX (port-forward for testing)
kubectl port-forward svc/awx-service 8080:80 -n awx
# Open http://localhost:8080
```

## Features

| Feature                      | Description                                     | Status    |
| ---------------------------- | ----------------------------------------------- | --------- |
| **AWX Operator Integration** | Deploys and manages AWX via Kubernetes Operator | ✅ Stable |
| **High Availability**        | Multi-replica web and task pods                 | ✅ Stable |
| **PostgreSQL Options**       | Managed or external PostgreSQL database         | ✅ Stable |
| **Redis Clustering**         | Built-in Redis for task queuing                 | ✅ Stable |
| **Ingress Support**          | NGINX, Traefik, ALB ingress controllers         | ✅ Stable |
| **TLS/HTTPS**                | Automatic cert-manager integration              | ✅ Stable |
| **Persistent Storage**       | Projects, logs, and EE images persistence       | ✅ Stable |
| **Resource Management**      | CPU/memory limits and requests                  | ✅ Stable |
| **LDAP/SAML/OAuth**          | Enterprise authentication backends              | ✅ Stable |
| **Execution Environments**   | Custom container images for jobs                | ✅ Stable |
| **Backup/Restore**           | AWXBackup and AWXRestore CRDs                   | ✅ Stable |
| **Auto-scaling**             | HPA for web pods                                | ✅ Stable |

## Architecture

```d2
direction: down

cluster: Kubernetes Cluster {
  helm: AWX Helm Chart {
    operator: AWX Operator (Deployment) {
      shape: hexagon
      watch: Watch AWX CRs
      reconcile: Reconcile
      manage: Manage deps
    }

    awx: AWX Instance {
      web: Web Pods (nginx)
      task: Task Pods (celery)
      redis: Redis (Task Queue) {
        shape: cylinder
      }
      web -> redis
      task -> redis
    }

    operator -> awx: manages
  }

  data: Data Layer {
    postgres: PostgreSQL (StatefulSet) {
      shape: cylinder
    }
    projects: PVC Projects (ReadWriteMany) {
      shape: cylinder
    }
    ee: PVC EE Images Cache {
      shape: cylinder
    }
  }

  ingress_layer: Ingress Layer {
    ingress: Ingress/Route (TLS termination)
    service: AWX Service (ClusterIP)
    ingress -> service
  }

  helm.awx -> data
  ingress_layer.service -> helm.awx
}
```

## Chart Structure

```
awx-helm-chart/
├── Chart.yaml                 # Chart metadata and dependencies
├── values.yaml                # Default configuration values
├── values-production.yaml     # Production overrides
├── values-development.yaml    # Development overrides
├── templates/
│   ├── _helpers.tpl           # Template helper functions
│   ├── namespace.yaml         # Namespace creation (optional)
│   ├── awx-operator/
│   │   ├── deployment.yaml    # Operator deployment
│   │   ├── rbac.yaml          # ServiceAccount, Role, RoleBinding
│   │   └── service.yaml       # Operator metrics service
│   ├── awx-instance/
│   │   ├── awx.yaml           # AWX custom resource
│   │   ├── secrets.yaml       # Admin password, DB credentials
│   │   ├── configmap.yaml     # Extra settings, custom CA
│   │   └── pvc.yaml           # Persistent volume claims
│   ├── ingress.yaml           # Ingress resource
│   ├── network-policy.yaml    # Network policies
│   └── tests/
│       └── test-connection.yaml
├── crds/
│   ├── awx-crd.yaml           # AWX CRD definition
│   ├── awxbackup-crd.yaml     # AWXBackup CRD
│   └── awxrestore-crd.yaml    # AWXRestore CRD
└── ci/
    ├── ct.yaml                # Chart testing config
    └── test-values.yaml       # CI test values
```

## Version Compatibility

| Chart Version | AWX Operator | AWX Version | Kubernetes | Helm  |
| ------------- | ------------ | ----------- | ---------- | ----- |
| 2.10.x        | 2.10.0+      | 24.0.0+     | 1.27+      | 3.14+ |
| 2.9.x         | 2.9.0+       | 23.5.0+     | 1.26+      | 3.13+ |
| 2.8.x         | 2.8.0+       | 23.0.0+     | 1.25+      | 3.12+ |
| 2.7.x         | 2.7.0+       | 22.0.0+     | 1.24+      | 3.11+ |

## Related Documentation

- [Overview](overview.md) - Detailed architecture, configuration, and security
- [Usage](usage.md) - Installation, customization, and troubleshooting
