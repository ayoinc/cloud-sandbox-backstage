# Overview

## Architecture Deep Dive

AWX provides enterprise-grade automation capabilities through a modular, container-based architecture designed for scalability and high availability.

### Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AWX Kubernetes Deployment                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                     Ingress / Load Balancer                     │     │
│  │  ┌──────────────────────────────────────────────────────────┐  │     │
│  │  │    HTTPS (443) → AWX Web UI / API                        │  │     │
│  │  │    WSS → WebSocket (Job Output Streaming)                │  │     │
│  │  └──────────────────────────────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                     AWX Pods                                    │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │    AWX Web Pod                                          │   │     │
│  │  │    ┌─────────────┐  ┌─────────────┐                    │   │     │
│  │  │    │   nginx     │  │   uwsgi     │                    │   │     │
│  │  │    │  (Reverse   │──│  (Django)   │                    │   │     │
│  │  │    │   Proxy)    │  │             │                    │   │     │
│  │  │    └─────────────┘  └─────────────┘                    │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │    AWX Task Pod                                         │   │     │
│  │  │    ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │   │     │
│  │  │    │   Celery    │  │  Receptor   │  │  Dispatcher  │  │   │     │
│  │  │    │  (Workers)  │  │  (Mesh)     │  │  (Scheduler) │  │   │     │
│  │  │    └─────────────┘  └─────────────┘  └──────────────┘  │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │    Execution Environment Pod (per job)                  │   │     │
│  │  │    ┌─────────────────────────────────────────────────┐  │   │     │
│  │  │    │   ansible-runner + collections + dependencies   │  │   │     │
│  │  │    └─────────────────────────────────────────────────┘  │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                     Data Services                               │     │
│  │  ┌─────────────────────┐  ┌─────────────────────────────────┐  │     │
│  │  │    PostgreSQL       │  │         Redis                   │  │     │
│  │  │  - Job history      │  │  - Cache                        │  │     │
│  │  │  - Credentials      │  │  - Message broker               │  │     │
│  │  │  - Inventories      │  │  - Websocket events             │  │     │
│  │  └─────────────────────┘  └─────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Job Execution Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                      Job Execution Pipeline                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   1. Job Launch                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  User/API/Schedule → Create Job → Queue to Celery       │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│   2. Pre-run Tasks           ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  - Decrypt credentials                                   │    │
│   │  - Sync project (if needed)                             │    │
│   │  - Sync inventory (if dynamic)                          │    │
│   │  - Prepare execution environment                        │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│   3. Execution               ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  Receptor → ansible-runner → Ansible Playbook           │    │
│   │  (Stream output via WebSocket)                          │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│   4. Post-run Tasks          ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │  - Store job output                                      │    │
│   │  - Send notifications                                    │    │
│   │  - Trigger dependent workflows                           │    │
│   │  - Update job status                                     │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Configuration

### AWX Custom Resource

```yaml
# awx-instance.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  # Deployment settings
  replicas: 2
  
  # Web settings
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.example.com
  ingress_annotations: |
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  ingress_tls_secret: awx-tls
  
  # Resource limits
  web_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  
  ee_resource_requirements:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  # Database settings
  postgres_configuration_secret: awx-postgres-configuration
  postgres_storage_class: standard
  postgres_storage_requirements:
    requests:
      storage: 20Gi
  
  # Projects storage
  projects_persistence: true
  projects_storage_class: standard
  projects_storage_size: 10Gi
  
  # Extra settings
  extra_settings:
    - setting: AWX_TASK_ENV
      value:
        HTTPS_PROXY: "http://proxy.example.com:8080"
    - setting: SOCIAL_AUTH_SAML_ENABLED_IDPS
      value:
        corporate:
          entity_id: "https://idp.example.com"
          url: "https://idp.example.com/sso"
          x509cert: "..."
```

### Environment Variables

```yaml
# AWX Task Environment
AWX_TASK_ENV:
  # Proxy settings
  HTTP_PROXY: "http://proxy.example.com:8080"
  HTTPS_PROXY: "http://proxy.example.com:8080"
  NO_PROXY: "localhost,127.0.0.1,.example.com"
  
  # Ansible settings
  ANSIBLE_FORCE_COLOR: "true"
  ANSIBLE_HOST_KEY_CHECKING: "false"
  ANSIBLE_SSH_RETRIES: "5"
  
  # Custom CA certificates
  REQUESTS_CA_BUNDLE: "/etc/pki/tls/certs/ca-bundle.crt"
```

### Settings via API

```python
# settings.py examples
import requests

base_url = "https://awx.example.com/api/v2"
headers = {"Authorization": "Bearer <token>"}

# Configure authentication
settings = {
    # LDAP
    "AUTH_LDAP_SERVER_URI": "ldaps://ldap.example.com:636",
    "AUTH_LDAP_BIND_DN": "cn=awx,ou=services,dc=example,dc=com",
    "AUTH_LDAP_BIND_PASSWORD": "password",
    "AUTH_LDAP_USER_SEARCH": ["ou=users,dc=example,dc=com", "SCOPE_SUBTREE", "(uid=%(user)s)"],
    "AUTH_LDAP_USER_ATTR_MAP": {
        "first_name": "givenName",
        "last_name": "sn",
        "email": "mail"
    },
    "AUTH_LDAP_GROUP_SEARCH": ["ou=groups,dc=example,dc=com", "SCOPE_SUBTREE", "(objectClass=groupOfNames)"],
    "AUTH_LDAP_USER_FLAGS_BY_GROUP": {
        "is_superuser": "cn=awx-admins,ou=groups,dc=example,dc=com"
    },
    
    # SAML
    "SOCIAL_AUTH_SAML_ENABLED_IDPS": {
        "corporate": {
            "entity_id": "https://idp.example.com",
            "url": "https://idp.example.com/sso",
            "x509cert": "MIID..."
        }
    },
    "SOCIAL_AUTH_SAML_SP_ENTITY_ID": "https://awx.example.com",
    
    # Logging
    "LOG_AGGREGATOR_HOST": "https://splunk.example.com:8088",
    "LOG_AGGREGATOR_TYPE": "splunk",
    "LOG_AGGREGATOR_TOKEN": "your-hec-token",
    
    # Misc
    "TOWER_URL_BASE": "https://awx.example.com",
    "DEFAULT_EXECUTION_ENVIRONMENT": 1,
    "GALAXY_IGNORE_CERTS": False,
}

for key, value in settings.items():
    requests.patch(f"{base_url}/settings/{key}/", json={"value": value}, headers=headers)
```

## Security Configuration

### RBAC Model

```
┌──────────────────────────────────────────────────────────────────┐
│                        AWX RBAC Model                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   Organizations (Top-level container)                             │
│   └── Teams (Group of users)                                      │
│       └── Users                                                   │
│                                                                   │
│   Permissions:                                                    │
│   ┌───────────────┬─────────────────────────────────────────┐    │
│   │ Role          │ Permissions                              │    │
│   ├───────────────┼─────────────────────────────────────────┤    │
│   │ Admin         │ Full control over resource              │    │
│   │ Execute       │ Run jobs, view output                   │    │
│   │ Read          │ View resource details                   │    │
│   │ Use           │ Use in job templates                    │    │
│   │ Update        │ Modify resource                         │    │
│   │ Approve       │ Approve workflow steps                  │    │
│   └───────────────┴─────────────────────────────────────────┘    │
│                                                                   │
│   Resource Hierarchy:                                             │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │ Organization                                             │    │
│   │  ├── Projects                                            │    │
│   │  ├── Inventories                                         │    │
│   │  ├── Credentials                                         │    │
│   │  ├── Job Templates                                       │    │
│   │  ├── Workflow Templates                                  │    │
│   │  └── Execution Environments                              │    │
│   └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Credential Encryption

```yaml
# AWX encrypts credentials using Fernet symmetric encryption
# Keys stored in database, encrypted with SECRET_KEY

# Credential Type: Machine
credential:
  name: "Production Servers"
  credential_type: "Machine"
  inputs:
    username: "ansible"
    ssh_key_data: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ... (encrypted at rest)
      -----END OPENSSH PRIVATE KEY-----
    become_method: "sudo"
    become_username: "root"
```

### Network Security

```yaml
# Network policies for AWX
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
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - port: 8052
          protocol: TCP
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8  # Internal network
      ports:
        - port: 22
          protocol: TCP
    - to:
        - namespaceSelector:
            matchLabels:
              name: awx
      ports:
        - port: 5432  # PostgreSQL
        - port: 6379  # Redis
```

## Execution Environments

### Custom Execution Environment

```dockerfile
# Dockerfile for custom EE
ARG EE_BASE_IMAGE=quay.io/ansible/awx-ee:latest
FROM $EE_BASE_IMAGE

# Install additional collections
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Install system packages
RUN dnf install -y \
    gcc \
    python3-devel \
    krb5-devel \
    && dnf clean all
```

```yaml
# execution-environment.yml (for ansible-builder)
version: 3
images:
  base_image:
    name: quay.io/ansible/awx-ee:latest

dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

additional_build_steps:
  prepend_base:
    - RUN whoami
  append_final:
    - RUN pip3 install --upgrade pip
```

### Build and Push EE

```bash
# Install ansible-builder
pip install ansible-builder

# Build execution environment
ansible-builder build \
  --tag registry.example.com/awx-ee-custom:1.0.0 \
  --container-runtime docker

# Push to registry
docker push registry.example.com/awx-ee-custom:1.0.0
```

## Monitoring

### Prometheus Metrics

```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: awx
  namespace: awx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: awx
  endpoints:
    - port: http
      path: /api/v2/metrics/
      interval: 30s
      basicAuth:
        username:
          name: awx-admin-password
          key: username
        password:
          name: awx-admin-password
          key: password
```

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `awx_jobs_total` | Total jobs by status | N/A (tracking) |
| `awx_jobs_pending` | Jobs waiting to run | > 50 |
| `awx_jobs_running` | Currently executing | > capacity |
| `awx_schedule_jobs_pending` | Scheduled jobs in queue | > 100 |
| `awx_instance_capacity` | Available capacity | < 20% |
| `awx_instance_consumed_capacity` | Used capacity | > 80% |

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "AWX Overview",
    "panels": [
      {
        "title": "Job Status",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum(awx_jobs_total) by (status)"
          }
        ]
      },
      {
        "title": "Jobs per Hour",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(awx_jobs_total[1h])"
          }
        ]
      },
      {
        "title": "Capacity Utilization",
        "type": "gauge",
        "targets": [
          {
            "expr": "awx_instance_consumed_capacity / awx_instance_capacity * 100"
          }
        ]
      }
    ]
  }
}
```

## High Availability

### Multi-Node Configuration

```yaml
# AWX with multiple replicas
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  replicas: 3
  
  # External PostgreSQL for HA
  postgres_configuration_secret: awx-external-postgres
  
  # Redis cluster mode
  redis_configuration_secret: awx-redis-cluster
  
  # Shared projects storage
  projects_persistence: true
  projects_storage_class: efs-sc  # Shared filesystem
  
  # Node affinity for spreading
  node_selector: |
    node-role.kubernetes.io/worker: ""
  
  topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
```

### Receptor Mesh

```yaml
# receptor.conf for distributed execution
receptor:
  node_id: hop-node-1
  
  connections:
    - name: awx-main
      host: awx.example.com
      port: 27199
      
  work_commands:
    ansible-runner:
      command: ansible-runner
      params: worker
      
  log_level: info
```
