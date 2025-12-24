# Overview

## Architecture Deep Dive

AWX provides enterprise-grade automation capabilities through a modular, container-based architecture designed for scalability and high availability.

### Component Architecture

```d2
direction: down

title: AWX Kubernetes Deployment {
  shape: text
  near: top-center
  style: {
    font-size: 24
    bold: true
  }
}

ingress: Ingress / Load Balancer {
  style.fill: "#fff3e0"
  https: "HTTPS (443)\nAWX Web UI / API" {
    shape: rectangle
    style.fill: "#ffe0b2"
  }
  wss: "WSS\nJob Output Streaming" {
    shape: rectangle
    style.fill: "#ffe0b2"
  }
}

awx_pods: AWX Pods {
  style.fill: "#e8f5e9"
  
  web_pod: AWX Web Pod {
    style.fill: "#c8e6c9"
    nginx: nginx\n(Reverse Proxy) {
      shape: rectangle
    }
    uwsgi: uwsgi\n(Django) {
      shape: rectangle
    }
    nginx -> uwsgi
  }
  
  task_pod: AWX Task Pod {
    style.fill: "#a5d6a7"
    celery: Celery\n(Workers) {
      shape: rectangle
    }
    receptor: Receptor\n(Mesh) {
      shape: hexagon
    }
    dispatcher: Dispatcher\n(Scheduler) {
      shape: rectangle
    }
  }
  
  ee_pod: Execution Environment Pod {
    style.fill: "#81c784"
    runner: ansible-runner\n+ collections\n+ dependencies {
      shape: rectangle
    }
  }
}

data_services: Data Services {
  style.fill: "#e3f2fd"
  
  postgres: PostgreSQL {
    shape: cylinder
    style.fill: "#90caf9"
    label: "Job history\nCredentials\nInventories"
  }
  
  redis: Redis {
    shape: cylinder
    style.fill: "#90caf9"
    label: "Cache\nMessage broker\nWebsocket events"
  }
}

target_hosts: Managed Hosts {
  shape: rectangle
  style.fill: "#ffcdd2"
}

ingress -> awx_pods.web_pod: HTTP/WS
awx_pods.web_pod -> awx_pods.task_pod: Queue Jobs
awx_pods.task_pod -> awx_pods.ee_pod: Launch
awx_pods.task_pod.celery -> data_services.redis: Message Queue
awx_pods.web_pod.uwsgi -> data_services.postgres: Queries
awx_pods.task_pod -> data_services.postgres: Job Data
awx_pods.ee_pod.runner -> target_hosts: SSH/WinRM
awx_pods.task_pod.receptor -> target_hosts: Mesh Network
```

### Job Execution Flow

```d2
direction: down

pipeline: Job Execution Pipeline {
  launch: 1. Job Launch {
    flow: User/API/Schedule -> Create Job -> Queue to Celery
  }
  
  prerun: 2. Pre-run Tasks {
    decrypt: Decrypt credentials
    sync_proj: Sync project (if needed)
    sync_inv: Sync inventory (if dynamic)
    prep_ee: Prepare execution environment
  }
  
  execution: 3. Execution {
    flow: Receptor -> ansible-runner -> Ansible Playbook {
      shape: hexagon
    }
    stream: Stream output via WebSocket
  }
  
  postrun: 4. Post-run Tasks {
    store: Store job output
    notify: Send notifications
    trigger: Trigger dependent workflows
    status: Update job status
  }
  
  launch -> prerun -> execution -> postrun
}
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

```d2
direction: right

rbac: AWX RBAC Model {
  hierarchy: User Hierarchy {
    org: Organization {
      shape: rectangle
    }
    teams: Teams {
      shape: rectangle
    }
    users: Users {
      shape: person
    }
    
    org -> teams: contains
    teams -> users: contains
  }
  
  roles: Permission Roles {
    admin: Admin\nFull control {
      shape: hexagon
    }
    execute: Execute\nRun jobs {
      shape: hexagon
    }
    read: Read\nView details {
      shape: hexagon
    }
    use: Use\nIn templates {
      shape: hexagon
    }
    update: Update\nModify resource {
      shape: hexagon
    }
    approve: Approve\nWorkflow steps {
      shape: hexagon
    }
  }
  
  resources: Resource Hierarchy {
    organization: Organization {
      shape: rectangle
    }
    projects: Projects {
      shape: document
    }
    inventories: Inventories {
      shape: cylinder
    }
    credentials: Credentials {
      shape: document
    }
    job_templates: Job Templates {
      shape: document
    }
    workflow_templates: Workflow Templates {
      shape: document
    }
    execution_envs: Execution Environments {
      shape: hexagon
    }
    
    organization -> projects
    organization -> inventories
    organization -> credentials
    organization -> job_templates
    organization -> workflow_templates
    organization -> execution_envs
  }
  
  hierarchy.users -> roles: assigned
  roles -> resources: grants access
}
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
