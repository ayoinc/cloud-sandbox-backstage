# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible playbook automates infrastructure configuration and application deployment tasks.

## Prerequisites

- Ansible 2.12 or later
- Python 3.8 or later
- Access to target hosts via SSH
- Required Ansible collections (see `requirements.yml`)

## Quick Start

### Install Dependencies

```bash
# Install required Ansible collections
ansible-galaxy install -r requirements.yml
```

### Configure Inventory

Edit `inventory/hosts.yml` to define your target hosts:

```yaml
all:
  hosts:
    server1:
      ansible_host: 192.168.1.10
    server2:
      ansible_host: 192.168.1.11
```

### Run the Playbook

```bash
# Run with default inventory
ansible-playbook playbook.yml

# Run with specific inventory
ansible-playbook -i inventory/hosts.yml playbook.yml

# Dry run (check mode)
ansible-playbook playbook.yml --check

# Run with verbose output
ansible-playbook playbook.yml -v
```

## Project Structure

```
.
├── ansible.cfg           # Ansible configuration
├── catalog-info.yaml     # Backstage catalog entry
├── docs/                 # Documentation
├── inventory/            # Inventory files
│   └── hosts.yml
├── molecule/             # Molecule tests
│   └── default/
│       ├── converge.yml
│       ├── molecule.yml
│       └── verify.yml
├── playbook.yml          # Main playbook
├── README.md
└── requirements.yml      # Galaxy dependencies
```

## Testing with Molecule

This playbook includes Molecule tests for validation:

```bash
# Install Molecule
pip install molecule molecule-docker

# Run full test sequence
molecule test

# Run converge only (for development)
molecule converge

# Login to test instance
molecule login

# Destroy test environment
molecule destroy
```

## Configuration

### Variables

Key variables can be customized in the playbook or via extra vars:

| Variable | Description | Default |
|----------|-------------|---------|
| `app_name` | Application name | `${{ values.name }}` |

### Tags

Use tags to run specific parts of the playbook:

```bash
# Run only tasks tagged 'install'
ansible-playbook playbook.yml --tags install

# Skip tasks tagged 'configure'
ansible-playbook playbook.yml --skip-tags configure
```

## CI/CD

This playbook includes GitHub Actions workflows for:

- **Linting**: ansible-lint and yamllint validation
- **Testing**: Molecule test execution on pull requests
- **Deployment**: Automated deployment on merge to main

## Troubleshooting

### Common Issues

**SSH Connection Failures**
```bash
# Test SSH connectivity
ansible all -m ping -i inventory/hosts.yml
```

**Permission Denied**
```bash
# Run with become (sudo)
ansible-playbook playbook.yml --become --ask-become-pass
```

**Syntax Errors**
```bash
# Check playbook syntax
ansible-playbook playbook.yml --syntax-check
```

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](${{ values.repoUrl }})
