# ${{ values.name }}

${{ values.description }}

## Overview

AWX is the upstream open-source project for Red Hat Ansible Automation Platform (formerly Ansible Tower). This deployment provides a production-ready, Kubernetes-based AWX installation managed by the AWX Operator for orchestrating Ansible automation at scale.

Key features of this deployment:

- Kubernetes-native deployment using the AWX Operator
- PostgreSQL database with persistent storage
- Redis for caching and message queuing
- Web UI for managing inventories, credentials, and job templates
- RESTful API for automation and integration
- Role-based access control (RBAC)
- Project synchronization from Git repositories
- Scheduled job execution and workflow orchestration

```d2
direction: right

title: {
  label: AWX Deployment Architecture - ${{ values.environment }}
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Users {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

ingress: Ingress Controller {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "NGINX Ingress\n${{ values.hostname }}"
}

k8s: Kubernetes Cluster {
  style.fill: "#F5F5F5"
  style.stroke: "#616161"

  namespace: ${{ values.namespace }} Namespace {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    awx_web: AWX Web {
      style.fill: "#C8E6C9"
      style.stroke: "#388E3C"
      label: "AWX Web\nUI + API\nPort: 8052"
    }

    awx_task: AWX Task {
      style.fill: "#FFECB3"
      style.stroke: "#FFA000"
      label: "AWX Task\nJob Runner\nAnsible Execution"
    }

    awx_ee: Execution Environment {
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
      label: "Execution\nEnvironment\nAnsible Playbooks"
    }

    postgres: PostgreSQL {
      shape: cylinder
      style.fill: "#BBDEFB"
      style.stroke: "#1976D2"
      label: "PostgreSQL\nDatabase\n${{ values.postgres_storage_size }}"
    }

    redis: Redis {
      shape: cylinder
      style.fill: "#FFCDD2"
      style.stroke: "#D32F2F"
      label: "Redis\nCache/Queue"
    }

    pvc_projects: Projects PVC {
      shape: cylinder
      style.fill: "#E1BEE7"
      style.stroke: "#7B1FA2"
      label: "Projects\nStorage\n${{ values.project_storage_size }}"
    }

    awx_web -> postgres: queries
    awx_web -> redis: cache
    awx_task -> postgres: job data
    awx_task -> redis: queue
    awx_task -> awx_ee: execute
    awx_task -> pvc_projects: sync
  }

  operator: AWX Operator {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
    label: "AWX Operator\nLifecycle Management"
  }

  operator -> namespace: manages
}

users -> ingress: HTTPS
ingress -> k8s.namespace.awx_web: routes
```

---

## Configuration Summary

| Setting              | Value                                                      |
| -------------------- | ---------------------------------------------------------- |
| Instance Name        | `${{ values.name }}`                                       |
| Namespace            | `${{ values.namespace }}`                                  |
| Environment          | `${{ values.environment }}`                                |
| AWX Version          | `${{ values.awx_version }}`                                |
| Service Type         | `${{ values.service_type }}`                               |
| Ingress Enabled      | `${{ values.ingress_enabled }}`                            |
| Hostname             | `${{ values.hostname }}`                                   |
| SSL/TLS Enabled      | `${{ values.ssl_enabled }}`                                |
| Storage Class        | `${{ values.storage_class }}`                              |
| PostgreSQL Storage   | `${{ values.postgres_storage_size }}`                      |
| Project Storage      | `${{ values.project_storage_size }}`                       |
| Admin User           | `${{ values.admin_user }}`                                 |
| LDAP Enabled         | `${{ values.ldap_enabled }}`                               |
| Owner                | `${{ values.owner }}`                                      |

---

## Infrastructure Components

### AWX Web Service

The AWX Web component provides:

- **Django-based Web UI**: User-friendly interface for managing automation
- **REST API**: Programmable interface for CI/CD integration
- **Authentication**: Local users, LDAP, SAML, and OAuth2 support
- **RBAC**: Fine-grained role-based access control

| Resource | Requests | Limits |
| -------- | -------- | ------ |
| CPU      | 1000m    | 2000m  |
| Memory   | 2Gi      | 4Gi    |

### AWX Task Service

The AWX Task component handles:

- **Job Execution**: Running Ansible playbooks and ad-hoc commands
- **Workflow Orchestration**: Chaining jobs with conditional logic
- **Scheduling**: Cron-like job scheduling
- **Callback Processing**: Handling callbacks from managed nodes

| Resource | Requests | Limits |
| -------- | -------- | ------ |
| CPU      | 500m     | 1000m  |
| Memory   | 1Gi      | 2Gi    |

### Execution Environment

The Execution Environment provides:

- **Containerized Ansible Runtime**: Isolated execution environment
- **Custom Collections**: Pre-installed Ansible collections
- **Python Dependencies**: Required Python packages for playbooks

| Resource | Requests | Limits |
| -------- | -------- | ------ |
| CPU      | 500m     | 1000m  |
| Memory   | 1Gi      | 2Gi    |

### PostgreSQL Database

PostgreSQL stores all AWX data including:

- **Inventories**: Managed hosts and groups
- **Credentials**: Encrypted secrets for authentication
- **Job History**: Execution logs and output
- **Projects**: Source control repository configurations

| Setting       | Value                              |
| ------------- | ---------------------------------- |
| Storage Size  | `${{ values.postgres_storage_size }}` |
| Storage Class | `${{ values.storage_class }}`      |

### Redis Cache

Redis provides:

- **Message Queue**: Inter-process communication
- **Cache Layer**: Session and result caching
- **Pub/Sub**: Real-time event notifications

| Resource | Requests | Limits |
| -------- | -------- | ------ |
| CPU      | 500m     | 1000m  |
| Memory   | 1Gi      | 2Gi    |

---

## CI/CD Pipeline

This repository includes GitHub Actions workflows for automated deployment and management of the AWX instance.

### Pipeline Features

- **Validation**: Kubernetes manifest validation and linting
- **Security Scanning**: Secret detection and best practices verification
- **Deployment**: Automated deployment to Kubernetes cluster
- **Health Checks**: Post-deployment verification
- **Rollback**: Automated rollback on deployment failure

### Pipeline Workflow

```d2
direction: right

title: {
  label: AWX Deployment Pipeline
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "YAML Lint\nKubeval\nSchema Validate"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Secret Scan\nPolicy Check\nBest Practices"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Kustomize Build\nManifest Generation"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

deploy: Deploy {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
  label: "kubectl apply\nAWX Deployment"
}

verify: Verify {
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "Health Check\nSmoke Test"
}

pr -> validate -> security -> build -> review -> deploy -> verify
```

### Workflow Triggers

| Event         | Action                                        |
| ------------- | --------------------------------------------- |
| Pull Request  | Validate, Security Scan, Dry-run Deploy       |
| Push to main  | Full deployment to `${{ values.environment }}` |
| Manual        | Deploy, Rollback, Scale operations            |

---

## Prerequisites

### 1. Kubernetes Cluster

A Kubernetes cluster version 1.24 or higher is required:

```bash
# Verify cluster version
kubectl version --short

# Check cluster connectivity
kubectl cluster-info

# Verify sufficient resources
kubectl top nodes
```

**Minimum Requirements:**

| Resource | Requirement                        |
| -------- | ---------------------------------- |
| Nodes    | At least 1 node with 4GB RAM, 2 CPU |
| Storage  | StorageClass with dynamic provisioning |
| Network  | Ingress controller (if using ingress) |

### 2. AWX Operator

The AWX Operator must be installed in the cluster:

```bash
# Install AWX Operator using Kustomize
kubectl apply -k https://github.com/ansible/awx-operator/config/default

# Or install specific version
AWX_OPERATOR_VERSION=2.10.0
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/${AWX_OPERATOR_VERSION}/deploy/awx-operator.yaml

# Verify operator is running
kubectl get pods -n awx-operator-system
kubectl get crd awxs.awx.ansible.com
```

### 3. Helm (Optional)

Helm 3.x is optional but useful for managing dependencies:

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### 4. kubectl Configuration

Ensure kubectl is configured with cluster access:

```bash
# Configure kubectl context
kubectl config use-context <your-cluster-context>

# Verify access
kubectl auth can-i create deployments --namespace ${{ values.namespace }}
```

### 5. Ingress Controller (If Using Ingress)

Install NGINX Ingress Controller if ingress is enabled:

```bash
# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Verify installation
kubectl get pods -n ingress-nginx
```

### 6. Cert-Manager (If Using SSL/TLS)

Install cert-manager for automatic certificate management:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

---

## Usage

### Deployment

#### Quick Deploy

```bash
# Run the deployment script
./deploy.sh

# Or deploy with specific action
./deploy.sh deploy
```

#### Manual Deployment

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# Apply Kubernetes manifests
kubectl apply -k k8s/

# Watch deployment progress
kubectl get pods -n ${{ values.namespace }} -w
```

#### Verify Deployment

```bash
# Check AWX custom resource status
kubectl get awx ${{ values.name }} -n ${{ values.namespace }}

# Check all pods are running
kubectl get pods -n ${{ values.namespace }}

# Check services
kubectl get svc -n ${{ values.namespace }}

# Check ingress (if enabled)
kubectl get ingress -n ${{ values.namespace }}
```

### Accessing AWX UI

#### Via Ingress (Recommended)

If ingress is enabled, access AWX at:

```
https://${{ values.hostname }}
```

#### Via Port Forward

For ClusterIP service type or local development:

```bash
# Port forward to AWX service
kubectl port-forward -n ${{ values.namespace }} svc/awx-${{ values.name }}-service 8080:80

# Access at http://localhost:8080
```

#### Via NodePort

If using NodePort service type:

```bash
# Get NodePort
NODE_PORT=$(kubectl get svc awx-${{ values.name }}-service -n ${{ values.namespace }} -o jsonpath='{.spec.ports[0].nodePort}')

# Get Node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Access at http://${NODE_IP}:${NODE_PORT}
echo "AWX URL: http://${NODE_IP}:${NODE_PORT}"
```

### Retrieving Admin Credentials

```bash
# Get admin password
kubectl get secret awx-${{ values.name }}-admin-password -n ${{ values.namespace }} \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Default credentials
# Username: ${{ values.admin_user }}
# Password: Retrieved from secret above
```

### Scaling

```bash
# Scale AWX web replicas
kubectl scale deployment awx-${{ values.name }}-web -n ${{ values.namespace }} --replicas=3

# Scale AWX task replicas
kubectl scale deployment awx-${{ values.name }}-task -n ${{ values.namespace }} --replicas=3

# For production, modify awx.yaml spec.replicas instead
```

---

## Configuration Management

### Modifying AWX Configuration

Edit `k8s/awx.yaml` to customize the deployment:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ${{ values.name }}
  namespace: ${{ values.namespace }}
spec:
  # Ingress configuration
  ingress_type: ingress
  hostname: ${{ values.hostname }}
  
  # Resource limits
  web_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  # Storage configuration
  postgres_storage_class: ${{ values.storage_class }}
  postgres_storage_requirements:
    requests:
      storage: ${{ values.postgres_storage_size }}
```

### Environment-Specific Configuration

| Setting    | Development | Staging | Production |
| ---------- | ----------- | ------- | ---------- |
| Replicas   | 1           | 1       | 2+         |
| Auto Upgrade | true      | true    | false      |
| Web CPU    | 500m-1000m  | 1000m-2000m | 2000m-4000m |
| Web Memory | 1Gi-2Gi     | 2Gi-4Gi | 4Gi-8Gi    |

### Updating Secrets

```bash
# Update admin password
kubectl create secret generic awx-${{ values.name }}-admin-password \
  -n ${{ values.namespace }} \
  --from-literal=password='NewSecurePassword123!' \
  --dry-run=client -o yaml | kubectl apply -f -

# Update PostgreSQL credentials
kubectl create secret generic awx-${{ values.name }}-postgres-configuration \
  -n ${{ values.namespace }} \
  --from-literal=host=awx-${{ values.name }}-postgres-13 \
  --from-literal=port=5432 \
  --from-literal=database=awx \
  --from-literal=username=awx \
  --from-literal=password='NewDBPassword123!' \
  --from-literal=sslmode=prefer \
  --from-literal=type=managed \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Configuring LDAP Authentication

1. Enable LDAP in AWX UI: **Settings > Authentication > LDAP**
2. Or configure via the AWX API:

```bash
# Example LDAP configuration
curl -X PATCH https://${{ values.hostname }}/api/v2/settings/ldap/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "AUTH_LDAP_SERVER_URI": "ldap://ldap.example.com:389",
    "AUTH_LDAP_BIND_DN": "cn=admin,dc=example,dc=com",
    "AUTH_LDAP_BIND_PASSWORD": "secret",
    "AUTH_LDAP_USER_SEARCH": ["ou=users,dc=example,dc=com", "SCOPE_SUBTREE", "(uid=%(user)s)"]
  }'
```

---

## Backup and Restore

### Creating Backups

AWX Operator supports native backup and restore operations:

```bash
# Create a backup
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-${{ values.name }}-backup-$(date +%Y%m%d-%H%M%S)
  namespace: ${{ values.namespace }}
spec:
  deployment_name: ${{ values.name }}
  backup_pvc: awx-${{ values.name }}-backup-pvc
  backup_storage_class: ${{ values.storage_class }}
  backup_storage_requirements:
    requests:
      storage: 10Gi
EOF

# List backups
kubectl get awxbackup -n ${{ values.namespace }}

# Check backup status
kubectl describe awxbackup <backup-name> -n ${{ values.namespace }}
```

### Automated Backup Schedule

Create a CronJob for automated backups:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: awx-${{ values.name }}-backup-job
  namespace: ${{ values.namespace }}
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: awx-operator-controller-manager
          containers:
          - name: backup
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              kubectl apply -f - <<EOF
              apiVersion: awx.ansible.com/v1beta1
              kind: AWXBackup
              metadata:
                name: awx-${{ values.name }}-backup-$(date +%Y%m%d)
                namespace: ${{ values.namespace }}
              spec:
                deployment_name: ${{ values.name }}
              EOF
          restartPolicy: OnFailure
```

### Restoring from Backup

```bash
# List available backups
kubectl get awxbackup -n ${{ values.namespace }}

# Restore from a specific backup
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-${{ values.name }}-restore
  namespace: ${{ values.namespace }}
spec:
  deployment_name: ${{ values.name }}
  backup_name: awx-${{ values.name }}-backup-20231201
EOF

# Monitor restore progress
kubectl get awxrestore -n ${{ values.namespace }} -w
kubectl logs -f deployment/awx-operator-controller-manager -n awx-operator-system
```

### Database Backup (Manual)

```bash
# Create PostgreSQL dump
kubectl exec -n ${{ values.namespace }} deployment/awx-${{ values.name }}-postgres-13 -- \
  pg_dump -U awx -d awx > awx-backup-$(date +%Y%m%d).sql

# Restore from dump
kubectl exec -i -n ${{ values.namespace }} deployment/awx-${{ values.name }}-postgres-13 -- \
  psql -U awx -d awx < awx-backup-20231201.sql
```

---

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ${{ values.namespace }}

# Describe failing pod for events
kubectl describe pod <pod-name> -n ${{ values.namespace }}

# Check recent events
kubectl get events -n ${{ values.namespace }} --sort-by='.lastTimestamp' | tail -20
```

#### AWX Operator Not Working

```bash
# Check operator status
kubectl get pods -n awx-operator-system

# View operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx-operator-system

# Verify CRDs are installed
kubectl get crd | grep awx
```

#### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pods -n ${{ values.namespace }} -l app.kubernetes.io/component=database

# View PostgreSQL logs
kubectl logs -n ${{ values.namespace }} deployment/awx-${{ values.name }}-postgres-13

# Connect to database directly
kubectl exec -it -n ${{ values.namespace }} deployment/awx-${{ values.name }}-postgres-13 -- \
  psql -U awx -d awx -c "\dt"

# Verify database secret
kubectl get secret awx-${{ values.name }}-postgres-configuration -n ${{ values.namespace }} -o yaml
```

#### Redis Connection Issues

```bash
# Check Redis pod
kubectl get pods -n ${{ values.namespace }} -l app.kubernetes.io/component=redis

# View Redis logs
kubectl logs -n ${{ values.namespace }} deployment/awx-${{ values.name }}-redis

# Test Redis connectivity
kubectl exec -it -n ${{ values.namespace }} deployment/awx-${{ values.name }}-redis -- redis-cli ping
```

#### Web UI Not Accessible

```bash
# Check web service
kubectl get svc -n ${{ values.namespace }} -l app.kubernetes.io/component=awx

# Check ingress configuration
kubectl get ingress -n ${{ values.namespace }}
kubectl describe ingress -n ${{ values.namespace }}

# Test from within cluster
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl -I http://awx-${{ values.name }}-service.${{ values.namespace }}.svc.cluster.local
```

#### Reset Admin Password

```bash
# Reset via awx-manage
kubectl exec -it -n ${{ values.namespace }} deployment/awx-${{ values.name }}-web -- \
  awx-manage changepassword ${{ values.admin_user }}

# Or create new secret
kubectl create secret generic awx-${{ values.name }}-admin-password \
  -n ${{ values.namespace }} \
  --from-literal=password='NewPassword123!' \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart web pods to pick up new password
kubectl rollout restart deployment awx-${{ values.name }}-web -n ${{ values.namespace }}
```

#### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n ${{ values.namespace }}

# Describe PVC for events
kubectl describe pvc -n ${{ values.namespace }}

# Verify StorageClass exists
kubectl get storageclass ${{ values.storage_class }}
```

### Viewing Logs

```bash
# AWX Web logs
kubectl logs -f -n ${{ values.namespace }} deployment/awx-${{ values.name }}-web

# AWX Task logs
kubectl logs -f -n ${{ values.namespace }} deployment/awx-${{ values.name }}-task

# All AWX logs
kubectl logs -f -n ${{ values.namespace }} -l app.kubernetes.io/instance=${{ values.name }}

# Use deployment script
./deploy.sh logs
```

### Health Checks

```bash
# Check AWX status
./deploy.sh status

# API health check
curl -k https://${{ values.hostname }}/api/v2/ping/

# Verify all components
kubectl get awx ${{ values.name }} -n ${{ values.namespace }} -o jsonpath='{.status.conditions}'
```

---

## Related Templates

| Template                                                          | Description                              |
| ----------------------------------------------------------------- | ---------------------------------------- |
| [awx-operator](/docs/default/template/awx-operator)               | AWX Operator installation template       |
| [ansible-playbook](/docs/default/template/ansible-playbook)       | Ansible Playbook project template        |
| [kubernetes-cluster](/docs/default/template/kubernetes-cluster)   | Kubernetes cluster provisioning          |
| [argocd-application](/docs/default/template/argocd-application)   | ArgoCD application for GitOps deployment |
| [vault-secrets](/docs/default/template/vault-secrets)             | HashiCorp Vault secrets integration      |

---

## References

- [AWX Project Documentation](https://ansible.readthedocs.io/projects/awx/en/latest/)
- [AWX Operator GitHub](https://github.com/ansible/awx-operator)
- [AWX API Reference](https://docs.ansible.com/automation-controller/latest/html/controllerapi/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)

---

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }})
- **Environment**: `${{ values.environment }}`
- **Namespace**: `${{ values.namespace }}`
