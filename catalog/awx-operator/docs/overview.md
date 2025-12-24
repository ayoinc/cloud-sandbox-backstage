# Overview

## Architecture Deep Dive

The AWX Operator follows the Kubernetes Operator pattern, using custom controllers to manage AWX deployments declaratively.

### Operator Components

```d2
direction: down

title: AWX Operator Internals {
  shape: text
  near: top-center
  style.font-size: 24
}

operator: AWX Operator {
  style.fill: "#E3F2FD"
  
  manager: Controller Manager {
    style.fill: "#BBDEFB"
    
    main: Main Process {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    
    features: |md
      - Leader election
      - Health/Ready endpoints
      - Metrics server
    | {
      shape: document
      style.fill: "#E8F5E9"
    }
  }
  
  controllers: Controllers {
    style.fill: "#FFF3E0"
    
    awx: AWXController {
      shape: hexagon
      style.fill: "#FF9800"
      style.font-color: white
    }
    awx_desc: |md
      - Manages Deployments, StatefulSets
      - Handles ConfigMaps, Secrets
      - Creates Services, Ingress
      - Manages PVCs for projects/postgres
    | {
      shape: document
      style.fill: "#FFECB3"
    }
    
    backup: AWXBackupController {
      shape: hexagon
      style.fill: "#FF9800"
      style.font-color: white
    }
    backup_desc: |md
      - Creates backup jobs
      - Manages backup PVCs
      - Exports database and secrets
    | {
      shape: document
      style.fill: "#FFECB3"
    }
    
    restore: AWXRestoreController {
      shape: hexagon
      style.fill: "#FF9800"
      style.font-color: white
    }
    restore_desc: |md
      - Validates backup integrity
      - Restores database
      - Recreates secrets
    | {
      shape: document
      style.fill: "#FFECB3"
    }
    
    awx -> awx_desc
    backup -> backup_desc
    restore -> restore_desc
  }
  
  manager -> controllers: manages
}
```

### Resources Created by Operator

```d2
direction: down

title: AWX CR Resources {
  shape: text
  near: top-center
  style.font-size: 24
}

awx_cr: AWX CR\n(awx.ansible.com/v1beta1) {
  shape: circle
  style.fill: "#9C27B0"
  style.font-color: white
}

deployments: Deployments {
  style.fill: "#E3F2FD"
  
  web: awx-web\n(Nginx + uWSGI) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
  task: awx-task\n(Celery + Receptor) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
}

statefulsets: StatefulSets {
  style.fill: "#E8F5E9"
  
  postgres: awx-postgres\n(if not external DB) {
    shape: cylinder
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

services: Services {
  style.fill: "#FFF3E0"
  
  svc: awx-service\n(Web UI/API) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  db_svc: awx-postgres-13\n(Database) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  receptor: awx-receptor\n(Mesh networking) {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
}

configmaps: ConfigMaps {
  style.fill: "#F3E5F5"
  
  cm1: awx-configmap\n(Django settings) {
    shape: document
    style.fill: "#CE93D8"
  }
  cm2: awx-nginx-conf\n(Nginx config) {
    shape: document
    style.fill: "#CE93D8"
  }
  cm3: awx-receptor-conf\n(Receptor mesh) {
    shape: document
    style.fill: "#CE93D8"
  }
}

secrets: Secrets {
  style.fill: "#FFCDD2"
  
  s1: awx-admin-password {
    shape: document
    style.fill: "#EF5350"
    style.font-color: white
  }
  s2: awx-secret-key {
    shape: document
    style.fill: "#EF5350"
    style.font-color: white
  }
  s3: awx-postgres-configuration {
    shape: document
    style.fill: "#EF5350"
    style.font-color: white
  }
  s4: awx-receptor-ca {
    shape: document
    style.fill: "#EF5350"
    style.font-color: white
  }
}

pvcs: PersistentVolumeClaims {
  style.fill: "#E0F7FA"
  
  pvc1: awx-projects\n(Playbook storage) {
    shape: cylinder
    style.fill: "#00BCD4"
    style.font-color: white
  }
  pvc2: postgres-13-awx-postgres-13-0\n(Database) {
    shape: cylinder
    style.fill: "#00BCD4"
    style.font-color: white
  }
}

ingress: Ingress (if enabled) {
  style.fill: "#FCE4EC"
  
  ing: awx-ingress {
    shape: rectangle
    style.fill: "#E91E63"
    style.font-color: white
  }
}

awx_cr -> deployments: creates
awx_cr -> statefulsets: creates
awx_cr -> services: creates
awx_cr -> configmaps: creates
awx_cr -> secrets: creates
awx_cr -> pvcs: creates
awx_cr -> ingress: creates
```

## Configuration

### Complete AWX Spec Reference

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  # --- Deployment Settings ---
  replicas: 1                    # Number of web replicas
  
  # --- Image Configuration ---
  image: quay.io/ansible/awx
  image_version: 24.0.0
  image_pull_policy: IfNotPresent
  image_pull_secrets:
    - name: registry-secret
  
  # --- Web Pod Settings ---
  web_replicas: 2
  web_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  web_extra_env: |
    - name: CUSTOM_VAR
      value: "custom_value"
  
  # --- Task Pod Settings ---
  task_replicas: 2
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  task_extra_env: |
    - name: ANSIBLE_FORCE_COLOR
      value: "true"
  
  # --- Execution Environment ---
  control_plane_ee_image: quay.io/ansible/awx-ee:latest
  ee_resource_requirements:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  # --- PostgreSQL (Managed) ---
  postgres_storage_class: standard
  postgres_storage_requirements:
    requests:
      storage: 20Gi
    limits:
      storage: 50Gi
  postgres_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  # --- PostgreSQL (External) ---
  # postgres_configuration_secret: awx-external-postgres
  
  # --- Redis ---
  redis_image: redis:7
  redis_resource_requirements:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  # --- Service Configuration ---
  service_type: ClusterIP  # ClusterIP, NodePort, LoadBalancer
  service_annotations: |
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
  
  # --- Ingress Configuration ---
  ingress_type: ingress  # none, ingress, route
  hostname: awx.example.com
  ingress_annotations: |
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  ingress_tls_secret: awx-tls
  ingress_class_name: nginx
  
  # --- Route Configuration (OpenShift) ---
  # route_tls_termination_mechanism: Edge
  # route_tls_secret: awx-route-tls
  
  # --- Projects Storage ---
  projects_persistence: true
  projects_storage_class: standard
  projects_storage_size: 10Gi
  projects_storage_access_mode: ReadWriteOnce
  
  # --- Admin Configuration ---
  admin_user: admin
  admin_password_secret: awx-admin-password
  
  # --- Extra Settings ---
  extra_settings:
    - setting: REMOTE_HOST_HEADERS
      value:
        - HTTP_X_FORWARDED_FOR
    - setting: CSRF_TRUSTED_ORIGINS
      value:
        - https://awx.example.com
  
  # --- Node Selection ---
  node_selector: |
    node-role.kubernetes.io/worker: ""
  tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "awx"
      effect: "NoSchedule"
  topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: ScheduleAnyway
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: awx-web
  
  # --- Security Context ---
  security_context_settings:
    runAsGroup: 0
    runAsUser: 0
    fsGroup: 0
    fsGroupChangePolicy: OnRootMismatch
  
  # --- Garbage Collection ---
  garbage_collect_secrets: false
  set_self_labels: true
```

### External PostgreSQL Configuration

```yaml
# awx-external-postgres secret
apiVersion: v1
kind: Secret
metadata:
  name: awx-external-postgres
  namespace: awx
type: Opaque
stringData:
  host: postgres.example.com
  port: "5432"
  database: awx
  username: awx
  password: securepassword
  sslmode: require
  type: managed  # or 'unmanaged'
```

### AWXBackup Configuration

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWXBackup
metadata:
  name: awx-backup-daily
  namespace: awx
spec:
  # AWX instance to backup
  deployment_name: awx
  
  # Backup storage
  backup_pvc: awx-backup-pvc
  backup_pvc_namespace: awx
  
  # Or use storage class
  # backup_storage_class: standard
  # backup_storage_requirements: 10Gi
  
  # What to backup
  postgres_label_selector: app.kubernetes.io/name=awx-postgres
  
  # Cleanup
  clean_backup_on_delete: true
```

### AWXRestore Configuration

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWXRestore
metadata:
  name: awx-restore
  namespace: awx
spec:
  # Backup to restore from
  backup_name: awx-backup-daily
  
  # New AWX instance name
  deployment_name: awx-restored
  
  # Restore options
  restore_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
```

## RBAC Configuration

### Operator Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: awx-operator-controller-manager
  namespace: awx
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: awx-operator-manager-role
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets", "services", "persistentvolumeclaims"]
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["*"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["*"]
  - apiGroups: ["route.openshift.io"]
    resources: ["routes"]
    verbs: ["*"]
  - apiGroups: ["awx.ansible.com"]
    resources: ["awxs", "awxbackups", "awxrestores"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: awx-operator-manager-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: awx-operator-manager-role
subjects:
  - kind: ServiceAccount
    name: awx-operator-controller-manager
    namespace: awx
```

## Monitoring

### Operator Metrics

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: awx-operator
  namespace: awx
spec:
  selector:
    matchLabels:
      control-plane: controller-manager
  endpoints:
    - port: https
      path: /metrics
      scheme: https
      tlsConfig:
        insecureSkipVerify: true
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `controller_runtime_reconcile_total` | Total reconciliations | N/A (tracking) |
| `controller_runtime_reconcile_errors_total` | Reconciliation errors | > 0 |
| `controller_runtime_reconcile_time_seconds` | Reconciliation duration | p95 > 60s |
| `workqueue_depth` | Items in work queue | > 10 |
| `workqueue_adds_total` | Items added to queue | Spike detection |

## Upgrade Strategy

```yaml
# Upgrade operator
kubectl apply -k github.com/ansible/awx-operator/config/default?ref=2.13.0

# Upgrade AWX version
kubectl patch awx awx -n awx --type merge -p '{"spec":{"image_version":"24.1.0"}}'

# Watch upgrade progress
kubectl get pods -n awx -w
```

### Upgrade Considerations

| From | To | Notes |
|------|-----|-------|
| 2.11.x | 2.12.x | Database migration required |
| 23.x | 24.x | AWX image version change |
| < 2.0 | 2.x | Major breaking changes |
