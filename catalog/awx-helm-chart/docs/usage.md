# Usage Guide

## Installation

### Prerequisites

```bash
# Check Kubernetes version (1.27+ required)
kubectl version --short

# Check Helm version (3.14+ required)
helm version

# Ensure cluster has sufficient resources
kubectl top nodes
```

### Basic Installation

```bash
# Add Helm repository
helm repo add awx-community https://ansible.github.io/awx-operator/
helm repo update

# Create namespace
kubectl create namespace awx

# Install with default values
helm install awx awx-community/awx-operator \
  --namespace awx \
  --set AWX.enabled=true \
  --set AWX.name=awx

# Wait for operator
kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
  -n awx --timeout=300s

# Wait for AWX instance
kubectl wait --for=condition=Ready awx/awx -n awx --timeout=600s
```

### Production Installation

```bash
# Create values file
cat > values-production.yaml << 'EOF'
operator:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi

AWX:
  enabled: true
  name: awx-production
  spec:
    admin_user: admin
    admin_email: admin@example.com
    
    # High availability
    web_replicas: 3
    task_replicas: 3
    
    # Resource allocation
    web_resource_requirements:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 2000m
        memory: 4Gi
    
    task_resource_requirements:
      requests:
        cpu: 1000m
        memory: 2Gi
      limits:
        cpu: 4000m
        memory: 8Gi
    
    # PostgreSQL configuration
    postgres_storage_class: fast-ssd
    postgres_storage_requirements:
      requests:
        storage: 50Gi
    
    # Projects persistence
    projects_persistence: true
    projects_storage_class: nfs-client
    projects_storage_size: 50Gi
    projects_storage_access_mode: ReadWriteMany
    
    # Ingress hostname
    hostname: awx.example.com
    
    # Extra settings
    extra_settings:
      - setting: REMOTE_HOST_HEADERS
        value: "['HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR']"
      - setting: SESSION_COOKIE_SECURE
        value: "True"
      - setting: CSRF_COOKIE_SECURE
        value: "True"

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: awx.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: awx-tls
      hosts:
        - awx.example.com
EOF

# Install production configuration
helm install awx-production awx-community/awx-operator \
  --namespace awx \
  --values values-production.yaml \
  --wait --timeout 20m
```

### External Database Configuration

```bash
# Create database credentials secret
kubectl create secret generic awx-postgres-configuration \
  --namespace awx \
  --from-literal=host='postgres.example.com' \
  --from-literal=port='5432' \
  --from-literal=database='awx' \
  --from-literal=username='awx' \
  --from-literal=password='secure-password' \
  --from-literal=sslmode='require' \
  --from-literal=type='unmanaged'

# Reference in values
cat > values-external-db.yaml << 'EOF'
AWX:
  enabled: true
  name: awx
  spec:
    postgres_configuration_secret: awx-postgres-configuration
EOF

helm install awx awx-community/awx-operator \
  --namespace awx \
  --values values-external-db.yaml
```

## Custom Values Files

### Development Environment

```yaml
# values-development.yaml
AWX:
  enabled: true
  name: awx-dev
  spec:
    admin_user: admin
    
    web_replicas: 1
    task_replicas: 1
    
    web_resource_requirements:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 1Gi
    
    task_resource_requirements:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 2Gi
    
    postgres_storage_requirements:
      requests:
        storage: 5Gi
    
    projects_persistence: true
    projects_storage_size: 5Gi
    
    # Enable debug logging
    extra_settings:
      - setting: LOG_LEVEL
        value: "DEBUG"

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: awx.dev.local
      paths:
        - path: /
          pathType: Prefix
```

### Air-Gapped Installation

```yaml
# values-airgapped.yaml
operator:
  image:
    repository: registry.internal.example.com/ansible/awx-operator
    tag: 2.10.0

AWX:
  enabled: true
  name: awx
  spec:
    image: registry.internal.example.com/ansible/awx
    image_version: 24.0.0
    
    redis_image: registry.internal.example.com/redis
    redis_image_version: "7"
    
    postgres_image: registry.internal.example.com/postgres
    postgres_image_version: "15"
    
    ee_images:
      - name: AWX EE
        image: registry.internal.example.com/ansible/awx-ee:24.0.0
    
    # Image pull secrets for private registry
    image_pull_secrets:
      - internal-registry-creds
```

## Execution Environments

### Custom Execution Environment

```dockerfile
# Dockerfile for custom EE
ARG EE_BASE_IMAGE=quay.io/ansible/awx-ee:24.0.0
FROM $EE_BASE_IMAGE

# Install additional Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Install additional collections
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

# Install system packages
USER root
RUN dnf install -y \
    postgresql \
    mysql \
    && dnf clean all
USER 1000
```

```yaml
# requirements.txt
netaddr>=0.8.0
jmespath>=1.0.0
boto3>=1.26.0
google-auth>=2.16.0
azure-identity>=1.12.0
kubernetes>=25.0.0
```

```yaml
# requirements.yml
collections:
  - name: amazon.aws
    version: ">=6.0.0"
  - name: azure.azcollection
    version: ">=1.15.0"
  - name: google.cloud
    version: ">=1.1.0"
  - name: kubernetes.core
    version: ">=2.4.0"
  - name: community.general
    version: ">=7.0.0"
```

```bash
# Build and push custom EE
podman build -t registry.example.com/custom-awx-ee:1.0.0 .
podman push registry.example.com/custom-awx-ee:1.0.0

# Configure in AWX
cat > values-custom-ee.yaml << 'EOF'
AWX:
  spec:
    ee_images:
      - name: Custom EE
        image: registry.example.com/custom-awx-ee:1.0.0
    control_plane_ee_image: registry.example.com/custom-awx-ee:1.0.0
EOF
```

## Backup and Restore

### Automated Backups

```yaml
# AWXBackup CRD for scheduled backups
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-daily
  namespace: awx
spec:
  deployment_name: awx
  backup_pvc: awx-backup-claim
  backup_pvc_namespace: awx
  
  # Backup storage configuration
  backup_storage_class: standard
  backup_storage_requirements: 10Gi
  
  # Clean old backups
  clean_backup_on_delete: true
  
  # Schedule (cron format)
  backup_schedule: "0 2 * * *"  # Daily at 2 AM
```

```bash
# Create backup PVC
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: awx-backup-claim
  namespace: awx
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard
EOF

# Create backup
kubectl apply -f - << 'EOF'
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-$(date +%Y%m%d)
  namespace: awx
spec:
  deployment_name: awx
  backup_pvc: awx-backup-claim
EOF

# Check backup status
kubectl get awxbackup -n awx
kubectl describe awxbackup awx-backup-$(date +%Y%m%d) -n awx
```

### Restore from Backup

```bash
# List available backups
kubectl get awxbackup -n awx

# Create restore
kubectl apply -f - << 'EOF'
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-restore
  namespace: awx
spec:
  deployment_name: awx
  backup_name: awx-backup-20241223
  backup_pvc: awx-backup-claim
EOF

# Monitor restore progress
kubectl get awxrestore -n awx -w
kubectl logs -f deployment/awx-operator-controller-manager -n awx
```

### S3 Backup Integration

```yaml
# Backup to S3
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-s3
  namespace: awx
spec:
  deployment_name: awx
  
  # S3 configuration
  backup_storage_class: ""
  backup_s3_bucket: awx-backups
  backup_s3_region: us-east-1
  backup_s3_secret: awx-s3-credentials
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-s3-credentials
  namespace: awx
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"
  AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

## Upgrades

### Helm Chart Upgrade

```bash
# Check current version
helm list -n awx

# Update repository
helm repo update

# Check available versions
helm search repo awx-community/awx-operator --versions

# Dry-run upgrade
helm upgrade awx awx-community/awx-operator \
  --namespace awx \
  --values values-production.yaml \
  --dry-run --debug

# Perform upgrade
helm upgrade awx awx-community/awx-operator \
  --namespace awx \
  --values values-production.yaml \
  --wait --timeout 20m

# Verify upgrade
kubectl get pods -n awx
kubectl get awx -n awx
```

### AWX Version Upgrade

```yaml
# Update AWX version in values
AWX:
  spec:
    image_version: 24.1.0  # New version
```

```bash
# Create backup before upgrade
kubectl apply -f - << 'EOF'
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-pre-upgrade-backup
  namespace: awx
spec:
  deployment_name: awx
  backup_pvc: awx-backup-claim
EOF

# Wait for backup completion
kubectl wait --for=condition=Complete awxbackup/awx-pre-upgrade-backup -n awx --timeout=600s

# Upgrade AWX
helm upgrade awx awx-community/awx-operator \
  --namespace awx \
  --values values-production.yaml

# Monitor migration
kubectl logs -f deployment/awx-operator-controller-manager -n awx
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Pods stuck in Pending | Insufficient resources | Check node capacity: `kubectl describe nodes` |
| Database connection failed | Wrong credentials or network | Verify secret: `kubectl get secret awx-postgres-configuration -o yaml` |
| Ingress not working | Missing ingress controller | Install ingress: `helm install ingress-nginx ingress-nginx/ingress-nginx` |
| AWX CRD not found | Operator not installed | Install operator first: `helm install awx awx-community/awx-operator` |
| Backup failed | PVC not bound | Check PVC status: `kubectl get pvc -n awx` |
| EE image pull error | Missing pull secret | Add `image_pull_secrets` to AWX spec |
| LDAP auth failing | Certificate issues | Add custom CA bundle to AWX |
| Slow job execution | Insufficient task workers | Increase `task_replicas` |

### Diagnostic Commands

```bash
# Check all AWX resources
kubectl get all -n awx

# Check AWX custom resource status
kubectl describe awx awx -n awx

# Check operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx

# Check AWX web logs
kubectl logs -f deployment/awx-web -n awx -c awx-web

# Check AWX task logs
kubectl logs -f deployment/awx-task -n awx -c awx-task

# Check Redis
kubectl logs -f deployment/awx-redis -n awx

# Check PostgreSQL
kubectl logs -f statefulset/awx-postgres-15 -n awx

# Check events
kubectl get events -n awx --sort-by='.lastTimestamp'

# Check ingress
kubectl describe ingress awx-ingress -n awx
```

### Database Troubleshooting

```bash
# Connect to PostgreSQL
kubectl exec -it statefulset/awx-postgres-15 -n awx -- psql -U awx

# Check database size
kubectl exec -it statefulset/awx-postgres-15 -n awx -- psql -U awx -c \
  "SELECT pg_size_pretty(pg_database_size('awx'));"

# Check active connections
kubectl exec -it statefulset/awx-postgres-15 -n awx -- psql -U awx -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname = 'awx';"

# Run database maintenance
kubectl exec -it statefulset/awx-postgres-15 -n awx -- psql -U awx -c \
  "VACUUM ANALYZE;"
```

### Network Troubleshooting

```bash
# Test internal connectivity
kubectl run debug --rm -it --image=busybox -n awx -- sh

# Inside pod:
# Test AWX service
wget -qO- http://awx-service:80/api/v2/ping/

# Test PostgreSQL
nc -zv awx-postgres-15 5432

# Test Redis
nc -zv awx-redis 6379

# Check DNS resolution
nslookup awx-service.awx.svc.cluster.local
```

## Best Practices

### Resource Planning

```yaml
# Sizing guidelines
# Small (< 100 hosts, < 10 concurrent jobs)
small:
  web_replicas: 1
  task_replicas: 1
  postgres_storage: 10Gi
  web_memory: 1Gi
  task_memory: 2Gi

# Medium (100-500 hosts, 10-50 concurrent jobs)
medium:
  web_replicas: 2
  task_replicas: 2
  postgres_storage: 25Gi
  web_memory: 2Gi
  task_memory: 4Gi

# Large (500+ hosts, 50+ concurrent jobs)
large:
  web_replicas: 3
  task_replicas: 4
  postgres_storage: 50Gi
  web_memory: 4Gi
  task_memory: 8Gi
```

### Security Checklist

- [ ] Use strong admin password (stored in Kubernetes Secret)
- [ ] Enable TLS/HTTPS with valid certificates
- [ ] Configure network policies
- [ ] Use external PostgreSQL with TLS
- [ ] Enable audit logging
- [ ] Configure LDAP/SAML for enterprise auth
- [ ] Regular backup schedule configured
- [ ] Pod security standards enforced
- [ ] Image scanning for custom EEs
- [ ] Secrets managed with External Secrets Operator

### Operational Checklist

- [ ] Monitoring with Prometheus/Grafana configured
- [ ] Log aggregation set up (ELK/Loki)
- [ ] Alerting rules defined
- [ ] Backup/restore tested
- [ ] Disaster recovery plan documented
- [ ] Upgrade procedure tested
- [ ] Capacity planning reviewed
- [ ] Documentation maintained

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
