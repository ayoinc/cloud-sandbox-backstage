# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible role installs and configures Nginx web server. It supports:

- Multiple Linux distributions (Ubuntu, Debian, CentOS, RHEL, Amazon Linux)
- Virtual host configuration
- SSL/TLS certificate management
- Gzip compression
- Reverse proxy configuration
- Load balancing

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
- hosts: webservers
  roles:
    - role: ${{ values.name }}
```

### With Virtual Hosts

```yaml
- hosts: webservers
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_vhosts:
          - server_name: example.com
            root: /var/www/example
            index: index.html
```

## Supported Platforms

| Platform     | Versions     |
| ------------ | ------------ |
| Ubuntu       | 20.04, 22.04 |
| Debian       | 10, 11, 12   |
| CentOS       | 7, 8, 9      |
| RHEL         | 7, 8, 9      |
| Amazon Linux | 2, 2023      |

## Role Variables

See [Variables](variables.md) for a complete list of configurable variables.

## Testing

This role includes Molecule tests:

```bash
pip install molecule molecule-docker ansible-lint yamllint
molecule test
```

## License

MIT

## Author

${{ values.owner }}
