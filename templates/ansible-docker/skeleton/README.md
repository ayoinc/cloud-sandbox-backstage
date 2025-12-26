# ${{ values.name }}

${{ values.description }}

## Overview

Ansible role for Docker container deployment and management.

## Requirements

- Ansible 2.12+
- Docker Engine on target hosts
- community.docker collection

## Installation

```bash
ansible-galaxy install -r requirements.yml
```

## Role Variables

See `defaults/main.yml` for configurable variables.

## Usage

```yaml
- hosts: docker_hosts
  roles:
    - role: ${{ values.name }}
      vars:
        docker_compose_version: "2.20.0"
```

## Testing

```bash
molecule test
```

## License

MIT

## Author

${{ values.owner }}
