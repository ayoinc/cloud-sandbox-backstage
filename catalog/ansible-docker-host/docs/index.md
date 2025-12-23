# Ansible Docker Host Playbook

Production-ready Ansible playbook for automated Docker and Docker Compose installation, configuration, and security hardening on Linux hosts.

## Quick Start

### Prerequisites

```bash
# Install Ansible (2.15+)
pip install ansible ansible-lint

# Verify installation
ansible --version
# ansible [core 2.15.0]

# Install required collections
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
```

### Basic Deployment

```bash
# Clone the playbook repository
git clone https://github.com/company/ansible-docker-host.git
cd ansible-docker-host

# Configure inventory
cp inventory/example.ini inventory/production.ini
vim inventory/production.ini

# Run the playbook
ansible-playbook -i inventory/production.ini site.yml

# Dry run
ansible-playbook -i inventory/production.ini site.yml --check --diff
```

### Quick One-Liner

```bash
# Install Docker on a single host
ansible-playbook -i "server.example.com," -u deploy --become site.yml
```

## Features

| Feature | Description | Default |
|---------|-------------|---------|
| **Docker CE Installation** | Latest stable Docker Engine | Enabled |
| **Docker Compose** | V2 plugin and standalone | Both |
| **Container Runtime** | containerd with proper configuration | Enabled |
| **Registry Configuration** | Private registry support, mirrors | Optional |
| **Storage Driver** | overlay2 with optimal settings | overlay2 |
| **Logging Configuration** | JSON-file, journald, fluentd | json-file |
| **Security Hardening** | CIS Docker Benchmark compliance | Enabled |
| **User Management** | Docker group membership | Configurable |
| **Network Configuration** | Bridge, overlay, custom networks | Enabled |
| **Swarm Mode** | Optional Swarm cluster setup | Optional |
| **GPU Support** | NVIDIA Container Toolkit | Optional |
| **Monitoring** | Prometheus metrics, cAdvisor | Optional |

## Architecture Overview

```
+------------------------------------------------------------------+
|                    Ansible Control Node                           |
+------------------------------------------------------------------+
|  +-------------------+  +-------------------+  +----------------+ |
|  |   Inventory       |  |   Playbooks       |  |   Roles        | |
|  |   - docker_hosts  |  |   - site.yml      |  |   - common     | |
|  |   - swarm_managers|  |   - docker.yml    |  |   - docker     | |
|  |   - swarm_workers |  |   - swarm.yml     |  |   - compose    | |
|  +-------------------+  +-------------------+  |   - security   | |
+------------------------------------------------------------------+
                              |
        +---------------------+---------------------+
        |                     |                     |
        v                     v                     v
+----------------+    +----------------+    +----------------+
|  Docker Host 1 |    |  Docker Host 2 |    |  Docker Host 3 |
|  Ubuntu 22.04  |    |  Rocky Linux 9 |    |  Debian 12     |
|                |    |                |    |                |
|  +----------+  |    |  +----------+  |    |  +----------+  |
|  | Docker   |  |    |  | Docker   |  |    |  | Docker   |  |
|  | Engine   |  |    |  | Engine   |  |    |  | Engine   |  |
|  +----------+  |    |  +----------+  |    |  +----------+  |
|  | Compose  |  |    |  | Compose  |  |    |  | Compose  |  |
|  +----------+  |    |  +----------+  |    |  +----------+  |
|  | containerd| |    |  | containerd| |    |  | containerd| |
|  +----------+  |    |  +----------+  |    |  +----------+  |
+----------------+    +----------------+    +----------------+
```

## Supported Platforms

| OS | Version | Docker Version | Status |
|----|---------|----------------|--------|
| Ubuntu | 20.04, 22.04, 24.04 | 24.x, 25.x | Tested |
| Debian | 11, 12 | 24.x, 25.x | Tested |
| RHEL | 8, 9 | 24.x, 25.x | Tested |
| Rocky Linux | 8, 9 | 24.x, 25.x | Tested |
| AlmaLinux | 8, 9 | 24.x, 25.x | Tested |
| Amazon Linux | 2, 2023 | 24.x, 25.x | Tested |
| Fedora | 38, 39, 40 | 24.x, 25.x | Tested |

## Project Structure

```
ansible-docker-host/
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── requirements.yml         # Galaxy requirements
├── inventory/
│   ├── production.ini       # Production inventory
│   └── group_vars/
│       ├── all.yml          # Global variables
│       └── docker_hosts.yml # Docker-specific vars
├── roles/
│   ├── common/              # Base system configuration
│   ├── docker/              # Docker installation
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── install.yml
│   │   │   ├── configure.yml
│   │   │   └── security.yml
│   │   ├── handlers/
│   │   ├── templates/
│   │   │   └── daemon.json.j2
│   │   └── defaults/
│   │       └── main.yml
│   ├── compose/             # Docker Compose setup
│   ├── swarm/               # Swarm mode configuration
│   └── security/            # Security hardening
└── playbooks/
    ├── docker.yml           # Docker only
    ├── swarm-init.yml       # Initialize Swarm
    └── upgrade.yml          # Upgrade Docker
```

## CLI Commands

```bash
# Verify Docker installation
ansible docker_hosts -m shell -a "docker version"

# Check Docker service status
ansible docker_hosts -m service -a "name=docker state=started"

# List running containers
ansible docker_hosts -m shell -a "docker ps"

# Check disk usage
ansible docker_hosts -m shell -a "docker system df"

# Prune unused resources
ansible docker_hosts -m shell -a "docker system prune -af"

# Run with specific tags
ansible-playbook site.yml --tags "docker,compose"

# Skip security hardening
ansible-playbook site.yml --skip-tags "security"
```

## Related Documentation

- [Overview](overview.md) - Deep dive into architecture, roles, and configuration
- [Usage](usage.md) - Deployment examples, Swarm setup, and troubleshooting
