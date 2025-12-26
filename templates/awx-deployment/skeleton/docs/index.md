# ${{ values.name }}

${{ values.description }}

## Overview

AWX is the upstream open-source project for Ansible Tower/Automation Controller. This deployment provides a Kubernetes-based AWX installation for managing Ansible automation at scale.

## Prerequisites

- Kubernetes cluster (1.24+)
- kubectl configured with cluster access
- Helm 3.x (optional)
- At least 4GB RAM and 2 CPUs for AWX

## Quick Start

### Deploy AWX

```bash
# Run the deployment script
./deploy.sh

# Or deploy manually with kubectl
kubectl apply -k k8s/
```

### Access AWX UI

```bash
# Get the AWX URL
kubectl get ingress -n awx

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 -d
```

Default credentials:
- Username: `admin`
- Password: Retrieved from secret above

## Project Structure

```
.
├── catalog-info.yaml     # Backstage catalog entry
├── deploy.sh             # Deployment script
├── docs/                 # Documentation
├── k8s/                  # Kubernetes manifests
│   ├── awx.yaml          # AWX custom resource
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   └── operator.yaml     # AWX Operator deployment
└── README.md
```

## Architecture

```
┌─────────────────────────────────────────┐
│             Kubernetes Cluster          │
│  ┌─────────────────────────────────┐    │
│  │          AWX Namespace          │    │
│  │  ┌─────────┐  ┌─────────────┐   │    │
│  │  │   AWX   │  │  PostgreSQL │   │    │
│  │  │   Web   │  │   Database  │   │    │
│  │  └────┬────┘  └─────────────┘   │    │
│  │       │                         │    │
│  │  ┌────┴────┐  ┌─────────────┐   │    │
│  │  │   AWX   │  │    Redis    │   │    │
│  │  │  Task   │  │    Cache    │   │    │
│  │  └─────────┘  └─────────────┘   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Configuration

### AWX Settings

Edit `k8s/awx.yaml` to customize:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.example.com
  postgres_storage_class: standard
  projects_persistence: true
  projects_storage_size: 10Gi
```

### Resource Limits

```yaml
spec:
  web_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
```

## Operations

### Backup and Restore

```bash
# Create backup
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-$(date +%Y%m%d)
  namespace: awx
spec:
  deployment_name: awx
EOF

# Restore from backup
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-restore
  namespace: awx
spec:
  deployment_name: awx
  backup_name: awx-backup-20231201
EOF
```

### Scaling

```bash
# Scale task pods
kubectl scale deployment awx-task --replicas=3 -n awx
```

### Logs

```bash
# View AWX web logs
kubectl logs -f deployment/awx-web -n awx

# View AWX task logs
kubectl logs -f deployment/awx-task -n awx

# View operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx
```

## Integrations

### LDAP/AD Authentication

Configure in AWX UI: Settings > Authentication > LDAP

### Source Control

Add credentials for Git repositories in AWX:
- Settings > Credentials > Add
- Select "Source Control" type

### Cloud Credentials

AWX supports credentials for:
- AWS
- Azure
- GCP
- VMware
- OpenStack

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n awx

# Describe failing pod
kubectl describe pod <pod-name> -n awx

# Check events
kubectl get events -n awx --sort-by='.lastTimestamp'
```

### Database Issues

```bash
# Check PostgreSQL pod
kubectl logs -f deployment/awx-postgres -n awx

# Connect to database
kubectl exec -it deployment/awx-postgres -n awx -- psql -U awx
```

### Reset Admin Password

```bash
kubectl exec -it deployment/awx-web -n awx -- awx-manage changepassword admin
```

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](${{ values.repoUrl }})
- **AWX Documentation**: https://ansible.readthedocs.io/projects/awx/en/latest/
