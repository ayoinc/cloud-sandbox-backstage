# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible role installs and configures Docker on target hosts. It supports:

- Docker CE (Community Edition) and Docker EE (Enterprise Edition)
- Multiple Linux distributions (Ubuntu, Debian, CentOS, RHEL, Amazon Linux)
- Docker Compose plugin installation
- User management for Docker group
- Custom Docker daemon configuration

## Requirements

- Ansible 2.9+
- Target hosts running a supported Linux distribution
- Root or sudo access on target hosts

## Quick Start

### Installation

```bash
# Install from Ansible Galaxy
ansible-galaxy install ${{ values.destination.owner }}.${{ values.name }}

# Or clone directly
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
```

### Basic Usage

```yaml
- hosts: docker_hosts
  roles:
    - role: ${{ values.name }}
      vars:
        docker_edition: ${{ values.dockerEdition }}
        docker_compose_install: ${{ values.dockerComposeInstall }}
```

### With Custom Configuration

```yaml
- hosts: docker_hosts
  roles:
    - role: ${{ values.name }}
      vars:
        docker_edition: ce
        docker_users:
          - deploy
          - jenkins
        docker_daemon_options:
          storage-driver: overlay2
          log-driver: json-file
          log-opts:
            max-size: "10m"
            max-file: "3"
```

## Supported Platforms

| Platform | Versions |
|----------|----------|
| Ubuntu | 20.04, 22.04 |
| Debian | 10, 11, 12 |
| CentOS | 7, 8, 9 |
| RHEL | 7, 8, 9 |
| Amazon Linux | 2, 2023 |

## Role Variables

See [Variables](variables.md) for a complete list of configurable variables.

## Testing

This role includes Molecule tests:

```bash
# Install test dependencies
pip install molecule molecule-docker ansible-lint yamllint

# Run tests
molecule test
```

## License

MIT

## Author

${{ values.owner }}
