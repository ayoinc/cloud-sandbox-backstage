# AWX Core

Open-source automation platform providing a web-based UI, REST API, and task engine for Ansible automation at scale.

## Quick Start

```bash
# Install AWX Operator (recommended method)
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml

# Create AWX instance
cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.example.com
EOF

# Get admin password
kubectl get secret awx-admin-password -o jsonpath='{.data.password}' | base64 -d

# Access AWX UI
open https://awx.example.com

# Install AWX CLI
pip install awxkit

# Configure CLI
export TOWER_HOST=https://awx.example.com
export TOWER_USERNAME=admin
export TOWER_PASSWORD=your-password

# Run a job template
awx job_templates launch "Deploy Application" --monitor
```

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Web UI** | Modern React-based interface | Easy visual management |
| **REST API** | Full-featured RESTful API | Automation and integration |
| **RBAC** | Role-based access control | Secure multi-tenancy |
| **Inventories** | Dynamic and static hosts | Flexible target management |
| **Credentials** | Encrypted credential storage | Secure secret management |
| **Job Templates** | Reusable job configurations | Standardized automation |
| **Workflows** | Multi-playbook orchestration | Complex automation chains |
| **Scheduling** | Cron-based job scheduling | Automated execution |
| **Notifications** | Slack, email, webhooks | Real-time alerts |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AWX Platform                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                      Web Interface                              │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │   React UI  │  │  REST API   │  │  WebSocket (Live)   │    │     │
│  │  │             │  │  /api/v2/   │  │  Job Output Stream  │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                      AWX Task (Django)                          │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │   Views     │  │   Models    │  │   Celery Tasks      │    │     │
│  │  │   (API)     │  │   (ORM)     │  │   (Job Runner)      │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                      Execution Layer                            │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │  Receptor   │  │  ansible-   │  │   Execution         │    │     │
│  │  │  (Mesh)     │  │  runner     │  │   Environments      │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                      Data Layer                                 │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │ PostgreSQL  │  │    Redis    │  │   Project Storage   │    │     │
│  │  │ (Database)  │  │  (Cache/MQ) │  │   (Git/SCM)         │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **awx-web** | Web UI and API server | Django, React |
| **awx-task** | Background task processing | Celery |
| **awx-ee** | Ansible execution environment | Container |
| **PostgreSQL** | Persistent data storage | PostgreSQL 13+ |
| **Redis** | Cache and message broker | Redis 6+ |
| **Receptor** | Mesh networking for execution | Go |

## Job Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Job Template** | Single playbook execution | Standard automation |
| **Workflow** | Multi-step orchestration | Complex pipelines |
| **Inventory Sync** | Dynamic inventory update | Cloud discovery |
| **Project Update** | SCM repository sync | Playbook updates |
| **Ad Hoc Command** | One-off module execution | Quick tasks |

## Credential Types

| Type | Purpose | Examples |
|------|---------|----------|
| **Machine** | SSH/WinRM access | Private keys, passwords |
| **Source Control** | Git repository access | SSH keys, tokens |
| **Vault** | Ansible Vault decryption | Vault passwords |
| **Cloud** | Cloud provider APIs | AWS, Azure, GCP credentials |
| **Network** | Network device access | Enable passwords |
| **Container Registry** | Image pull secrets | Docker Hub, ECR |

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| AWX | 24.0+ | Latest stable |
| AWX Operator | 2.12+ | Kubernetes deployment |
| Ansible Core | 2.15+ | Execution engine |
| Python | 3.11+ | Runtime |
| PostgreSQL | 13-16 | Database |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - API examples and CI/CD integration
