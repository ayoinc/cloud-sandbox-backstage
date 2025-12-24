# Ansible Webserver Playbook

Production-ready Ansible playbook for automated Nginx and Apache web server configuration and management.

## Quick Start

### Prerequisites

```bash
# Install Ansible (2.15+)
pip install ansible ansible-lint

# Or via package manager
brew install ansible  # macOS
apt install ansible   # Ubuntu/Debian
dnf install ansible   # RHEL/Fedora

# Verify installation
ansible --version
# ansible [core 2.15.0]
```

### Install Required Collections

```bash
# Install required Ansible collections
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

# Or install from requirements file
ansible-galaxy install -r requirements.yml
```

### Basic Playbook Execution

```bash
# Clone the playbook repository
git clone https://github.com/company/ansible-webserver.git
cd ansible-webserver

# Configure inventory
cp inventory/example.ini inventory/production.ini
vim inventory/production.ini

# Run the playbook
ansible-playbook -i inventory/production.ini site.yml

# Dry run (check mode)
ansible-playbook -i inventory/production.ini site.yml --check --diff

# Limit to specific hosts
ansible-playbook -i inventory/production.ini site.yml --limit web01

# Use specific tags
ansible-playbook -i inventory/production.ini site.yml --tags "nginx,ssl"
```

## Features

| Feature                    | Description                            | Default   |
| -------------------------- | -------------------------------------- | --------- |
| **Multi-Server Support**   | Nginx and Apache configuration         | Nginx     |
| **SSL/TLS Management**     | Let's Encrypt and custom certificates  | Enabled   |
| **Virtual Hosts**          | Multiple site configuration            | Supported |
| **Load Balancing**         | Upstream server configuration          | Optional  |
| **Security Hardening**     | CIS benchmarks, ModSecurity            | Enabled   |
| **Performance Tuning**     | Worker processes, caching, compression | Optimized |
| **Monitoring Integration** | Prometheus exporters, log shipping     | Optional  |
| **Backup & Recovery**      | Configuration backup, rollback         | Enabled   |
| **Zero-Downtime Deploy**   | Rolling updates, health checks         | Supported |
| **Multi-OS Support**       | Ubuntu, Debian, RHEL, Rocky            | All major |

## Architecture Overview

```d2
direction: down

control: Ansible Control Node {
  style.fill: "#e3f2fd"

  inventory: Inventory {
    style.fill: "#e8f5e9"
    production: production
    staging: staging
    development: development
  }

  playbooks: Playbooks {
    style.fill: "#fff3e0"
    site: site.yml
    webserver: webserver.yml
    ssl: ssl.yml
  }

  roles: Roles {
    style.fill: "#fce4ec"
    common: common
    nginx: nginx
    apache: apache
    ssl: ssl
    security: security
  }

  group_vars: Group Vars {
    style.fill: "#f3e5f5"
    all: all.yml
    webservers: webservers
  }

  host_vars: Host Vars {
    style.fill: "#e0f7fa"
    web01: web01.yml
    web02: web02.yml
  }
}

servers: Web Servers {
  style.fill: "#f5f5f5"

  web01: Web Server 01 {
    style.fill: "#e8f5e9"
    server: Nginx/Apache
    os: Ubuntu 22.04
  }

  web02: Web Server 02 {
    style.fill: "#fff3e0"
    server: Nginx/Apache
    os: Rocky Linux 9
  }

  web03: Web Server 03 {
    style.fill: "#e3f2fd"
    server: Nginx/Apache
    os: Debian 12
  }
}

control -> servers.web01: SSH
control -> servers.web02: SSH
control -> servers.web03: SSH
```

## Supported Platforms

| OS           | Version             | Web Server    | Status |
| ------------ | ------------------- | ------------- | ------ |
| Ubuntu       | 20.04, 22.04, 24.04 | Nginx, Apache | Tested |
| Debian       | 11, 12              | Nginx, Apache | Tested |
| RHEL         | 8, 9                | Nginx, Apache | Tested |
| Rocky Linux  | 8, 9                | Nginx, Apache | Tested |
| AlmaLinux    | 8, 9                | Nginx, Apache | Tested |
| Amazon Linux | 2, 2023             | Nginx, Apache | Tested |

## Project Structure

```
ansible-webserver/
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── requirements.yml         # Galaxy requirements
├── inventory/
│   ├── production.ini       # Production inventory
│   ├── staging.ini          # Staging inventory
│   └── group_vars/
│       ├── all.yml          # Global variables
│       └── webservers.yml   # Webserver-specific vars
├── roles/
│   ├── common/              # Base system configuration
│   │   ├── tasks/
│   │   ├── handlers/
│   │   ├── templates/
│   │   └── defaults/
│   ├── nginx/               # Nginx configuration
│   ├── apache/              # Apache configuration
│   ├── ssl/                 # SSL/TLS management
│   └── security/            # Security hardening
├── playbooks/
│   ├── webserver.yml        # Webserver setup
│   ├── ssl-renew.yml        # SSL certificate renewal
│   └── backup.yml           # Configuration backup
└── templates/
    ├── nginx/
    │   ├── nginx.conf.j2
    │   └── vhost.conf.j2
    └── apache/
        ├── httpd.conf.j2
        └── vhost.conf.j2
```

## CLI Commands

```bash
# Test connectivity to all hosts
ansible all -i inventory/production.ini -m ping

# Gather facts from web servers
ansible webservers -i inventory/production.ini -m setup

# Run ad-hoc command
ansible webservers -i inventory/production.ini -m shell -a "nginx -t"

# Check Nginx status
ansible webservers -i inventory/production.ini -m service -a "name=nginx state=started"

# Deploy with verbose output
ansible-playbook -i inventory/production.ini site.yml -vvv

# List all tasks
ansible-playbook -i inventory/production.ini site.yml --list-tasks

# List all tags
ansible-playbook -i inventory/production.ini site.yml --list-tags
```

## Related Documentation

- [Overview](overview.md) - Deep dive into architecture, roles, and configuration
- [Usage](usage.md) - Deployment examples, customization, and troubleshooting
