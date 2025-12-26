# Usage Guide

## Installation Methods

### Method 1: Kustomize (Recommended)

```bash
# Create namespace
kubectl create namespace awx

# Install specific version
kubectl apply -k github.com/ansible/awx-operator/config/default?ref=2.12.0

# Or with custom kustomization
cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: awx
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.12.0
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.12.0
EOF

kubectl apply -k .
```

### Method 2: Helm

```bash
# Add Helm repository
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update

# Install operator
helm install awx-operator awx-operator/awx-operator \
  --namespace awx \
  --create-namespace \
  --set AWX.enabled=true \
  --set AWX.spec.service_type=ClusterIP

# Custom values
cat > values.yaml <<EOF
AWX:
  enabled: true
  name: awx
  spec:
    service_type: ClusterIP
    ingress_type: ingress
    hostname: awx.example.com
    admin_user: admin
    postgres_storage_class: standard
EOF

helm install awx-operator awx-operator/awx-operator \
  --namespace awx \
  --create-namespace \
  -f values.yaml
```

### Method 3: OLM (OpenShift)

```bash
# Create OperatorGroup
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: awx-operator-group
  namespace: awx
spec:
  targetNamespaces:
    - awx
EOF

# Create Subscription
cat <<EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: awx-operator
  namespace: awx
spec:
  channel: stable
  name: awx-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
```

## Deployment Examples

### Basic AWX Deployment

```yaml
# awx-basic.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
```

### Production AWX with Ingress

```yaml
# awx-production.yaml
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
  namespace: awx
type: Opaque
stringData:
  password: 'YourSecurePassword123!'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  # High availability
  web_replicas: 2
  task_replicas: 2

  # Resources
  web_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 8Gi

  task_resource_requirements:
    requests:
      cpu: 1000m
      memory: 4Gi
    limits:
      cpu: 8000m
      memory: 16Gi

  # Storage
  postgres_storage_class: fast-ssd
  postgres_storage_requirements:
    requests:
      storage: 50Gi

  projects_persistence: true
  projects_storage_class: fast-ssd
  projects_storage_size: 20Gi

  # Ingress
  ingress_type: ingress
  hostname: awx.example.com
  ingress_annotations: |
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  ingress_tls_secret: awx-tls
  # Admin
  admin_user: admin
  admin_password_secret: awx-admin-password

  # Extra settings
  extra_settings:
    - setting: REMOTE_HOST_HEADERS
      value:
        - HTTP_X_FORWARDED_FOR
    - setting: CSRF_TRUSTED_ORIGINS
      value:
        - https://awx.example.com
    - setting: SESSION_COOKIE_SECURE
      value: true
    - setting: CSRF_COOKIE_SECURE
      value: true
```

### AWX with External PostgreSQL

```yaml
# external-postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: awx-external-postgres
  namespace: awx
type: Opaque
stringData:
  host: rds.example.amazonaws.com
  port: '5432'
  database: awx
  username: awx
  password: your-db-password
  sslmode: require
  type: unmanaged
---
# awx-external-db.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  postgres_configuration_secret: awx-external-postgres

  # Rest of configuration...
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.example.com
```

### AWX with Custom Execution Environment

```yaml
# awx-custom-ee.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ee-registry-secret
  namespace: awx
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  control_plane_ee_image: registry.example.com/awx-ee-custom:1.0.0

  image_pull_secrets:
    - name: ee-registry-secret

  ee_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 8Gi

  # Other settings...
  service_type: ClusterIP
```

## Backup and Restore

### Create Backup

```yaml
# awx-backup.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: awx-backup-pvc
  namespace: awx
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: standard
---
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-$(date +%Y%m%d)
  namespace: awx
spec:
  deployment_name: awx
  backup_pvc: awx-backup-pvc
  clean_backup_on_delete: false
```

```bash
# Create backup
kubectl apply -f awx-backup.yaml

# Check backup status
kubectl get awxbackup -n awx

# List backup contents
kubectl exec -it $(kubectl get pod -n awx -l app.kubernetes.io/name=awx-backup -o name) \
  -n awx -- ls -la /backups/
```

### Restore from Backup

```yaml
# awx-restore.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-restore
  namespace: awx
spec:
  backup_name: awx-backup-20240115
  deployment_name: awx
```

```bash
# Restore
kubectl apply -f awx-restore.yaml

# Monitor restore
kubectl get awxrestore -n awx -w

# Check AWX status
kubectl get awx -n awx
```

### Scheduled Backups with CronJob

```yaml
# scheduled-backup.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: awx-scheduled-backup
  namespace: awx
spec:
  schedule: '0 2 * * *' # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: awx-backup-sa
          containers:
            - name: backup-creator
              image: bitnami/kubectl:latest
              command:
                - /bin/sh
                - -c
                - |
                  DATE=$(date +%Y%m%d-%H%M%S)
                  cat <<EOF | kubectl apply -f -
                  apiVersion: awx.ansible.com/v1beta1
                  kind: AWXBackup
                  metadata:
                    name: awx-backup-${DATE}
                    namespace: awx
                  spec:
                    deployment_name: awx
                    backup_pvc: awx-backup-pvc
                  EOF
          restartPolicy: OnFailure
```

## Upgrade Procedures

### Upgrade AWX Version

```bash
# Check current version
kubectl get awx awx -n awx -o jsonpath='{.spec.image_version}'

# Upgrade AWX image
kubectl patch awx awx -n awx --type merge \
  -p '{"spec":{"image_version":"24.1.0"}}'

# Watch upgrade progress
kubectl get pods -n awx -w

# Verify upgrade
kubectl exec -it deployment/awx-web -n awx -- awx-manage version
```

### Upgrade Operator

```bash
# Backup first
kubectl apply -f awx-backup.yaml

# Check current operator version
kubectl get deployment awx-operator-controller-manager -n awx \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Upgrade operator
kubectl apply -k github.com/ansible/awx-operator/config/default?ref=2.13.0

# Verify operator upgrade
kubectl rollout status deployment/awx-operator-controller-manager -n awx
```

## Troubleshooting

### Common Issues

| Issue                     | Cause               | Solution                    |
| ------------------------- | ------------------- | --------------------------- |
| Operator not starting     | RBAC issues         | Check ClusterRoleBinding    |
| AWX pods pending          | PVC not bound       | Check storage class         |
| Database connection error | Wrong credentials   | Verify postgres secret      |
| Ingress not working       | Missing annotations | Check ingress configuration |
| Backup failing            | PVC full            | Increase backup PVC size    |
| Restore stuck             | Missing backup      | Verify AWXBackup exists     |
| Web pods crashlooping     | OOM                 | Increase memory limits      |

### Debug Commands

```bash
# Check operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx

# Check AWX CR status
kubectl get awx awx -n awx -o yaml

# Describe AWX for events
kubectl describe awx awx -n awx

# Check pod logs
kubectl logs -f deployment/awx-web -n awx
kubectl logs -f deployment/awx-task -n awx

# Check PostgreSQL
kubectl logs -f statefulset/awx-postgres-13 -n awx

# Exec into pod for debugging
kubectl exec -it deployment/awx-web -n awx -- bash

# Check migrations
kubectl exec -it deployment/awx-web -n awx -- awx-manage showmigrations

# Force reconciliation
kubectl annotate awx awx -n awx --overwrite reconcile=$(date +%s)
```

### Health Checks

```bash
# Check operator health
kubectl get deployment awx-operator-controller-manager -n awx

# Check AWX health
kubectl get awx -n awx

# Test API endpoint
kubectl exec -it deployment/awx-web -n awx -- \
  curl -s http://localhost:8052/api/v2/ping/

# Check database connectivity
kubectl exec -it deployment/awx-task -n awx -- \
  python3 -c "from django.db import connection; connection.ensure_connection()"
```

## GitOps Integration

### ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: awx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-configs
    targetRevision: main
    path: awx
  destination:
    server: https://kubernetes.default.svc
    namespace: awx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Flux Kustomization

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: awx
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: infrastructure
  path: ./awx
  prune: true
  healthChecks:
    - apiVersion: awx.ansible.com/v1beta1
      kind: AWX
      name: awx
      namespace: awx
```

## Best Practices

1. **Use external PostgreSQL for production** - Better performance and backup options
2. **Enable PVC for projects** - Persist playbook syncs
3. **Set resource limits** - Prevent resource exhaustion
4. **Use Ingress with TLS** - Secure access
5. **Regular backups** - Automate with CronJob
6. **Monitor operator metrics** - Catch issues early
7. **Use specific versions** - Avoid unexpected upgrades
8. **Test upgrades in staging** - Before production
9. **Document custom settings** - For disaster recovery
10. **Use GitOps** - Version control infrastructure
