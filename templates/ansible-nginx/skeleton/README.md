# ${{ values.name }}

${{ values.description }}

## Overview

Ansible role for Nginx web server installation and configuration.

## Requirements

- Ansible 2.12+
- RHEL/CentOS/Ubuntu target hosts

## Installation

```bash
ansible-galaxy install -r requirements.yml
```

## Role Variables

See `defaults/main.yml` for configurable variables.

## Usage

```yaml
- hosts: webservers
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_worker_processes: auto
```

## Testing

```bash
molecule test
```

## License

MIT

## Author

${{ values.owner }}
