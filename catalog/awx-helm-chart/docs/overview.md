# Overview

## Architecture Deep Dive

### AWX Operator Pattern

The AWX Helm Chart leverages the Kubernetes Operator pattern, using the AWX Operator to manage the complete lifecycle of AWX instances:

```d2
direction: right

reconciliation: AWX Operator Reconciliation Loop {
  watch: Watch AWX CRs {
    shape: hexagon
  }
  compare: Compare Desired vs Actual {
    shape: hexagon
  }
  manage: Create/Update/Delete Kubernetes Resources {
    shape: hexagon
  }

  watch -> compare -> manage
  manage -> watch: Continuous Loop {
    style.stroke-dash: 3
  }
}

resources: Resources Managed by Operator {
  deployments: Deployments {
    web: awx-web
    task: awx-task
    ee: awx-ee
  }
  services: Services {
    svc: awx-service
    receptor: awx-receptor
    postgres: postgres
  }
  secrets: Secrets {
    admin: admin-password
    db: db-credentials
    tls: receptor-tls
  }
  pvcs: PVCs {
    projects: projects
    ca: receptor-ca
    cache: ee-cache
  }
}

reconciliation -> resources: manages
```

### Component Interactions

```d2
direction: down

user: User Request {
  shape: person
}

ingress_layer: {
  ingress: Ingress
  nginx: NGINX (proxy) {
    shape: hexagon
  }
  ingress -> nginx
}

web: AWX Web Pod {
  django: Django Application {
    api: REST API (/api/v2/)
    ws: WebSocket (/websocket/)
    static: Static files
  }
}

data_layer: {
  redis: Redis (Queue) {
    shape: cylinder
  }
  postgres: PostgreSQL Database {
    shape: cylinder
  }
}

task: AWX Task Pod {
  shape: hexagon
}

ee: Execution Env Container (ansible-run) {
  shape: hexagon
}

user -> ingress_layer.ingress
ingress_layer.nginx -> web
web -> data_layer.redis
web -> data_layer.postgres
web -> task
data_layer.redis -> task: Job Dispatch via Redis
task -> ee
```

## Configuration Reference

### Core Values

```yaml
# values.yaml - Complete configuration reference

# AWX Operator Configuration
operator:
  # Operator image settings
  image:
    repository: quay.io/ansible/awx-operator
    tag: 2.10.0
    pullPolicy: IfNotPresent

  # Operator resources
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi

  # Watch all namespaces or specific namespace
  watchNamespace: '' # Empty = watch all

  # Operator replicas (1 is sufficient)
  replicas: 1

# AWX Instance Configuration
AWX:
  # Enable AWX instance creation
  enabled: true

  # AWX instance name
  name: awx

  # AWX specification (maps to AWX CRD spec)
  spec:
    # Admin user configuration
    admin_user: admin
    admin_email: admin@example.com

    # AWX image settings
    image: quay.io/ansible/awx
    image_version: 24.0.0
    image_pull_policy: IfNotPresent

    # Web pod configuration
    web_replicas: 2
    web_resource_requirements:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 2000m
        memory: 4Gi

    # Task pod configuration
    task_replicas: 2
    task_resource_requirements:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 4000m
        memory: 8Gi

    # Redis configuration
    redis_image: docker.io/redis
    redis_image_version: '7'
    redis_resource_requirements:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 1Gi

    # PostgreSQL configuration
    postgres_configuration_secret: '' # Use external DB
    postgres_storage_class: ''
    postgres_storage_requirements:
      requests:
        storage: 20Gi

    # Projects persistence
    projects_persistence: true
    projects_storage_class: ''
    projects_storage_size: 10Gi
    projects_storage_access_mode: ReadWriteMany

    # Execution environments
    ee_images:
      - name: AWX EE (latest)
        image: quay.io/ansible/awx-ee:latest
      - name: Minimal EE
        image: quay.io/ansible/ansible-runner:latest

    # Extra configuration
    extra_settings:
      - setting: ALLOW_OAUTH2_FOR_EXTERNAL_USERS
        value: 'True'
      - setting: AUTH_LDAP_SERVER_URI
        value: 'ldap://ldap.example.com'
```

### Ingress Configuration

```yaml
# Ingress settings
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: '100m'
    nginx.ingress.kubernetes.io/proxy-read-timeout: '600'
    nginx.ingress.kubernetes.io/proxy-send-timeout: '600'
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

# Alternative: OpenShift Route
route:
  enabled: false
  host: awx.apps.openshift.example.com
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

### Database Configuration

```yaml
# Internal PostgreSQL (default)
postgres:
  enabled: true
  image: postgres
  version: '15'
  storage:
    class: standard
    size: 20Gi
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 2Gi

# External PostgreSQL
externalDatabase:
  enabled: false
  host: postgres.example.com
  port: 5432
  database: awx
  username: awx
  existingSecret: awx-db-credentials
  existingSecretPasswordKey: password
  sslmode: require
```

### Authentication Backends

```yaml
# LDAP Configuration
ldap:
  enabled: true
  serverUri: 'ldap://ldap.example.com:389'
  bindDn: 'cn=awx,ou=services,dc=example,dc=com'
  bindPassword: ''
  existingSecret: awx-ldap-credentials
  userSearch:
    - 'ou=users,dc=example,dc=com'
    - '(uid=%(user)s)'
  groupSearch:
    - 'ou=groups,dc=example,dc=com'
    - '(objectClass=groupOfNames)'
  userAttrMap:
    first_name: givenName
    last_name: sn
    email: mail

# SAML Configuration
saml:
  enabled: false
  entityId: 'https://awx.example.com/sso/metadata/saml/'
  idpMetadataUrl: 'https://idp.example.com/metadata'
  orgInfo:
    name: 'Example Corp'
    displayName: 'Example Corporation'
    url: 'https://example.com'

# OAuth2/OIDC Configuration
oauth2:
  enabled: false
  providers:
    github:
      key: ''
      secret: ''
      existingSecret: awx-github-oauth
    google:
      key: ''
      secret: ''
      existingSecret: awx-google-oauth
```

## Security Configuration

### Network Policies

```yaml
# Network policy for AWX pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: awx-network-policy
  namespace: awx
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: awx
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8052
    # Allow internal AWX communication
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: awx
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
    # Allow PostgreSQL
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: awx-postgres
      ports:
        - protocol: TCP
          port: 5432
    # Allow Redis
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: awx-redis
      ports:
        - protocol: TCP
          port: 6379
    # Allow external managed hosts
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
      ports:
        - protocol: TCP
          port: 22
```

### Pod Security Standards

```yaml
# Pod Security Context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Secrets Management

```yaml
# External secrets with External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: awx-admin-password
  namespace: awx
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault-backend
  target:
    name: awx-admin-password
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: secret/awx/admin
        property: password

---
# HashiCorp Vault integration
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: awx-db-credentials
  namespace: awx
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault-backend
  target:
    name: awx-db-credentials
  dataFrom:
    - extract:
        key: secret/awx/database
```

## Monitoring and Observability

### Prometheus Metrics

```yaml
# ServiceMonitor for Prometheus Operator
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: awx-metrics
  namespace: awx
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: awx
  endpoints:
    - port: metrics
      interval: 30s
      path: /api/v2/metrics/
      basicAuth:
        username:
          name: awx-metrics-auth
          key: username
        password:
          name: awx-metrics-auth
          key: password
  namespaceSelector:
    matchNames:
      - awx
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "AWX Metrics",
    "panels": [
      {
        "title": "Active Jobs",
        "targets": [
          {
            "expr": "awx_running_jobs_total",
            "legendFormat": "Running Jobs"
          }
        ]
      },
      {
        "title": "Pending Jobs",
        "targets": [
          {
            "expr": "awx_pending_jobs_total",
            "legendFormat": "Pending Jobs"
          }
        ]
      },
      {
        "title": "Job Success Rate",
        "targets": [
          {
            "expr": "rate(awx_jobs_total{status=\"successful\"}[5m]) / rate(awx_jobs_total[5m]) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      }
    ]
  }
}
```

### Logging Configuration

```yaml
# Fluent Bit sidecar for log collection
extraContainers:
  - name: fluent-bit
    image: fluent/fluent-bit:2.2
    volumeMounts:
      - name: varlog
        mountPath: /var/log
      - name: fluent-bit-config
        mountPath: /fluent-bit/etc/
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 50m
        memory: 64Mi

extraVolumes:
  - name: varlog
    emptyDir: {}
  - name: fluent-bit-config
    configMap:
      name: awx-fluent-bit-config
```

## High Availability

### Multi-Replica Configuration

```yaml
# Production HA configuration
AWX:
  spec:
    # Multiple web replicas behind load balancer
    web_replicas: 3

    # Multiple task workers for parallel execution
    task_replicas: 3

    # Pod disruption budget
    web_pdb:
      minAvailable: 2
    task_pdb:
      minAvailable: 2

    # Anti-affinity for spreading across nodes
    web_affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/component: awx-web
              topologyKey: kubernetes.io/hostname

    task_affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/component: awx-task
              topologyKey: kubernetes.io/hostname
```

### Database HA

```yaml
# External PostgreSQL with CloudNativePG
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: awx-postgres-cluster
  namespace: awx
spec:
  instances: 3
  primaryUpdateStrategy: unsupervised

  storage:
    size: 50Gi
    storageClass: fast-ssd

  postgresql:
    parameters:
      max_connections: '200'
      shared_buffers: '256MB'

  backup:
    barmanObjectStore:
      destinationPath: s3://awx-backups/postgres
      s3Credentials:
        accessKeyId:
          name: s3-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: s3-creds
          key: SECRET_ACCESS_KEY
    retentionPolicy: '30d'
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Installation, examples, and troubleshooting
