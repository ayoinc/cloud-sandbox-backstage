# Usage Examples

This document provides various usage examples for the Docker role.

## Basic Playbook

### Install Docker with Defaults

```yaml
---
- name: Install Docker
  hosts: docker_hosts
  become: true
  roles:
    - ${{ values.name }}
```

### Install with Custom Users

```yaml
---
- name: Install Docker with custom users
  hosts: docker_hosts
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        docker_users:
          - deploy
          - jenkins
          - '{{ ansible_user }}'
```

## Production Deployment

### High-Availability Setup

```yaml
---
- name: Configure Docker for production
  hosts: docker_hosts
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        docker_edition: ce
        docker_compose_install: true
        docker_daemon_options:
          storage-driver: overlay2
          live-restore: true
          log-driver: json-file
          log-opts:
            max-size: '100m'
            max-file: '10'
          default-ulimits:
            nofile:
              Name: nofile
              Hard: 65536
              Soft: 65536
          metrics-addr: '0.0.0.0:9323'
          experimental: true
```

### With Private Registry

```yaml
---
- name: Configure Docker with private registry
  hosts: docker_hosts
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        docker_insecure_registries:
          - 'registry.internal.company.com:5000'
        docker_registry_mirrors:
          - 'https://mirror.gcr.io'
```

## Inventory Examples

### Simple Inventory

```ini
[docker_hosts]
server1.example.com
server2.example.com
server3.example.com
```

### Inventory with Variables

```ini
[docker_hosts]
server1.example.com docker_users='["deploy","app"]'
server2.example.com docker_storage_driver=overlay2

[docker_hosts:vars]
docker_edition=ce
docker_compose_install=true
```

### YAML Inventory

```yaml
all:
  children:
    docker_hosts:
      hosts:
        server1.example.com:
        server2.example.com:
      vars:
        docker_edition: ce
        docker_compose_install: true
        docker_users:
          - deploy
```

## Running the Playbook

### Basic Execution

```bash
ansible-playbook -i inventory playbook.yml
```

### With Extra Variables

```bash
ansible-playbook -i inventory playbook.yml \
  -e "docker_version=24.0.0" \
  -e "docker_compose_install=true"
```

### Check Mode (Dry Run)

```bash
ansible-playbook -i inventory playbook.yml --check --diff
```

### Limit to Specific Hosts

```bash
ansible-playbook -i inventory playbook.yml --limit "server1.example.com"
```

## Integration with AWX/Tower

### Job Template Variables

```yaml
docker_edition: ce
docker_compose_install: true
docker_users:
  - awx
  - deploy
docker_daemon_options:
  log-driver: journald
```

### Survey Variables

Create a survey with these questions:

- Docker Edition (ce/ee)
- Install Docker Compose (yes/no)
- Docker Users (comma-separated)

## Troubleshooting

### Verify Docker Installation

```bash
ansible docker_hosts -i inventory -m shell -a "docker --version"
```

### Check Docker Service Status

```bash
ansible docker_hosts -i inventory -m service -a "name=docker" --become
```

### Test Docker Functionality

```bash
ansible docker_hosts -i inventory -m docker_container -a "name=test image=hello-world state=started" --become
```
