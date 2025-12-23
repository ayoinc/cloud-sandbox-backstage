# AWX Deployment Template

This template creates production-ready AWX (Ansible Automation Platform) deployments on Kubernetes, enabling enterprise automation at scale.

## Overview

**AWX** is the open-source version of Ansible Tower, providing a web-based user interface and RESTful API for managing and executing Ansible automation. It enables organizations to:

- Centralize automation management and execution
- Enable self-service automation for teams
- Provide role-based access control (RBAC)
- Track automation history and audit trails
- Scale automation across thousands of endpoints
- Integrate with CI/CD pipelines

### Use Cases

- **Infrastructure as Code**: Automate cloud provisioning, configuration management
- **Application Deployment**: Streamline application releases and updates
- **Network Automation**: Manage network devices and configurations
- **Security Automation**: Automate security compliance and incident response
- **Disaster Recovery**: Automated backup and recovery procedures
## Features

This template provides a comprehensive AWX deployment with the following capabilities:

### Core Features

- **Kubernetes-Native Deployment**: Built on Kubernetes operator pattern
- **High Availability**: Production-ready with multi-replica deployments
- **External PostgreSQL**: Production-grade database setup with persistent storage
- **Enterprise Authentication**: LDAP/AD and SSO integration
- **Ingress Integration**: External access with SSL/TLS termination
- **Resource Management**: Configurable CPU, memory, and storage
- **Backup and Recovery**: Automated backup strategies
- **Monitoring Ready**: Observability and logging integration

### Enterprise Features

- **Multi-Environment Support**: Development, staging, and production configurations
- **GitOps Ready**: Compatible with ArgoCD and Flux for GitOps workflows
- **Security Hardened**: Network policies, RBAC, and secret management
- **Scalable Architecture**: Independent web, task, and execution environment pods
- **Storage Management**: Persistent volumes for projects, databases, and configurations
## Prerequisites

### Infrastructure Requirements

- **Kubernetes Cluster**: Version 1.19 or higher
  - Recommended: 3+ worker nodes for HA
  - Minimum: 4 CPU cores, 16GB RAM, 100GB storage
- **Kubernetes CLI**: `kubectl` configured with cluster access
- **Package Manager**: Helm 3.x (optional, for operator installation)
- **Container Registry**: Access to `quay.io` for AWX images

### Database Requirements

- **PostgreSQL**: Version 12+
  - External PostgreSQL: Production recommendation
  - Managed PostgreSQL: AWS RDS, Azure Database, Cloud SQL
  - Local PostgreSQL: For development/testing only
- **Storage**: Minimum 8GB for PostgreSQL data
- **Network**: Cluster-to-database connectivity on port 5432

### Storage Requirements

- **Storage Classes**: At least one configured storage class
  - For PostgreSQL: Any standard storage class (e.g., `gp3`, `standard`)
  - For Projects: **ReadWriteMany** capable storage class required
    - Recommended: NFS, EFS, CephFS, Portworx
- **Capacity Planning**:
  - PostgreSQL: 8GB minimum, 50GB+ for large deployments
  - Projects: 8GB minimum, 100GB+ for many projects

### Networking Requirements

- **Ingress Controller**: NGINX ingress controller or compatible
- **Cert-Manager** (optional): For automatic SSL certificate management
- **Network Policies**: Configured to allow internal pod communication
- **DNS**: DNS records for the AWX hostname

### Security Requirements

- **RBAC**: Kubernetes RBAC enabled
- **Service Accounts**: Ability to create service accounts
- **Network Policies**: Supported by cluster CNI plugin
- **Secret Management**: Kubernetes secrets encryption at rest recommended

### Tooling Requirements

- **Git**: Version control for configurations
- **CI/CD** (optional): ArgoCD, Flux, or GitHub Actions
- **Monitoring** (optional): Prometheus, Grafana
- **Logging** (optional): ELK/EFK stack or similar

## Configuration Options

All template parameters from `template.yaml` with detailed explanations:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | AWX instance name (lowercase, hyphen-separated) |
| `namespace` | string | Yes | `awx` | Kubernetes namespace for deployment |
| `owner` | string | Yes | - | Owner entity from Backstage catalog |
| `environment` | enum | Yes | `development` | Deployment environment: `development`, `staging`, `production` |
| `repoUrl` | string | Yes | - | Git repository URL for storing configurations |
| `awx_version` | string | No | `latest` | AWX version tag (e.g., `21.14.0`)
| `service_type` | enum | No | `ClusterIP` | Kubernetes service type: `ClusterIP`, `NodePort`, `LoadBalancer` |
| `ingress_enabled` | boolean | No | `true` | Enable ingress for external access |
| `hostname` | string | No* | `awx.example.com` | Hostname for AWX access (required if ingress enabled) |
| `storage_class` | string | No | `default` | Storage class for persistent volumes |
| `postgres_storage_size` | string | No | `8Gi` | PostgreSQL storage capacity |
| `project_storage_size` | string | No | `8Gi` | Project storage capacity |
| `admin_user` | string | No | `admin` | AWX administrator username |
| `ssl_enabled` | boolean | No | `true` | Enable SSL/TLS encryption |
| `ldap_enabled` | boolean | No | `false` | Enable LDAP authentication |

**Note:** `hostname` is required when `ingress_enabled` is `true`

### Environment-Specific Configurations

```yaml
# Development
replicas: 1
auto_upgrade: true
resource_requests: lower

# Staging
replicas: 1
auto_upgrade: true
resource_requests: medium

# Production
replicas: 2
auto_upgrade: false
resource_requests: higher
```

### Resource Requirements by Environment

| Component | Development | Staging | Production |
|-----------|-------------|---------|------------|
| **Web Pod** | 0.5-1 CPU / 1-2GB | 1-1.5 CPU / 1-2GB | 1-2 CPU / 2-4GB |
| **Task Pod** | 0.25-0.5 CPU / 0.5-1GB | 0.5-1 CPU / 1-2GB | 0.5-1 CPU / 1-2GB |
| **EE Pod** | 0.25-0.5 CPU / 0.5-1GB | 0.5-1 CPU / 1-2GB | 0.5-1 CPU / 1-2GB |
| **Redis Pod** | 0.25-0.5 CPU / 0.5-1GB | 0.5-1 CPU / 1-2GB | 0.5-1 CPU / 1-2GB |
## Getting Started

### Step 1: Create Template Instance

```bash
# Using Backstage UI
1. Navigate to Create → AWX Deployment
2. Fill in all required parameters
3. Generate repository and configurations

# Or via Backstage API
curl -X POST https://backstage-api.example.com/api/scaffolder/v2/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -d @awx-config.json
```

### Step 2: Clone and Review Configuration

```bash
# Clone generated repository
git clone https://github.com/your-org/${AWX_NAME}-awx-deployment.git
cd ${AWX_NAME}-awx-deployment

# Review generated files
ls -la k8s/
cat k8s/awx.yaml
cat k8s/secrets.yaml

# Update passwords in secrets.yaml
# Note: Change default passwords before deployment
```

### Step 3: Install AWX Operator (One-Time Setup)

```bash
# Latest stable version
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/stable/deploy/awx-operator.yaml

# Wait for operator to be ready
kubectl wait deployment awx-operator-controller-manager \
  -n awx-operator \
  --for condition=Available=True \
  --timeout=300s

# Verify operator
kubectl get pods -n awx-operator
```

### Step 4: Deploy AWX Instance

```bash
# Using automated script
chmod +x deploy.sh
./deploy.sh deploy

# Or manual deployment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/awx.yaml

# Or using Kustomize
kubectl apply -k k8s/
```

### Step 5: Monitor Deployment Progress

```bash
# Watch deployment status
./deploy.sh status

# Monitor pods
kubectl get pods -n ${NAMESPACE} -w

# Check AWX resource
describe awx ${AWX_NAME} -n ${NAMESPACE}

# Follow operator logs
kubectl logs -n awx-operator deployment/awx-operator-controller-manager -f
```

### Step 6: Access AWX UI

#### Via Ingress (Recommended)

```bash
# Get the URL
echo "https://${AWX_HOSTNAME}"

# Default credentials:
# Username: admin (or your configured admin_user)
# Password: From deployment output or secret
kubectl get secret awx-${AWX_NAME}-admin-password \
  -n ${NAMESPACE} \
  -o jsonpath='{.data.password}' | base64 -d
```

#### Via Port Forwarding (Development)

```bash
# Port forward cluster IP service
kubectl port-forward -n ${NAMESPACE} svc/awx-${AWX_NAME}-service 8080:80

# Access locally
open http://localhost:8080
```

#### Via NodePort

```bash
# Get node port
kubectl get svc -n ${NAMESPACE}

# Access via:
# http://node-ip:node-port/
```

#### Via LoadBalancer

```bash
# Get external IP (Cloud provider)
kubectl get svc -n ${NAMESPACE} awx-${AWX_NAME}-service

# Access via:
# http://external-ip/
```

### Step 7: Initial Configuration

```bash
# Log in to AWX UI
# Navigate to Settings

# Recommended initial setup:
1. Change admin password
2. Configure organizations and teams
3. Set up credentials
4. Create inventory
5. Configure projects (Git repos or local)
6. Create job templates
7. Set up notifications

# If LDAP enabled:
# - LDAP configuration is pre-configured
# - Map LDAP groups to AWX teams
# - Configure authentication backends
```

## Deployment Architecture

### Operator Pattern

The deployment uses the **Kubernetes Operator pattern** for managing AWX lifecycle:

```
┌─────────────────────────────────────────────────────────────┐
│                    Backstage Platform                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Template Generation Service                     │
│          (Generates customized AWX manifests)               │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Kubernetes API Server                       │
│                                                              │
│            ┌────────────────────────────────┐                │
│            │     AWX Operator Controller    │                │
│            │         (Reconciliation)       │                │
│            └────────┬───────────────────────┘                │
│                     │                                        │
│                     ▼                                        │
│         ┌────────────────────────┐                         │
│         │   AWX Custom Resource  │                         │
│         │  (awx-${{ values.name }})  │                         │
│         └────┬───────────────────┘                         │
│              │                                             │
│              ▼                                             │
│  ┌─────────────────────────────────────────────────┐       │
│  │  Kubernetes Resources Generated by Operator     │       │
│  │                                                 │       │
│  │  ┌────────────────────────────────────┐         │
│  │  │  Deployment: awx-web              │         │
│  │  │  (Web UI/API pods)                │         │
│  │  └────────────────────────────────────┘         │
│  │                                                 │
│  │  ┌────────────────────────────────────┐         │
│  │  │  Deployment: awx-task             │         │
│  │  │  (Background task processor)      │         │
│  │  └────────────────────────────────────┘         │
│  │                                                 │
│  │  ┌────────────────────────────────────┐         │
│  │  │  Deployment: awx-ee               │         │
│  │  │  (Execution environment)          │         │
│  │  └────────────────────────────────────┘         │
│  │                                                 │
│  │  ┌────────────────────────────────────┐         │
│  │  │  StatefulSet: awx-postgres-13     │         │
│  │  │  (PostgreSQL database)            │         │
│  │  └────────────────────────────────────┘         │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
│  ┌─────────────────────────────────────────────────┐       │
│  │      Persistent Volumes & Claims                │       │
│  │                                                 │       │
│  │  - PVC: awx-postgres                            │       │
│  │  - PVC: awx-projects                            │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
│  ┌─────────────────────────────────────────────────┐       │
│  │          Networking & Services                  │       │
│  │                                                 │       │
│  │  - Service: awx-${{ values.name }}-service      │       │
│  │  - Secret: *-admin-password                    │       │
│  │  - Secret: *-postgres-configuration            │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
│  ┌─────────────────────────────────────────────────┐       │
│  │          Ingress (if enabled)                   │       │
│  │                                                 │
│  │  - Ingress: awx-${{ values.name }}-ingress      │       │
│  │  - TLS: *-tls (cert-manager)                   │       │
│  └─────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────┘
```

### Custom Resource Definition (CRD)

The AWX operator extends Kubernetes with a custom resource:

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-instance
spec:
  # Operator watches and reconciles this resource
  # Creates dependent deployments, services, PVCs
```

### Component Breakdown

1. **Operator Controller**: Managing CRD lifecycle
2. **Web Pod**: Django application server, API endpoints
3. **Task Pod**: Celery worker for background jobs
4. **EE Pod**: Execution environment for running playbooks
5. **Redis Pod**: Caching and task queue management
6. **PostgreSQL**: Persistent data storage

### Data Flow

```
User Request (Browser/CLI)
    ↓
Ingress Controller
    ↓
AWX Service
    ↓
AWX Web Pods (Django)
    ├─→ Redis (Task Queue)
    ├─→ PostgreSQL (Data Storage)
    └─→ AWX Task Pods (Celery Workers)
          ↓
    AWX EE Pods (Playbook Execution)
          ↓
    Managed Infrastructure/Apps
```

### Scaling Architecture

**Horizontal Scaling**:
```yaml
spec:
  replicas: 3  # Scales web pods
  web_resource_requirements:
    replicas: 3
  task_resource_requirements:
    replicas: 3  # For multiple task workers
```

**Vertical Scaling**:
```yaml
spec:
  web_resource_requirements:
    requests:
      cpu: 2000m    # 2 cores
      memory: 4Gi   # 4GB
    limits:
      cpu: 4000m    # 4 cores
      memory: 8Gi   # 8GB
```

## Kubernetes Resources

### Deployed by Operator

The AWX operator automatically creates and manages these resources based on the AWX CRD:

#### 1. AWX Custom Resource

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ${AWX_NAME}
  namespace: ${NAMESPACE}
spec:
  # Configuration as code
```

#### 2. Deployments

**Web Deployment (awx-${NAME}-web)**:
```yaml
# Creates: 
# - Pods: Django application server
# - Replicas: Configurable (1 for dev/staging, 2+ for prod)
# - Ports: 8052 (internal)
# - Resources: Configurable CPU/memory
apiVersion: apps/v1
kind: Deployment
metadata:
  name: awx-${NAME}-web
spec:
  template:
    spec:
      containers:
      - name: awx-web
        image: quay.io/ansible/awx
        ports:
        - containerPort: 8052
```

**Task Deployment (awx-${NAME}-task)**:
```yaml
# Creates:
# - Pods: Celery task workers
# - Replicas: 1 (can scale)
# - Resources: Configurable for job processing
apiVersion: apps/v1
kind: Deployment
metadata:
  name: awx-${NAME}-task
```

**Execution Environment Deployment (awx-${NAME}-ee)**:
```yaml
# Creates:
# - Pods: Isolated execution environment
# - Replicas: 1 per task pod
# - Resources: Matches task resource requirements
apiVersion: apps/v1
kind: Deployment
metadata:
  name: awx-${NAME}-ee
```

**Redis Deployment (awx-${NAME}-redis)**:
```yaml
# Creates:
# - Pods: Redis for caching and queuing
# - Replicas: 1 (or HA setup for production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: awx-${NAME}-redis
```

#### 3. StatefulSet (PostgreSQL)

```yaml
# Creates:
# - Pods: PostgreSQL database
# - Replicas: 1 (recommend external HA for production)
# - Persistent Volume: For data
# - Service: Internal cluster access
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: awx-${NAME}-postgres-13
spec:
  serviceName: awx-${NAME}-postgres-13
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:13
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: ${POSTGRES_STORAGE_SIZE}
```

#### 4. Services

**AWX Service**:
```yaml
# Creates:
# - Type: Configurable (ClusterIP, NodePort, LoadBalancer)
# - Port: 80 (or custom)
# - Selector: Routes to web pods
apiVersion: v1
kind: Service
metadata:
  name: awx-${NAME}-service
spec:
  type: ${SERVICE_TYPE}
  ports:
  - port: 80
    targetPort: 8052
  selector:
    app.kubernetes.io/name: awx-${NAME}-web
```

**PostgreSQL Service**:
```yaml
# Creates:
# - Type: ClusterIP
# - Port: 5432
# - Selector: Routes to postgres pod
apiVersion: v1
kind: Service
metadata:
  name: awx-${NAME}-postgres-13
spec:
  ports:
  - port: 5432
```

**Redis Service**:
```yaml
# Creates:
# - Type: ClusterIP
# - Port: 6379
# - Selector: Routes to redis pod
apiVersion: v1
kind: Service
metadata:
  name: awx-${NAME}-redis
spec:
  ports:
  - port: 6379
```

#### 5. Persistent Volume Claims

**PostgreSQL PVC**:
```yaml
# Creates:
# - AccessMode: ReadWriteOnce
# - Storage: Configurable (default: 8Gi)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-${NAME}-postgres-13-0
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: ${POSTGRES_STORAGE_SIZE}
  storageClassName: ${STORAGE_CLASS}
```

**Project Storage PVC**:
```yaml
# Creates:
# - AccessMode: ReadWriteMany (required for multi-pod access)
# - Storage: Configurable (default: 8Gi)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${NAME}-projects-claim
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: ${PROJECT_STORAGE_SIZE}
  storageClassName: ${STORAGE_CLASS}
```

#### 6. Secrets

**Admin Password Secret**:
```yaml
# Creates:
# - Type: Opaque
# - Key: password
# - Value: Base64 encoded password
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-admin-password
type: Opaque
data:
  password: YWRtaW4xMjM=  # FIXME: CHANGE BEFORE PRODUCTION!
```

**PostgreSQL Configuration Secret**:
```yaml
# Creates:
# - Type: Opaque
# - Contains: host, port, database, username, password
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-postgres-configuration
type: Opaque
stringData:
  host: awx-${NAME}-postgres-13
  port: "5432"
  database: awx
  username: awx
  password: awxpass123  # FIXME: CHANGE BEFORE PRODUCTION!
  sslmode: prefer
  type: managed
```

**TLS Secret** (if SSL enabled):
```yaml
# Creates:
# - Type: kubernetes.io/tls
# - Managed by: cert-manager (if annotations present)
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-tls
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
type: kubernetes.io/tls
data:
  tls.crt: |
    # Certificate data
  tls.key: |
    # Private key data
```

**LDAP CA Certificate Secret** (if LDAP enabled):
```yaml
# Creates:
# - Type: Opaque
# - Contains: LDAP CA certificate
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-ldap-cacert
type: Opaque
data:
  ldap-cacert.crt: |
    # LDAP CA certificate
```

#### 7. Ingress (Optional)

```yaml
# Creates:
# - Host: Configured hostname
# - TLS: Optional SSL termination
# - Routes: External → Service → Pod
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: awx-${NAME}-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
  - host: ${HOSTNAME}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: awx-${NAME}-service
            port:
              number: 80
  tls:
  - hosts:
    - ${HOSTNAME}
    secretName: awx-${NAME}-tls
```

#### 8. ConfigMaps and Extra Settings

```yaml
# Creates:
# - Environment variables
# - Django settings
# - Custom AWX configurations
apiVersion: awx.ansible.com/v1beta1
kind: AWX
spec:
  extra_settings:
    - setting: SYSTEM_TASK_ABS_CPU
      value: 6
    - setting: SYSTEM_TASK_ABS_MEM
      value: 20
```

### Resource Overview Table

| Resource Type | Resource Name | Purpose | Quantity |
|---------------|---------------|---------|----------|
| **Custom Resource** | awx-${NAME} | AWX instance definition | 1 |
| **Deployment** | awx-${NAME}-web | Web UI/API server | 1-3 replicas |
| **Deployment** | awx-${NAME}-task | Background tasks | 1-3 replicas |
| **Deployment** | awx-${NAME}-ee | Execution environment | 1-3 replicas |
| **Deployment** | awx-${NAME}-redis | Cache/queue | 1 replica |
| **StatefulSet** | awx-${NAME}-postgres-13 | Database | 1 pod |
| **Service** | awx-${NAME}-service | Main service | 1 |
| **Service** | awx-${NAME}-postgres-13 | Database service | 1 |
| **Service** | awx-${NAME}-redis | Redis service | 1 |
| **PVC** | postgres-${NAME}-postgres-13-0 | Database storage | 1 |
| **PVC** | ${NAME}-projects-claim | Project storage | 1 |
| **Secret** | awx-${NAME}-admin-password | Admin credentials | 1 |
| **Secret** | awx-${NAME}-postgres-configuration | Database creds | 1 |
| **Secret** | awx-${NAME}-tls | TLS certificate | 1 (if SSL) |
| **Secret** | awx-${NAME}-ldap-cacert | LDAP CA cert | 1 (if LDAP) |
| **Ingress** | awx-${NAME}-ingress | External access | 1 (if enabled) |

### kubectl Commands for Resource Management

```bash
# List all AWX resources
kubectl get all -n ${NAMESPACE} -l app.kubernetes.io/name=awx-${NAME}

# Get detailed resource information
kubectl describe awx ${NAME} -n ${NAMESPACE}
kubectl describe deployment awx-${NAME}-web -n ${NAMESPACE}
kubectl describe statefulset awx-${NAME}-postgres-13 -n ${NAMESPACE}

# View pod logs
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-web
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-task
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-ee

# Check persistent volumes
kubectl get pvc -n ${NAMESPACE}
kubectl get pv

# Verify secrets (do not expose sensitive data)
kubectl get secrets -n ${NAMESPACE}

# Monitor resource usage
kubectl top pods -n ${NAMESPACE}
kubectl top nodes

# Debug pod issues
kubectl describe pod <pod-name> -n ${NAMESPACE}
kubectl exec -it <pod-name> -n ${NAMESPACE} -- /bin/bash
```
## Database Configuration

### PostgreSQL Database Options

The deployment supports three database configurations:

#### 1. Managed PostgreSQL (Default - Development)

Best for: **Quick setup, development, testing**

```yaml
# In awx.yaml
spec:
  postgres_configuration_secret: awx-${NAME}-postgres-configuration
  
# In secrets.yaml --
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-postgres-configuration
type: Opaque
stringData:
  host: awx-${NAME}-postgres-13
  port: "5432"
  database: awx
  username: awx
  password: awxpass123  # CHANGE THIS!
  sslmode: prefer
  type: managed
```

**Pros:**
- Zero external dependencies
- Self-contained in Kubernetes
- Easy backup/restore

**Cons:**
- Single point of failure
- Not recommended for production
- Requires manual HA setup

**Setup:**
```bash
# Operator automatically creates PostgreSQL StatefulSet
kubectl apply -f k8s/secrets.yaml  # Contains DB credentials
kubectl apply -f k8s/awx.yaml
```

#### 2. External PostgreSQL (Recommended for Production)

Best for: **Production, HA requirements, existing infrastructure**

```yaml
# In secrets.yaml --
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-postgres-configuration
type: Opaque
stringData:
  host: postgres-prod.example.com
  port: "5432"
  database: awx_production
  username: awx_user
  password: "${EXTERNAL_DB_PASSWORD}"  # Set via environment or secret
  sslmode: require
  type: unmanaged
```

**Pros:**
- Managed database service
- High availability built-in
- Professional backup/restore
- Connection pooling
- Monitoring and alerting

**Cons:**
- External dependency
- Network connectivity required
- Additional cost

**Setup for AWS RDS:**
```bash
# 1. Create RDS PostgreSQL instance
aws rds create-db-instance \
  --db-instance-identifier awx-postgres-prod \
  --db-instance-class db.m5.large \
  --engine postgres \
  --engine-version 13.7 \
  --allocated-storage 100 \
  --master-username awx_master \
  --master-user-password "${DB_PASSWORD}" \
  --vpc-security-group-ids sg-xxxxxxxx \
  --db-subnet-group-name awx-db-subnet

# 2. Create database and user
psql -h awx-postgres-prod.xxxxxx.us-east-1.rds.amazonaws.com \
  -U awx_master -d postgres <<EOF
CREATE DATABASE awx_production;
CREATE USER awx_user WITH PASSWORD '$AWX_DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE awx_production TO awx_user;
EOF

# 3. Update secrets
kubectl create secret generic awx-${NAME}-postgres-configuration \
  --from-literal=host="awx-postgres-prod.xxxxxx.us-east-1.rds.amazonaws.com" \
  --from-literal=port="5432" \
  --from-literal=database="awx_production" \
  --from-literal=username="awx_user" \
  --from-literal=password="$AWX_DB_PASSWORD" \
  --from-literal=sslmode="require" \
  --from-literal=type="unmanaged" \
  -n ${NAMESPACE}
```

**Setup for Azure Database:**
```bash
# 1. Create Azure PostgreSQL
az postgres server create \
  --resource-group awx-rg \
  --name awx-postgres-prod \
  --location eastus \
  --admin-user awx_admin \
  --admin-password "$DB_PASSWORD" \
  --sku-name GP_Gen5_2 \
  --version 13 \
  --storage-size 51200

# 2. Configure firewall
az postgres server firewall-rule create \
  --resource-group awx-rg \
  --server-name awx-postgres-prod \
  --name AllowAKS \
  --start-ip-address $AKS_NODE_RANGE \
  --end-ip-address $AKS_NODE_RANGE

# 3. Create database
psql -h awx-postgres-prod.postgres.database.azure.com \
  -U awx_admin@awx-postgres-prod -d postgres <<EOF
CREATE DATABASE awx_production;
CREATE USER awx_user WITH PASSWORD '$AWX_DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE awx_production TO awx_user;
EOF
```

**Setup for Google Cloud SQL:**
```bash
# 1. Create Cloud SQL instance
gcloud sql instances create awx-postgres-prod \
  --database-version=POSTGRES_13 \
  --cpu=2 \
  --memory=8GB \
  --region=us-central1 \
  --root-password="$DB_PASSWORD"

# 2. Create database
gcloud sql databases create awx_production \
  --instance=awx-postgres-prod

# 3. Create user
gcloud sql users create awx_user \
  --instance=awx-postgres-prod \
  --password="$AWX_DB_PASSWORD"
```

#### 3. High Availability PostgreSQL Cluster

Best for: **Enterprise, critical automation infrastructure**

```yaml
# Using Bitnami PostgreSQL HA Helm chart
helm install postgresql-ha bitnami/postgresql-ha \
  --namespace ${NAMESPACE} \
  --set postgresql.replicaCount=3 \
  --set postgresql.password="${DB_PASSWORD}" \
  --set postgresql.repmgrPassword="${REPMGR_PASSWORD}" \
  --set postgresql.database=awx_production \
  --set postgresql.username=awx_user \
  --set persistence.size=100Gi

# Update AWX secret to point to HA cluster
kubectl create secret generic awx-${NAME}-postgres-configuration \
  --from-literal=host="postgresql-ha-postgresql" \
  --from-literal=port="5432" \
  --from-literal=database="awx_production" \
  --from-literal=username="awx_user" \
  --from-literal=password="$AWX_DB_PASSWORD" \
  --from-literal=sslmode="prefer" \
  --from-literal=type="unmanaged" \
  -n ${NAMESPACE}
```

**Pros:**
- Automatic failover
- Read replicas for load balancing
- Self-healing
- All within Kubernetes

**Cons:**
- Complex setup
- More resource intensive
- PostgreSQL expertise required

### Database Connection Configuration

#### Connection Pooling (Recommended for Production)

```yaml
# Using PgBouncer
apiVersion: v1
kind: ConfigMap
metadata:
  name: pgbouncer-config
data:
  pgbouncer.ini: |
    [databases]
    awx = host=postgres-prod.example.com port=5432 dbname=awx_production
    
    [pgbouncer]
    listen_port = 5432
    listen_addr = *
    auth_type = md5
    auth_file = /etc/pgbouncer/userlist.txt
    pool_mode = transaction
    max_client_conn = 1000
    default_pool_size = 20
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: pgbouncer
        image: pgbouncer/pgbouncer:latest
# Update AWX secret to use PgBouncer
kubectl create secret generic awx-${NAME}-postgres-configuration \
  --from-literal=host="pgbouncer" \
  --from-literal=port="5432" \
  ...
```

#### SSL/TLS Configuration

```yaml
# Require SSL for production
stringData:
  host: postgres-prod.example.com
  port: "5432"
  database: awx_production
  username: awx_user
  password: "${DB_PASSWORD}"
  sslmode: require
  sslrootcert: |
    # CA certificate for verification
```

### Database Backup Strategies

#### 1. Automated RDS/Azure Backups

```bash
# AWS RDS automated backups
aws rds modify-db-instance \
  --db-instance-identifier awx-postgres-prod \
  --backup-retention-period 14 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00"
# Azure automated backups (configured via portal/CLI)
az postgres backup list \
  --resource-group awx-rg \
  --server-name awx-postgres-prod
```

#### 2. Manual pg_dump Backups

```bash
#!/bin/bash
#!/bin/bash
# backup-awx-database.sh
BACKUP_DIR="/backups/awx"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="awx_backup_${DATE}.sql"

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Dump database
pg_dump -h ${DB_HOST} \
        -U ${DB_USER} \
        -d awx_production \
        -F custom \
        -f ${BACKUP_DIR}/${BACKUP_FILE}

# Compress backup
gzip ${BACKUP_DIR}/${BACKUP_FILE}

# Upload to S3/GCS
aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE}.gz s3://awx-backups/

# Cleanup old backups (keep 30 days)
find ${BACKUP_DIR} -name "awx_backup_*.sql.gz" -mtime +30 -delete
```

#### 3. Kubernetes CronJob for Backups

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: awx-db-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: awx-${NAME}-postgres-configuration
                  key: password
            command:
            - /bin/bash
            - -c
            - |
              pg_dump -h awx-${NAME}-postgres-13 \
                      -U awx \
                      -d awx \
                      | gzip > /backups/awx_$(date +%Y%m%d).sql.gz
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: awx-backup-pvc
          restartPolicy: OnFailure
```

### Database Monitoring

```bash
# Check database connections
psql -h ${DB_HOST} -U ${DB_USER} -d awx_production <<EOF
SELECT count(*) as active_connections
FROM pg_stat_activity 
WHERE state = 'active';

-- Check database size
SELECT pg_size_pretty(pg_database_size('awx_production')) as database_size;

-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
EOF

# Monitor via kubectl exec
kubectl exec -it awx-${NAME}-postgres-13-0 -n ${NAMESPACE} -- \
  psql -U awx awx -c "SELECT * FROM pg_stat_activity;"
```

### Database Troubleshooting

**Connection Issues:**
```bash
# From within the cluster
curl -v telnet://${DB_HOST}:5432

# From a test pod
kubectl run test-db --image=postgres:13 -it --rm --restart=Never -- \
  psql -h ${DB_HOST} -U awx -d awx_production -c "SELECT version();"
```

**Performance Issues:**
```bash
# Check for long-running queries
psql -h ${DB_HOST} -U ${DB_USER} -d awx_production <<EOF
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query_start < now() - interval '5 minutes';
EOF
```

## Storage Configuration

### Persistent Volume Configuration

The deployment uses two types of persistent storage:

#### 1. PostgreSQL Storage Configuration

```yaml
# In AWX Custom Resource
spec:
  postgres_storage_class: ${STORAGE_CLASS}
  postgres_storage_requirements:
    requests:
      storage: ${POSTGRES_STORAGE_SIZE}
```

**Storage Requirements:**
- **Access Mode**: ReadWriteOnce (single pod access)
- **Recommended Storage Classes**:
  - AWS: `gp3`, `io2`
  - Azure: `managed-premium`
  - GCP: `pd-balanced`, `pd-ssd`
  - On-prem: `csi-rbd`, `csi-cephfs`
  - Generic: `fast-ssd`, `standard` (if no performance needs)

**Performance Recommendations:**
```yaml
# High-performance configuration for large deployments
storage_class: io2-high-performance  # AWS with provisioned IOPS
postgres_storage_requirements:
  requests:
    storage: 100Gi
    # For io2
    iops: "5000"
volume_mode: Filesystem
```

#### 2. Project Storage Configuration

```yaml
# In AWX Custom Resource
spec:
  projects_persistence: true
  projects_storage_class: ${STORAGE_CLASS}
  projects_storage_size: ${PROJECT_STORAGE_SIZE}
  projects_storage_access_mode: ReadWriteMany
```

**Storage Requirements:**
- **Access Mode**: ReadWriteMany (multiple pods need access)
- **Required**: Storage class must support ReadWriteMany
- **Recommended Storage Classes**:
  - AWS: `efs-csi` (EFS)
  - Azure: `azurefile-csi`
  - GCP: `filestore-csi`
  - On-prem: `nfs-client`, `cephfs`, `portworx-shared`

### Storage Class Configuration Examples

#### AWS EKS

```yaml
# PostgreSQL storage class (fast SSD)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-postgres-fast
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
---
# Project storage class (EFS for ReadWriteMany)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-projects-efs
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-xxxxxxxx
  directoryPerms: "700"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/dynamic_provisioning"
reclaimPolicy: Retain
```

#### Azure AKS

```yaml
# PostgreSQL storage class (premium SSD)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-postgres-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
  cachingMode: ReadOnly
allowVolumeExpansion: true
reclaimPolicy: Retain
---
# Project storage class (Azure Files for ReadWriteMany)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-projects-azurefile
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
  storageAccount: awxstorageaccount
  shareName: awxprojects
reclaimPolicy: Retain
```

#### GCP GKE

```yaml
# PostgreSQL storage class (SSD)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-postgres-ssd
provisioner: pd.csi.storage.gke.io
parameters:
  type: pd-balanced
  replication-type: regional-pd
allowVolumeExpansion: true
reclaimPolicy: Retain
---
# Project storage class (Filestore for ReadWriteMany)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-projects-filestore
provisioner: filestore.csi.storage.gke.io
parameters:
  tier: premium
  network: default
reclaimPolicy: Retain
```

#### On-Premises (NFS Example)

```yaml
# NFS Storage Class for both PostgreSQL and Projects
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-awx
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.example.com
  share: /exports/awx
  subDir: ${NAMESPACE}/${NAME}
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - intr
  - timeo=600
  - retrans=2
```

### Capacity Planning

#### PostgreSQL Storage Sizing

```
Base requirements: 10GB minimum

Sizing formula:
Jobs per day: 1000
Average job size: 10KB
Retention period: 30 days

Calculation:
1000 jobs/day × 10KB × 30 days = 300MB job data
+ 5GB for AWX data
+ 5GB for logs
+ 5GB for overhead
= ~21GB minimum

Recommended: 50GB for 1000 jobs/day
```

#### Project Storage Sizing

```
Base requirements: 10GB minimum

Sizing formula:
Number of projects: 50
Average project size: 100MB

Calculation:
50 projects × 100MB = 5GB minimum
+ 5GB for dynamic data
+ 5GB for cache
= ~15GB minimum

Recommended: 50GB for active development
```

### Storage Monitoring

```bash
# Monitor PVC usage
kubectl get pvc -n ${NAMESPACE}
kubectl describe pvc postgres-${NAME}-postgres-13-0 -n ${NAMESPACE}

# Monitor dynamic provisioning
kubectl get events -n ${NAMESPACE} | grep -i storage

# Check PV status
kubectl get pv
kubectl describe pv <pv-name>

# Set up Prometheus alerts
# Example: Alert on storage > 80%
groups:
- name: awx-storage
  rules:
  - alert: AWXPostgreSQLStorageLow
    expr: |
      (
        kubelet_volume_stats_available_bytes{namespace="${NAMESPACE}", 
        persistentvolumeclaim=~"postgres.*"} /
        kubelet_volume_stats_capacity_bytes{namespace="${NAMESPACE}", 
        persistentvolumeclaim=~"postgres.*"}
      ) < 0.2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "AWX PostgreSQL storage low"
      description: "Storage available < 20% in AWX PostgreSQL"
```

### Backup and Restore of Persistent Volumes

#### Volume Snapshots (CSI)

```yaml
# Create volume snapshot for PostgreSQL
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: awx-postgres-snapshot-$(date +%Y%m%d)
  namespace: ${NAMESPACE}
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: postgres-${NAME}-postgres-13-0
---
# Restore from snapshot
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-${NAME}-postgres-13-0-restored
  namespace: ${NAMESPACE}
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: ${STORAGE_CLASS}
  dataSource:
    name: awx-postgres-snapshot-20230101
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  resources:
    requests:
      storage: ${POSTGRES_STORAGE_SIZE}
```

#### Backup to Object Storage

```yaml
# CronJob for backing up PV to S3
apiVersion: batch/v1
kind: CronJob
metadata:
  name: awx-postgres-volume-backup
spec:
  schedule: "0 3 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: ubuntu:latest
            command:
            - /bin/bash
            - -c
            - |
              apt-get update && apt-get install -y tar gzip awscli
              # Mount PostgreSQL volume
              tar -czf /backup/awx-postgres-$(date +%Y%m%d).tar.gz /var/lib/postgresql/data
              aws s3 cp /backup/*.tar.gz s3://awx-backups/postgres/
            volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: postgres-data
            persistentVolumeClaim:
              claimName: postgres-${NAME}-postgres-13-0
          - name: backup-storage
            emptyDir: {}
          restartPolicy: OnFailure
```

### Troubleshooting Storage Issues

**PVC Pending:**
```bash
# Check storage class
kubectl get storageclass ${STORAGE_CLASS}
kubectl describe storageclass ${STORAGE_CLASS}

# Check CSI driver
kubectl get pods -n kube-system | grep csi

# Check events
kubectl describe pvc postgres-${NAME}-postgres-13-0 -n ${NAMESPACE}

# Common fixes:
# 1. Verify storage class exists
# 2. Check driver health
# 3. Verify resource quotas
# 4. Check network connectivity to storage
```

**Projects PVC ReadWriteMany Error:**
```bash
# Check storage class support
kubectl get storageclass ${STORAGE_CLASS} -o yaml | grep volumeBindingMode

# List ReadWriteMany storage classes
for sc in $(kubectl get storageclass -o name); do
  kubectl get $sc -o yaml | grep -q "ReadWriteMany" && \
  echo "$sc supports ReadWriteMany"
done

# Alternative: Use NFS provisioner if no native support
helm install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=x.x.x.x \
  --set nfs.path=/exported/path
```

**Storage Performance Issues:**
```bash
# Check I/O performance from within pod
kubectl exec -it awx-${NAME}-postgres-13-0 -n ${NAMESPACE} -- \
  dd if=/dev/zero of=/var/lib/postgresql/data/test bs=1M count=1000 oflag=direct

# Check disk usage
kubectl exec -it awx-${NAME}-postgres-13-0 -n ${NAMESPACE} -- \
  df -h /var/lib/postgresql/data

# PostgreSQL-specific checks
kubectl exec -it awx-${NAME}-postgres-13-0 -n ${NAMESPACE} -- \
  psql -U awx -d awx -c "SELECT pg_database_size('awx');"
```

### Storage Security Best Practices

```yaml
# Encrypt storage at rest
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-encrypted
parameters:
  encrypted: "true"  # For AWS EBS
  # For Azure
  # diskEncryptionSetID: <resource-id>
---
# Use SecurityContext for pods
apiVersion: v1
kind: Pod
spec:
  securityContext:
    fsGroup: 1000  # PostgreSQL usually runs as UID 999
  # For project storage, may need supplemental groups
    supplementalGroups: [1000]
```

### Storage Performance Testing

```bash
# Test sequential write performance
fio --name=test_seq_write --directory=/var/lib/postgresql/data \
    --rw=write --size=1G --bs=1M --runtime=60 --time_based

# Test random read/write (simulates database)
fio --name=test_rand_rw --directory=/var/lib/postgresql/data \
    --rw=randrw --size=1G --bs=4k --runtime=60 --time_based

# Results interpretation
# Sequential Write: >100MB/s for good performance
# Random RW IOPS: >500 IOPS for acceptable performance
# Latency: <10ms average for responsive database
```
## Authentication Setup

### Local Authentication (Default)

The template includes a default admin account. Change credentials immediately after deployment:

```bash
# Get admin password
kubectl get secret awx-${NAME}-admin-password \
  -n ${NAMESPACE} \
  -o jsonpath='{.data.password}' | base64 -d

# Log in to AWX UI
# Navigate to: https://${HOSTNAME}
# Username: admin (or configured admin_user)

# CHANGE DEFAULT PASSWORD!
# Settings → Users → admin → Edit
# Set new secure password
```

### LDAP/Active Directory Integration

#### 1. Enable LDAP in Template

```yaml
# During template generation
ldap_enabled: true
```

#### 2. Configure LDAP in AWX

```yaml
# In secrets.yaml (if using LDAP with custom CA)
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-ldap-cacert
type: Opaque
data:
  ldap-cacert.crt: |
    # Base64 encoded LDAP CA certificate
```

#### 3. AWX LDAP Settings (via UI or API)

```bash
# Via AWX API
curl -X POST "https://${HOSTNAME}/api/v2/settings/ldap/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @ldap-config.json
```

**ldap-config.json:**
```json
{
  "AUTH_LDAP_SERVER_URI": "ldaps://ldap.corp.example.com:636",
  "AUTH_LDAP_START_TLS": false,
  "AUTH_LDAP_BIND_DN": "CN=awxbind,OU=ServiceAccounts,DC=corp,DC=example,DC=com",
  "AUTH_LDAP_BIND_PASSWORD": "${LDAP_BIND_PASSWORD}",
  "AUTH_LDAP_USER_SEARCH": [
    "OU=Users,DC=corp,DC=example,DC=com",
    "SCOPE_SUBTREE",
    "(sAMAccountName=%(user)s)"
  ],
  "AUTH_LDAP_USER_ATTR_MAP": {
    "first_name": "givenName",
    "last_name": "sn",
    "email": "mail"
  },
  "AUTH_LDAP_GROUP_SEARCH": [
    "OU=Groups,DC=corp,DC=example,DC=com",
    "SCOPE_SUBTREE",
    "(objectClass=group)"
  ],
  "AUTH_LDAP_GROUP_TYPE": "MemberDNGroupType",
  "AUTH_LDAP_GROUP_TYPE_PARAMS": {
    "member_attr": "member",
    "name_attr": "cn"
  },
  "AUTH_LDAP_REQUIRE_GROUP": "CN=AWXUsers,OU=Groups,DC=corp,DC=example,DC=com",
  "AUTH_LDAP_USER_FLAGS_BY_GROUP": {
    "is_superuser": "CN=AWXAdmins,OU=Groups,DC=corp,DC=example,DC=com"
  },
  "AUTH_LDAP_ORGANIZATION_MAP": {
    "AWX-Org": {
      "admins": "CN=AWXAdmins,OU=Groups,DC=corp,DC=example,DC=com",
      "users": "CN=AWXUsers,OU=Groups,DC=corp,DC=example,DC=com",
      "remove_users": true,
      "remove_admins": true
    }
  },
  "AUTH_LDAP_TEAM_MAP": {
    "Developers": {
      "organization": "AWX-Org",
      "users": "CN=Developers,OU=Groups,DC=corp,DC=example,DC=com",
      "remove": true
    },
    "Operators": {
      "organization": "AWX-Org",
      "users": "CN=Operators,OU=Groups,DC=corp,DC=example,DC=com",
      "remove": true
    }
  }
}
```

#### 4. Testing LDAP Configuration

```bash
# Test LDAP bind
ldapsearch -x -D "CN=awxbind,OU=ServiceAccounts,DC=corp,DC=example,DC=com" \
  -w "$LDAP_BIND_PASSWORD" \
  -H ldaps://ldap.corp.example.com:636 \
  -b "OU=Users,DC=corp,DC=example,DC=com" \
  "(&(objectClass=user)(sAMAccountName=testuser))"

# Test from AWX pod
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
import django
from django.conf import settings
from django_auth_ldap.config import LDAPSearch
import ldap

# Test connection
conn = ldap.initialize(settings.AUTH_LDAP_SERVER_URI)
conn.simple_bind_s(settings.AUTH_LDAP_BIND_DN, settings.AUTH_LDAP_BIND_PASSWORD)
print("LDAP connection successful!")
EOF
```

### SAML SSO Integration

#### 1. Configure SAML in AWX

```yaml
# SAML settings via AWX API
curl -X POST "https://${HOSTNAME}/api/v2/settings/saml/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @saml-config.json
```

**saml-config.json:**
```json
{
  "SOCIAL_AUTH_SAML_ENABLED_IDPS": {
    "okta": {
      "entity_id": "https://dev-xxxx.okta.com",
      "url": "https://dev-xxxx.okta.com/app/yourapp/sso/saml",
      "x509cert": "MIIC4DCCAcigAwIBAgIGAX...",
      "attr_user_permanent_id": "username",
      "attr_first_name": "firstName",
      "attr_last_name": "lastName",
      "attr_username": "username",
      "attr_email": "email",
      "attr_groups": "groups"
    }
  },
  "SOCIAL_AUTH_SAML_SP_ENTITY_ID": "https://${HOSTNAME}",
  "SOCIAL_AUTH_SAML_SP_PUBLIC_CERT": "-----BEGIN CERTIFICATE-----\n...",
  "SOCIAL_AUTH_SAML_SP_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----\n...",
  "SOCIAL_AUTH_SAML_ORGANIZATION_ATTR": {
    "saml_attr": "organization",
    "saml_admin_attr": "org_admins",
    "remove": true,
    "remove_admins": true
  },
  "SOCIAL_AUTH_SAML_TEAM_ATTR": {
    "saml_attr": "groups",
    "remove": true,
    "team_org_map": [
      {
        "team": "Developers",
        "organization": "AWX-Org"
      },
      {
        "team": "Operators",
        "organization": "AWX-Org"
      }
    ]
  },
  "SOCIAL_AUTH_SAML_SECURITY_CONFIG": {
    "requestedAuthnContext": false
  }
}
```

#### 2. Create Kubernetes Secret for SAML Certificate

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: awx-${NAME}-saml-cert
type: Opaque
data:
  saml-sp.crt: LS0tLS1CRUdJTiB...(base64 encoded certificate)
  saml-sp.key: LS0tLS1CRUdJTiB...(base64 encoded private key)
```

#### 3. Mount SAML Secret in AWX

```yaml
# Update AWX CRD
spec:
  extra_volumes:
  - name: saml-cert
    secret:
      secretName: awx-${NAME}-saml-cert
  extra_volume_mounts:
  - name: saml-cert
    mountPath: /etc/tower/saml.crt
    subPath: saml-sp.crt
  - name: saml-cert
    mountPath: /etc/tower/saml.key
    subPath: saml-sp.key
```

### OAuth2/OIDC Authentication

#### 1. Configure GitHub OAuth

```bash
# In GitHub Settings → Developer Settings → OAuth Apps
# Create new OAuth application
# Homepage URL: https://${HOSTNAME}
# Authorization callback URL: https://${HOSTNAME}/sso/complete/github/

# Configure in AWX
curl -X POST "https://${HOSTNAME}/api/v2/settings/authentication/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d @oauth-config.json
```

**oauth-config.json:**
```json
{
  "SOCIAL_AUTH_GITHUB_KEY": "${GITHUB_CLIENT_ID}",
  "SOCIAL_AUTH_GITHUB_SECRET": "${GITHUB_CLIENT_SECRET}",
  "SOCIAL_AUTH_GITHUB_ORGANIZATION_MAP": {
    "YourOrg": {
      "admins": "github-org-admin-team",
      "users": "all",
      "remove_admins": true,
      "remove_users": true
    }
  },
  "SOCIAL_AUTH_GITHUB_TEAM_MAP": {
    "Developers": {
      "team_id": 123456,
      "organization": "YourOrg",
      "remove": true
    }
  }
}
```

#### 2. Configure Azure AD

```json
{
  "SOCIAL_AUTH_AZUREAD_TENANT_OAUTH2_KEY": "${AZURE_CLIENT_ID}",
  "SOCIAL_AUTH_AZUREAD_TENANT_OAUTH2_SECRET": "${AZURE_CLIENT_SECRET}",
  "SOCIAL_AUTH_AZUREAD_TENANT_OAUTH2_TENANT_ID": "${AZURE_TENANT_ID}",
  "SOCIAL_AUTH_AZUREAD_TENANT_OAUTH2_ORGANIZATION_MAP": {
    "AWX-Org": {
      "admins": "AZURE_ADMINS",
      "users": "AZURE_USERS",
      "remove_admins": true,
      "remove_users": true
    }
  }
}
```

### Multi-Factor Authentication (MFA)

#### 1. Enable MFA in AWX

```bash
# MFA settings via AWX API
curl -X POST "https://${HOSTNAME}/api/v2/settings/system/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"MFA_ENABLED": true}'
```

#### 2. Configure MFA Methods

```json
{
  "MFA_ENABLED": true,
  "MFA_CHALLENGE_ISSUER_NAME": "AWX Automation Platform"
}
```

Users can configure MFA in their profile settings:
- Time-based One-Time Password (TOTP)
- SMS (via external integration)
- Hardware tokens

### RBAC and User Management

#### 1. Organization Structure

```bash
# Create organizations
curl -X POST "https://${HOSTNAME}/api/v2/organizations/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"name": "AWX-Org", "description": "Main Organization"}'

curl -X POST "https://${HOSTNAME}/api/v2/organizations/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"name": "Security-Team", "description": "Security Team Org"}'
```

#### 2. Team Management

```bash
# Create teams within organizations
curl -X POST "https://${HOSTNAME}/api/v2/teams/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "name": "Developers",
    "description": "Development Team",
    "organization": 1
  }'

curl -X POST "https://${HOSTNAME}/api/v2/teams/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "name": "Operators",
    "description": "Operations Team",
    "organization": 1
  }'
```

#### 3. Role Assignments

Built-in AWX roles:
- **System Administrator**: Full system access
- **Organization Administrator**: Admin for specific org
- **Team Member**: Access to team's resources
- **Project Admin**: Manage specific project
- **Inventory Admin**: Manage specific inventory
- **Workflow Admin**: Manage specific workflow
- **Job Template Admin**: Manage specific job template
- **Execution Environment Admin**: Manage specific EE
- **Auditor**: Read-only access to all

```bash
# Assign user to team with specific role
curl -X POST "https://${HOSTNAME}/api/v2/teams/${TEAM_ID}/users/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"id": ${USER_ID}, "role": "member"}'

# Create custom role (example: restricted job viewer)
curl -X POST "https://${HOSTNAME}/api/v2/roles/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "name": "Job Viewer Restricted",
    "description": "Can view jobs but not create",
    "permissions": [
      {"resource_type": "job", "action": "view"}
    ]
  }'
```

### Security Best Practices

```bash
# 1. Disable local authentication if using LDAP/SAML
# Settings → Authentication → Disable Local Users

# 2. Configure session timeout
curl -X POST "https://${HOSTNAME}/api/v2/settings/system/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"SESSION_COOKIE_AGE": 3600}'  # 1 hour

# 3. Enable password complexity
curl -X POST "https://${HOSTNAME}/api/v2/settings/system/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "MINIMUM_PASSWORD_LENGTH": 12,
    "PASSWORD_UPPERCASE_REQUIRED": true,
    "PASSWORD_LOWERCASE_REQUIRED": true,
    "PASSWORD_DIGITS_REQUIRED": true,
    "PASSWORD_SYMBOLS_REQUIRED": true
  }'

# 4. Implement rate limiting for login attempts
curl -X POST "https://${HOSTNAME}/api/v2/settings/authentication/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "MAX_LOGIN_ATTEMPTS": 5,
    "LOGIN_ATTEMPT_TIMEOUT": 300
  }'

# 5. Configure account lockout
curl -X POST "https://${HOSTNAME}/api/v2/settings/authentication/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "ACCOUNT_LOCKOUT_THRESHOLD": 3,
    "ACCOUNT_LOCKOUT_DURATION": 900
  }'

# 6. Enable IP whitelisting (via ingress)
kubectl annotate ingress awx-${NAME}-ingress \
  -n ${NAMESPACE} \
  nginx.ingress.kubernetes.io/whitelist-source-range="10.0.0.0/8,172.16.0.0/12"
```

### Troubleshooting Authentication

**LDAP Connection Issues:**
```bash
# Test from AWX pod
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
from django_auth_ldap.backend import LDAPBackend
backend = LDAPBackend()
user = backend.authenticate(request=None, username='testuser', password='testpass')
print(f"User authenticated: {user}")
EOF

# Check logs
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-web | grep -i ldap
```

**SAML Issues:**
```bash
# Check SAML metadata
curl "https://${HOSTNAME}/sso/metadata/saml/" \
  -H "Authorization: Bearer ${TOKEN}"

# Enable debug logging
curl -X POST "https://${HOSTNAME}/api/v2/settings/logging/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"LOG_AGGREGATOR_LEVEL": "DEBUG"}'

kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-web | grep -i saml
```

**OAuth Issues:**
```bash
# Verify OAuth app configuration
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
from django.conf import settings
print(f"GitHub OAuth enabled: {settings.SOCIAL_AUTH_GITHUB_KEY is not None}")
EOF
```

### Identity Provider Configuration Examples

#### Okta SAML

```xml
<!-- Okta SAML Config -->
<md:EntityDescriptor entityID="https://${HOSTNAME}">
  <md:SPSSODescriptor>
    <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
    <md:AssertionConsumerService 
      index="1" 
      Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      Location="https://${HOSTNAME}/sso/complete/saml/"/>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

#### Azure AD SAML

```bash
# Azure AD Configuration
1. Azure Portal → Azure AD → Enterprise Applications → New
2. Select "Non-gallery application"
3. Set up SAML:
   - Identifier: https://${HOSTNAME}
   - Reply URL: https://${HOSTNAME}/sso/complete/saml/
   - Sign-on URL: https://${HOSTNAME}
   - Logout URL: https://${HOSTNAME}/accounts/logout/

# Download SAML certificate and configure in AWX
```

#### Google SAML

```bash
# Google Admin Console
1. Apps → Web and mobile apps → Add custom SAML app
2. Download metadata
3. Configure ACS URL: https://${HOSTNAME}/sso/complete/saml/
4. Map attributes:
   - Primary email → email
   - First name → firstName
   - Last name → lastName
   - Groups → groups
```

### Authentication Migration Strategy

**From Local to LDAP:**

```bash
#!/bin/bash
# migrate-users-to-ldap.sh

# 1. Export local users
awx user list --all-pages > local_users.json

# 2. Map existing users to LDAP
for user in $(cat local_users.json | jq -r '.results[] | select(.ldap_dn == null) | .username'); do
  echo "Migrating user: $user"
  
  # Update user to use LDAP auth
  awx user modify $user \
    --ldap_dn "uid=$user,ou=users,dc=example,dc=com"
done

# 3. Disable local auth (once verified)
curl -X POST "https://${HOSTNAME}/api/v2/settings/authentication/" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{"ALLOW_LOCAL_USERS": false}'
```

**From LDAP to SAML:**

```bash
# SAML migration uses same user identifiers
# User identity mapping based on email/username
# Test in staging before production
# Maintain fallback login method during migration
```

## Resource Management

### CPU and Memory Requests/Limits

Default resource configuration by environment:

```yaml
# Development Environment
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
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi
  
  ee_resource_requirements:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi
  
  redis_resource_requirements:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi
```

```yaml
# Production Environment
spec:
  web_resource_requirements:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  
  task_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  ee_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  redis_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
```

### Vertical Scaling

#### 1. Scale Individual Components

```bash
# Edit AWX resource
kubectl edit awx ${NAME} -n ${NAMESPACE}

# Update resource requirements
spec:
  web_resource_requirements:
    requests:
      cpu: 4000m  # 4 cores
      memory: 8Gi  # 8GB
    limits:
      cpu: 8000m  # 8 cores
      memory: 16Gi  # 16GB

# Monitor rollout
kubectl get pods -n ${NAMESPACE} -w
kubectl describe pod awx-${NAME}-web-xxx -n ${NAMESPACE}
```

#### 2. Set Default Resource Requirements

```bash
# Patch the AWX resource
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "web_resource_requirements": {
      "requests": {"cpu": "4000m", "memory": "8Gi"},
      "limits": {"cpu": "8000m", "memory": "16Gi"}
    }
  }
}'
```

### Horizontal Scaling (Replicas)

#### 1. Scale Web Pods

```yaml
# Scale web pods for increased UI/API load
spec:
  web_replicas: 3  # Default: 1 for dev, 2 for prod

# Apply change
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {"web_replicas": 3}
}'

# Verify scaling
kubectl get deployment awx-${NAME}-web -n ${NAMESPACE}
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=awx-${NAME}-web
```

#### 2. Scale Task Workers

```yaml
# Scale task workers for parallel job processing
spec:
  task_replicas: 3  # Default: 1

# Apply change
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {"task_replicas": 3}
}'

# Monitor task queue
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
from awx.main.utils import get_cpu_capacity, get_mem_capacity
print(f"CPU Capacity: {get_cpu_capacity()}")
print(f"Memory Capacity: {get_mem_capacity()}")
EOF
```

#### 3. Scale Execution Environments

```yaml
# Scale execution environments for concurrent ansible runs
spec:
  ee_replicas: 3  # Default: matches task_replicas

# Apply change
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {"ee_replicas": 3}
}'

# Check EE pods
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=awx-${NAME}-ee
```

### Auto-scaling with HPA

#### 1. Configure Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: awx-${NAME}-web-hpa
  namespace: ${NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: awx-${NAME}-web
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

```yaml
# HPA for Task Workers
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: awx-${NAME}-task-hpa
  namespace: ${NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: awx-${NAME}-task
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Pods
    pods:
      metric:
        name: awx_pending_jobs
      target:
        type: AverageValue
        averageValue: "5"
```

#### 2. Create Custom Metrics for AWX

```yaml
# Deploy Prometheus adapter for custom metrics
apiVersion: v1
kind: ConfigMap
metadata:
  name: adapter-config
data:
  config.yaml: |
    rules:
    - seriesQuery: 'awx_pending_jobs{namespace!=""}'
      resources:
        overrides:
          namespace: {resource: "namespace"}
      name:
        matches: "^(.*)"
        as: "${1}"
      metricsQuery: 'avg(awx_pending_jobs{namespace="${NAMESPACE}"})'
```

### Node Selection and Tolerations

#### 1. Dedicated Node Pools

```yaml
# For Production: Dedicated nodes for AWX
spec:
  node_selector: |
    workload-type: awx
    environment: production

# For Development: Can share nodes
spec:
  node_selector: |
    workload-type: general
```

#### 2. Taints and Tolerations

```yaml
# For dedicated AWX nodes
apiVersion: v1
kind: Node
metadata:
  name: worker-node-1
spec:
  taints:
  - key: "dedicated"
    value: "awx"
    effect: "NoSchedule"

# In AWX deployment
spec:
  tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "awx"
      effect: "NoSchedule"
```

#### 3. Affinity Rules

```yaml
spec:
  web_toleration: |
    - key: "workload-type"
      operator: "Equal"
      value: "web"
      effect: "NoSchedule"
  web_affinity: |
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - awx-${NAME}-web
          topologyKey: kubernetes.io/hostname
```

### Resource Limits and Quality of Service

#### 1. QoS Classes

- **Guaranteed**: `requests` == `limits` (all containers)
- **Burstable**: `requests` < `limits` (recommended for AWX)
- **BestEffort**: No requests/limits set (not recommended)

```yaml
# Burstable configuration (recommended)
spec:
  web_resource_requirements:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m  # 2x requests
      memory: 8Gi  # 2x requests
```

#### 2. Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: awx-${NAME}-quota
  namespace: ${NAMESPACE}
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 40Gi
    limits.cpu: "20"
    limits.memory: 80Gi
    persistentvolumeclaims: "10"
    requests.storage: 500Gi
```

#### 3. Limit Ranges

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: awx-${NAME}-limits
  namespace: ${NAMESPACE}
spec:
  limits:
  - default:
      cpu: 1000m
      memory: 2Gi
    defaultRequest:
      cpu: 500m
      memory: 1Gi
    type: Container
```

### Performance Tuning

#### 1. Django Settings for Performance

```yaml
# In AWX CRD
spec:
  extra_settings:
    - setting: TOWER_URL_BASE
      value: "https://${HOSTNAME}"
    - setting: AWX_TASK_ENV['MAX_OPEN_FILES']
      value: 8192
    - setting: SYSTEM_TASK_ABS_MEM
      value: 40  # 40GB for production
    - setting: SYSTEM_TASK_ABS_CPU
      value: 12  # 12 cores for production
    - setting: AWX_RUNNER_MIN_JOBS
      value: 5
    - setting: AWX_RUNNER_MAX_JOBS
      value: 50
    - setting: AWX_CALLBACK_PROFILE
      value: true
```

#### 2. Redis Performance

```yaml
# Redis optimization
spec:
  redis_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  redis_args: |
    - --maxmemory 2gb
    - --maxmemory-policy allkeys-lru
    - --tcp-keepalive 300
```

#### 3. PostgreSQL Performance

```yaml
# PostgreSQL tuning via custom config
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-custom-config
data:
  postgresql.conf: |
    # Connection settings
    max_connections = 200
    shared_buffers = 2GB
    effective_cache_size = 6GB
    
    # Performance settings
    checkpoint_timeout = 10min
    max_wal_size = 2GB
    work_mem = 10MB
    maintenance_work_mem = 512MB
    
    # Logging
    log_min_duration_statement = 1000
    log_checkpoints = on
    log_connections = on
    log_disconnections = on
```

Apply to PostgreSQL StatefulSet:
```bash
kubectl patch statefulset awx-${NAME}-postgres-13 -n ${NAMESPACE} --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "postgres",
          "volumeMounts": [{
            "name": "postgres-config",
            "mountPath": "/etc/postgresql/postgresql.conf",
            "subPath": "postgresql.conf"
          }]
        }],
        "volumes": [{
          "name": "postgres-config",
          "configMap": {
            "name": "postgres-custom-config"
          }
        }]
      }
    }
  }
}'
```

### Monitoring Resource Usage

#### 1. Prometheus Metrics

```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: awx-${NAME}-metrics
  namespace: ${NAMESPACE}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: awx-${NAME}
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

#### 2. Grafana Dashboard

Import dashboard ID: `17367` (AWX Ansible Automation Platform) or create custom:

```json
{
  "title": "AWX ${NAME} Resource Usage",
  "panels": [
    {
      "title": "Pod CPU Usage",
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"${NAMESPACE}\",pod=~\"awx-${NAME}-.*\"}[5m])) by (pod)"
        }
      ]
    },
    {
      "title": "Pod Memory Usage",
      "targets": [
        {
          "expr": "sum(container_memory_working_set_bytes{namespace=\"${NAMESPACE}\",pod=~\"awx-${NAME}-.*\"}) by (pod)"
        }
      ]
    },
    {
      "title": "Job Queue Depth",
      "targets": [
        {
          "expr": "awx_pending_jobs{namespace=\"${NAMESPACE}\"}"
        }
      ]
    }
  ]
}
```

#### 3. Alerting Rules

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: awx-${NAME}-alerts
spec:
  groups:
  - name: awx-resources
    rules:
    - alert: AWXHighCPUUsage
      expr: |
        avg(rate(container_cpu_usage_seconds_total{
          namespace="${NAMESPACE}",
          pod=~"awx-${NAME}-web-.*"
        }[5m])) > 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "AWX web pods high CPU usage"
        
    - alert: AWXHighMemoryUsage
      expr: |
        avg(container_memory_working_set_bytes{
          namespace="${NAMESPACE}", 
          pod=~"awx-${NAME}-.*"
        }) / avg(container_spec_memory_limit_bytes{
          namespace="${NAMESPACE}",
          pod=~"awx-${NAME}-.*"
        }) > 0.85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "AWX pods memory usage high"
        
    - alert: AWXPodRestarting
      expr: |
        rate(kube_pod_container_status_restarts_total{
          namespace="${NAMESPACE}",
          pod=~"awx-${NAME}-.*"
        }[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "AWX pod restarting frequently"
```

### Cost Optimization

#### 1. Right-size Resources

```bash
# Analyze actual usage vs requests
kubectl top pods -n ${NAMESPACE}

# Average CPU usage percentage
# Current: 500m requests, using 200m average
# Recommendation: Set requests to 300m (60% of actual)

# Memory usage
# Current: 2Gi requests, using 1.2Gi average  
# Recommendation: Set requests to 1.5Gi (80% of actual)
```

#### 2. Spot/Preemptible Instances

```yaml
# Use spot instances for non-critical components
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
        node.kubernetes.io/instance-type: spot
      tolerations:
      - key: "spot-instance"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

#### 3. Scheduled Scaling (Development/Staging)

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: awx-scale-down-demo
spec:
  schedule: "0 18 * * 1-5"  # 6 PM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: kubectl
            image: bitnami/kubectl:latest
            command:
            - kubectl
            - patch
            - awx
            - ${NAME}
            - -n
            - ${NAMESPACE}
            - --type=merge
            - -p
            - '{"spec":{"web_replicas":1,"task_replicas":1,"ee_replicas":1}}'
          restartPolicy: OnFailure
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: awx-scale-up-demo
spec:
  schedule: "0 8 * * 1-5"  # 8 AM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: kubectl
            image: bitnami/kubectl:latest
            command:
            - kubectl
            - patch
            - awx
            - ${NAME}
            - -n
            - ${NAMESPACE}
            - --type=merge
            - -p
            - '{"spec":{"web_replicas":2,"task_replicas":3,"ee_replicas":3}}'
          restartPolicy: OnFailure
```

### Resource Troubleshooting

**OOMKilled Pods:**
```bash
# Check for OOM events
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | grep OOM

# Describe pod for OOM details
kubectl describe pod awx-${NAME}-web-xxx -n ${NAMESPACE}
# Look for: "State: Terminated, Reason: OOMKilled"

# Solution: Increase memory limits
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "web_resource_requirements": {
      "limits": {"memory": "16Gi"}
    }
  }
}'
```

**CPU Throttling:**
```bash
# Check CPU throttling
kubectl describe pod awx-${NAME}-web-xxx -n ${NAMESPACE}
# Look for: "Throttled: True"

# Monitor CPU usage
kubectl top pod awx-${NAME}-web-xxx -n ${NAMESPACE}

# Check if consistently hitting limits
# If yes, increase CPU limits or scale horizontally
```

**Insufficient Resources:**
```bash
# Check pending pods
kubectl get pods -n ${NAMESPACE} | grep Pending

# Check why pending
kubectl describe pod awx-${NAME}-web-xxx -n ${NAMESPACE}
# Look for: "Insufficient cpu" or "Insufficient memory"

# Check cluster capacity
kubectl describe nodes
kubectl top nodes

# Solution: Scale cluster or reduce resource requests
```

**Scheduling Issues:**
```bash
# Check pod scheduling failures
kubectl describe pod awx-${NAME}-web-xxx -n ${NAMESPACE}

# Common issues:
# - Node selector mismatch
# - Tolerations missing
# - Affinity rules too restrictive
# - Resource limits too high

# Solution: Adjust nodeSelector/affinity/tolerations
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "node_selector": "environment=${ENVIRONMENT}"
  }
}'
```

### Resource Requests Guidelines

```
Web Pods:
  CPU: 1000m-4000m per replica (based on concurrent users)
  Memory: 2Gi-8Gi per replica (based on job history size)
  
Task Pods:
  CPU: 500m-2000m per replica (based on job complexity)
  Memory: 1Gi-4Gi per replica (based on job resources)
  
EE Pods:
  CPU: 500m-2000m per replica (based on ansible processes)
  Memory: 1Gi-4Gi per replica (based on playbook memory needs)
  
Redis Pods:
  CPU: 500m-2000m (based on cache size and throughput)
  Memory: 1Gi-4Gi (based on concurrent sessions)

PostgreSQL:
  CPU: 2000m-8000m (based on database size and queries)
  Memory: 4Gi-16Gi (based on shared_buffers and connections)
```

### Performance Benchmarks

```bash
# Web UI Load Test
# Using Apache Bench
ab -n 10000 -c 100 -k https://${HOSTNAME}/api/v2/ping/

# Expected results:
# - Development: 100+ req/sec
# - Production: 1000+ req/sec with multiple replicas
# - 95th percentile latency: < 200ms

# Job Execution Test
# Time to complete 100 parallel simple jobs
awx job_template launch --wait Demo-Job-Template
# Expected: Jobs complete at rate of task workers

# Database Performance
# Query performance
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
import time
from awx.main.models import Job
from django.db import connection
from django.db.utils import OperationalError

start = time.time()
try:
    job_count = Job.objects.count()
    print(f"Job count: {job_count}")
    print(f"Query time: {time.time() - start:.3f}s")
except OperationalError as e:
    print(f"Database error: {e}")
EOF

# Expected: < 1s for databases with < 100k jobs
```
## Upgrading AWX

### Pre-Upgrade Checklist

```bash
#!/bin/bash
# pre-upgrade-checks.sh

echo "=== AWX Pre-Upgrade Checks ==="

# 1. Check current version
CURRENT_VERSION=$(kubectl get awx ${NAME} -n ${NAMESPACE} -o jsonpath='{.spec.image}' | cut -d: -f2)
echo "Current AWX Version: ${CURRENT_VERSION}"

# 2. Check cluster health
kubectl get pods -n ${NAMESPACE}
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | head -20

# 3. Check database connectivity
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py check --database default

# 4. Backup current configuration
kubectl get awx ${NAME} -n ${NAMESPACE} -o yaml > awx-backup-${CURRENT_VERSION}.yaml
kubectl get secrets -n ${NAMESPACE} -o yaml > secrets-backup.yaml

# 5. Check storage capacity
kubectl get pvc -n ${NAMESPACE}
df -h /path/to/volumes  # If accessible

# 6. Check for custom modifications
echo "Custom settings applied:"
kubectl get awx ${NAME} -n ${NAMESPACE} -o yaml | grep -A 10 "extra_settings"

# 7. Check resource usage
kubectl top pods -n ${NAMESPACE}

# 8. Document running jobs
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
from awx.main.models import Job
active_jobs = Job.objects.filter(status__in=['running', 'pending']).count()
print(f"Active jobs: {active_jobs}")
EOF

echo "Pre-upgrade checks complete!"
```

### Upgrade Process

#### 1. Upgrade AWX Operator (If Needed)

```bash
# Check current operator version
kubectl get deployment awx-operator-controller-manager -n awx-operator \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Upgrade operator
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/${NEW_VERSION}/deploy/awx-operator.yaml

# Wait for operator upgrade
kubectl rollout status deployment/awx-operator-controller-manager -n awx-operator -w

# Verify operator is healthy
kubectl get pods -n awx-operator
```

#### 2. Upgrade AWX Instance

```bash
# Method 1: Edit AWX resource directly
kubectl edit awx ${NAME} -n ${NAMESPACE}

# Update spec.image (if pinned) or version
spec:
  image: quay.io/ansible/awx:22.7.0

# Method 2: Use patch
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "image": "quay.io/ansible/awx:22.7.0"
  }
}'

# Method 3: Update deployment files
# Edit k8s/awx.yaml and apply
sed -i 's/awx:21.14.0/awx:22.7.0/' k8s/awx.yaml
kubectl apply -f k8s/awx.yaml
```

#### 3. Monitor Upgrade Progress

```bash
# Watch pod updates
kubectl get pods -n ${NAMESPACE} -w

# Check AWX resource status
kubectl describe awx ${NAME} -n ${NAMESPACE}

# Monitor operator logs
kubectl logs -n awx-operator deployment/awx-operator-controller-manager -f

# Check for upgrade completion
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage --version

# Check migrations
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage showmigrations
```

#### 4. Post-Upgrade Verification

```bash
#!/bin/bash
# post-upgrade-verification.sh

echo "=== Post-Upgrade Verification ==="

# 1. Check all pods are running
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-${NAME} -n ${NAMESPACE} --timeout=600s

# 2. Verify AWX is responding
curl -f -u admin:$(kubectl get secret awx-${NAME}-admin-password -n ${NAMESPACE} -o jsonpath='{.data.password}' | base64 -d) \
  https://${HOSTNAME}/api/v2/ping/

# 3. Check version
NEW_VERSION=$(kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- awx-manage --version)
echo "New AWX Version: ${NEW_VERSION}"

# 4. Run database migrations if needed
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage migrate --noinput

# 5. Check for failed migrations
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage showmigrations | grep -v "[X]"

# 6. Verify job templates
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  python manage.py shell <<EOF
from awx.main.models import JobTemplate
count = JobTemplate.objects.count()
print(f"Job templates: {count}")
EOF

# 7. Test job execution
echo "Running test job..."
JOB_ID=$(awx job_template launch "Demo Job Template" --monitor -f json | jq -r '.id')
if [ "$JOB_ID" != "null" ]; then
  echo "Test job launched successfully: $JOB_ID"
else
  echo "ERROR: Test job failed to launch"
  exit 1
fi

# 8. Check logs for errors
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-web --tail=100 | grep -i error
kubectl logs -n ${NAMESPACE} deployment/awx-${NAME}-task --tail=100 | grep -i error

echo "Post-upgrade verification complete!"
```

### Rollback Procedure

#### 1. Immediate Rollback (If Upgrade Fails)

```bash
#!/bin/bash
# rollback-awx.sh

echo "=== Rolling back AWX ==="

# 1. Restore previous version
PREVIOUS_VERSION=$(cat awx-backup-*.yaml | grep "image:" | cut -d: -f2)

echo "Rolling back to version: ${PREVIOUS_VERSION}"

kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "image": "quay.io/ansible/awx:'${PREVIOUS_VERSION}'"
  }
}'

# 2. Monitor rollback
kubectl get pods -n ${NAMESPACE} -w

# 3. Check for any database issues
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage dbshell <<EOF
-- Check for migration issues
SELECT * FROM django_migrations ORDER BY id DESC LIMIT 10;
EOF

echo "Rollback completed!"
```

#### 2. Database Rollback (If Corrupted)

```bash
#!/bin/bash
# rollback-database.sh

echo "=== Rolling back AWX Database ==="

# WARNING: This will restore database from backup
# All data since backup will be lost

# 1. Scale down AWX
kubectl scale deployment awx-${NAME}-web -n ${NAMESPACE} --replicas=0
kubectl scale deployment awx-${NAME}-task -n ${NAMESPACE} --replicas=0

# 2. Restore database from backup (example for RDS)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier awx-postgres-prod \
  --target-db-instance-identifier awx-postgres-prod-restored \
  --restore-time "2024-01-20T10:00:00Z"

# Wait for restore...
aws rds wait db-instance-available --db-instance-identifier awx-postgres-prod-restored

# 3. Update secret to point to restored DB
kubectl patch secret awx-${NAME}-postgres-configuration -n ${NAMESPACE} --patch '{
  "stringData": {
    "host": "awx-postgres-prod-restored.xxx.us-east-1.rds.amazonaws.com"
  }
}'

# 4. Scale AWX back up
kubectl scale deployment awx-${NAME}-web -n ${NAMESPACE} --replicas=2
kubectl scale deployment awx-${NAME}-task -n ${NAMESPACE} --replicas=2

echo "Database rollback completed!"
```

### Version Compatibility Matrix

| AWX Version | Operator Version | PostgreSQL Version | Kubernetes Version | Notes |
|-------------|------------------|-------------------|-------------------|--------|
| 22.x | 2.x | 13+ | 1.21+ | Current |
| 21.x | 1.x | 13+ | 1.20+ | Stable |
| 20.x | 0.x | 12+ | 1.19+ | Legacy |

### Upgrade Best Practices

1. **Never skip versions** - Upgrade incrementally
2. **Test in staging first** - Always validate upgrades
3. **Backup everything** - Configuration, database, secrets
4. **Check compatibility** - Review AWX release notes
5. **Monitor resources** - Ensure cluster has capacity
6. **Plan downtime** - Expect 10-30 minutes downtime
7. **Coordinate with teams** - Notify automation users

### Upgrade Automation

```bash
#!/bin/bash
# automated-upgrade.sh

set -e

TARGET_VERSION=${1}
current_version=$(kubectl get awx ${NAME} -n ${NAMESPACE} -o jsonpath='{.spec.image}' | cut -d: -f2)

echo "Upgrading AWX from ${current_version} to ${TARGET_VERSION}"

# Pre-upgrade checks
./pre-upgrade-checks.sh

# Create maintenance window
# Notify users (if production)
if [[ "${ENVIRONMENT}" == "production" ]]; then
  curl -X POST https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK \
    -d '{"text":"AWX upgrade starting: '${current_version}' → '${TARGET_VERSION}'"}'
fi

# Upgrade operator if needed
if [[ "${UPGRADE_OPERATOR}" == "true" ]]; then
  echo "Upgrading operator..."
  kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/${OPERATOR_VERSION}/deploy/awx-operator.yaml
  kubectl wait --for=condition=available deployment/awx-operator-controller-manager -n awx-operator --timeout=600s
fi

# Upgrade AWX
echo "Upgrading AWX..."
kubectl patch awx ${NAME} -n ${NAMESPACE} --type merge -p '{
  "spec": {
    "image": "quay.io/ansible/awx:'${TARGET_VERSION}'"
  }
}'

# Monitor upgrade
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-${NAME} -n ${NAMESPACE} --timeout=1800s

# Post-upgrade verification
./post-upgrade-verification.sh

# Notify completion
if [[ "${ENVIRONMENT}" == "production" ]]; then
  curl -X POST https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK \
    -d '{"text":"AWX upgrade completed: '${TARGET_VERSION}'"}'
fi

echo "Upgrade completed successfully!"
```

### Upgrade Rollback Decision Tree

```
Upgrade Started
    ↓
Pods Not Starting?
    ├─→ YES → Check logs → Database issue?
    │              ├─→ YES → Restore DB from backup → Restart pods
    │              └─→ NO → Revert image version → Restart pods
    └─→ NO → AWX API responding?
           ├─→ NO → Check operator logs → Manual intervention needed?
           │         └─→ YES → Rollback to previous version
           └─→ YES → Jobs failing?
                   ├─→ YES → Check logs → Config issue?
                   │         ├─→ YES → Fix config → Re-test
                   │         └─→ NO → Rollback
                   └→ NO → All tests pass?
                           ├→ NO → Continue monitoring → Extended test period
                           └→ YES → Upgrade successful!
```

### Database Migration Considerations

```bash
# Check for long-running migrations
kubectl exec -it awx-${NAME}-task-0 -n ${NAMESPACE} -- \
  awx-manage dbshell

# Within psql:
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity 
WHERE query LIKE '%django_migrations%'
AND state = 'active';

# If migration hangs for >30 minutes:
# 1. Check for locks
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

# 2. Kill blocking PID if safe (CAUTION!)
# SELECT pg_terminate_backend(blocking_pid);
```

### Upgrade Logging and Auditing

```bash
# Comprehensive upgrade logging
#!/bin/bash
exec > >(tee -a /var/log/awx-upgrade.log) 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting AWX upgrade"
echo "User: $(whoami)"
echo "From: $(kubectl get awx ${NAME} -n ${NAMESPACE} -o jsonpath='{.spec.image}')"
echo "To: quay.io/ansible/awx:${TARGET_VERSION}"

# Run upgrade commands...

if [ $? -eq 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Upgrade completed successfully"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Upgrade failed"
  exit 1
fi
```

### Staged Rollout (Canary Upgrades)

```yaml
# Deploy new version alongside existing
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-${NAME}-v22
  namespace: ${NAMESPACE}
spec:
  image: quay.io/ansible/awx:22.7.0
  hostname: awx-v22.example.com  # Different hostname
  # Use same database or replica
  
# Test thoroughly on v22
# Gradually migrate traffic via ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: awx-${NAME}-canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - host: awx.example.com
    http:
      paths:
      - backend:
          service:
            name: awx-${NAME}-v22-service
```
