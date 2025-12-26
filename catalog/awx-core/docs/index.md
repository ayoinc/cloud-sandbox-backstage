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

| Feature           | Description                  | Benefit                    |
| ----------------- | ---------------------------- | -------------------------- |
| **Web UI**        | Modern React-based interface | Easy visual management     |
| **REST API**      | Full-featured RESTful API    | Automation and integration |
| **RBAC**          | Role-based access control    | Secure multi-tenancy       |
| **Inventories**   | Dynamic and static hosts     | Flexible target management |
| **Credentials**   | Encrypted credential storage | Secure secret management   |
| **Job Templates** | Reusable job configurations  | Standardized automation    |
| **Workflows**     | Multi-playbook orchestration | Complex automation chains  |
| **Scheduling**    | Cron-based job scheduling    | Automated execution        |
| **Notifications** | Slack, email, webhooks       | Real-time alerts           |

## Architecture

```d2
direction: down

title: AWX Platform Architecture {
  shape: text
  near: top-center
  style: {
    font-size: 24
    bold: true
  }
}

users: Users / API Clients {
  shape: rectangle
  style.fill: "#e3f2fd"
}

web_interface: Web Interface Layer {
  style.fill: "#e8f5e9"

  react_ui: React UI {
    shape: rectangle
    style.fill: "#c8e6c9"
  }

  rest_api: REST API\n/api/v2/ {
    shape: rectangle
    style.fill: "#c8e6c9"
  }

  websocket: WebSocket\nJob Output Stream {
    shape: rectangle
    style.fill: "#c8e6c9"
  }
}

awx_task: AWX Task Layer (Django) {
  style.fill: "#fff3e0"

  views: Views\n(API Handlers) {
    shape: rectangle
    style.fill: "#ffe0b2"
  }

  models: Models\n(ORM) {
    shape: rectangle
    style.fill: "#ffe0b2"
  }

  celery: Celery Tasks\n(Job Runner) {
    shape: rectangle
    style.fill: "#ffe0b2"
  }
}

execution: Execution Layer {
  style.fill: "#f3e5f5"

  receptor: Receptor\n(Mesh Network) {
    shape: hexagon
    style.fill: "#e1bee7"
  }

  runner: ansible-runner {
    shape: rectangle
    style.fill: "#e1bee7"
  }

  ee: Execution\nEnvironments {
    shape: rectangle
    style.fill: "#e1bee7"
  }
}

data: Data Layer {
  style.fill: "#e0f7fa"

  postgres: PostgreSQL {
    shape: cylinder
    style.fill: "#80deea"
    label: "Jobs, Credentials\nInventories"
  }

  redis: Redis {
    shape: cylinder
    style.fill: "#80deea"
    label: "Cache, Message\nBroker"
  }

  scm: Project Storage {
    shape: cylinder
    style.fill: "#80deea"
    label: "Git/SCM"
  }
}

target_hosts: Target Hosts {
  shape: rectangle
  style.fill: "#ffcdd2"
  label: "Managed\nInfrastructure"
}

users -> web_interface
web_interface -> awx_task
awx_task -> execution
execution -> data
awx_task.celery -> data.redis: Queue Jobs
awx_task.models -> data.postgres: Persist Data
execution.runner -> target_hosts: SSH/WinRM
execution.receptor -> target_hosts: Mesh Network
```

## Core Components

| Component      | Purpose                       | Technology     |
| -------------- | ----------------------------- | -------------- |
| **awx-web**    | Web UI and API server         | Django, React  |
| **awx-task**   | Background task processing    | Celery         |
| **awx-ee**     | Ansible execution environment | Container      |
| **PostgreSQL** | Persistent data storage       | PostgreSQL 13+ |
| **Redis**      | Cache and message broker      | Redis 6+       |
| **Receptor**   | Mesh networking for execution | Go             |

## Job Types

| Type               | Description               | Use Case            |
| ------------------ | ------------------------- | ------------------- |
| **Job Template**   | Single playbook execution | Standard automation |
| **Workflow**       | Multi-step orchestration  | Complex pipelines   |
| **Inventory Sync** | Dynamic inventory update  | Cloud discovery     |
| **Project Update** | SCM repository sync       | Playbook updates    |
| **Ad Hoc Command** | One-off module execution  | Quick tasks         |

## Credential Types

| Type                   | Purpose                  | Examples                    |
| ---------------------- | ------------------------ | --------------------------- |
| **Machine**            | SSH/WinRM access         | Private keys, passwords     |
| **Source Control**     | Git repository access    | SSH keys, tokens            |
| **Vault**              | Ansible Vault decryption | Vault passwords             |
| **Cloud**              | Cloud provider APIs      | AWS, Azure, GCP credentials |
| **Network**            | Network device access    | Enable passwords            |
| **Container Registry** | Image pull secrets       | Docker Hub, ECR             |

## Version Information

| Component    | Version | Notes                 |
| ------------ | ------- | --------------------- |
| AWX          | 24.0+   | Latest stable         |
| AWX Operator | 2.12+   | Kubernetes deployment |
| Ansible Core | 2.15+   | Execution engine      |
| Python       | 3.11+   | Runtime               |
| PostgreSQL   | 13-16   | Database              |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - API examples and CI/CD integration
