# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible playbook provides automated infrastructure configuration and application deployment capabilities. It follows Ansible best practices with:

- Modular playbook structure with roles and tasks
- Multi-environment inventory management (dev, staging, production)
- Molecule testing for validation and verification
- CI/CD pipeline with linting, security scanning, and automated deployment
- Ansible Vault integration for secrets management
- Idempotent task design for safe re-execution

```d2
direction: right

title: {
  label: Ansible Playbook Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

control: Control Node {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  playbook: Playbooks {
    shape: document
    style.fill: "#BBDEFB"
    style.stroke: "#1976D2"

    site: site.yml
    main: playbook.yml
  }

  roles: Roles {
    shape: folder
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"

    tasks: tasks/
    handlers: handlers/
    vars: vars/
    defaults: defaults/
    templates: templates/
    files: files/
  }

  inventory: Inventory {
    shape: cylinder
    style.fill: "#FFE0B2"
    style.stroke: "#F57C00"

    dev: dev
    staging: staging
    prod: production
  }

  vault: Ansible Vault {
    shape: hexagon
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  playbook -> roles: includes
  playbook -> inventory: targets
  roles -> vault: secrets
}

managed: Managed Nodes {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  web: Web Servers {
    shape: rectangle
    web1: web-01
    web2: web-02
  }

  app: App Servers {
    shape: rectangle
    app1: app-01
    app2: app-02
  }

  db: DB Servers {
    shape: rectangle
    db1: db-01
    db2: db-02
  }
}

control.inventory -> managed: SSH
```

## Configuration Summary

| Setting                 | Value                            |
| ----------------------- | -------------------------------- |
| Playbook Name           | `${{ values.name }}`             |
| Owner                   | `${{ values.owner }}`            |
| System                  | `${{ values.system }}`           |
| Ansible Version         | 2.17+                            |
| Python Version          | 3.12+                            |
| Default Inventory       | `inventory/hosts`                |
| Molecule Driver         | Docker                           |
| CI/CD Platform          | GitHub Actions                   |

## Project Structure

```
${{ values.name }}/
├── ansible.cfg              # Ansible configuration (forks, SSH, logging)
├── catalog-info.yaml        # Backstage catalog entry
├── docs/                    # TechDocs documentation
│   └── index.md
├── mkdocs.yml               # MkDocs configuration
├── .github/
│   └── workflows/
│       └── ansible.yaml     # CI/CD pipeline
├── inventory/               # Host inventories
│   ├── hosts                # Default inventory (INI format)
│   ├── dev/                 # Development environment
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/             # Staging environment
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── production/          # Production environment
│       ├── hosts.yml
│       └── group_vars/
├── molecule/                # Molecule test framework
│   └── default/
│       ├── molecule.yml     # Test configuration
│       ├── converge.yml     # Test playbook
│       └── verify.yml       # Verification tasks
├── playbook.yml             # Main playbook
├── requirements.yml         # Galaxy dependencies
├── roles/                   # Custom roles (add as needed)
│   └── example_role/
│       ├── defaults/
│       ├── handlers/
│       ├── tasks/
│       ├── templates/
│       └── vars/
├── group_vars/              # Group variables
│   └── all.yml
├── host_vars/               # Host-specific variables
└── README.md
```

### Key Files

| File                | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| `ansible.cfg`       | Configuration settings (SSH, performance, logging)    |
| `playbook.yml`      | Main playbook with tasks and handlers                  |
| `inventory/hosts`   | Default inventory with host groups                     |
| `requirements.yml`  | Ansible Galaxy collections and roles                   |
| `molecule/`         | Test scenarios for playbook validation                 |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with multi-stage validation and deployment.

### Pipeline Stages

- **Lint**: ansible-lint, yamllint, and syntax checking
- **Security**: Trivy IaC scanning, TruffleHog secret detection, vault validation
- **Test**: Molecule tests across multiple Linux distributions
- **Validate**: Inventory validation, variable file checks, dependency verification
- **Dry Run**: Check mode execution on pull requests
- **Deploy**: Automated deployment with environment targeting
- **Docs**: Role documentation generation with ansible-doctor

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "ansible-lint\nyamllint\nSyntax Check"
}

parallel: {
  style.fill: "#FAFAFA"
  style.stroke: "#9E9E9E"
  style.stroke-dash: 3

  security: Security {
    style.fill: "#FFCDD2"
    style.stroke: "#D32F2F"
    label: "Trivy\nTruffleHog\nVault Check"
  }

  test: Molecule {
    style.fill: "#E1BEE7"
    style.stroke: "#7B1FA2"
    label: "Ubuntu 24.04\nDebian 12\nRocky Linux 9"
  }

  validate: Validate {
    style.fill: "#FFE0B2"
    style.stroke: "#F57C00"
    label: "Inventory\nVariables\nDependencies"
  }
}

dryrun: Dry Run {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Check Mode\nDiff Output"
}

approval: Approval {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nReview"
}

deploy: Deploy {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Run Playbook\nTarget Hosts"
}

pr -> lint
lint -> parallel.security
lint -> parallel.test
lint -> parallel.validate
parallel.security -> dryrun
parallel.test -> dryrun
parallel.validate -> dryrun
dryrun -> approval
approval -> deploy
```

### Workflow Triggers

| Trigger            | Actions                                                    |
| ------------------ | ---------------------------------------------------------- |
| Pull Request       | Lint, Security, Test, Validate, Dry Run                    |
| Push to main       | Lint, Security, Test, Validate, Deploy (dev)               |
| Push to develop    | Lint, Security, Test, Validate                             |
| Manual Dispatch    | Full pipeline with environment selection                   |

---

## Prerequisites

### 1. Local Development Requirements

#### Install Ansible

```bash
# Using pip (recommended)
python3 -m pip install --user ansible-core>=2.17

# macOS with Homebrew
brew install ansible

# Ubuntu/Debian
sudo apt update && sudo apt install ansible

# Verify installation
ansible --version
```

#### Install Additional Tools

```bash
# Linting tools
pip install ansible-lint yamllint

# Molecule for testing
pip install molecule molecule-plugins[docker]

# Docker (required for Molecule)
# Install Docker Desktop or Docker Engine
```

### 2. SSH Access Configuration

#### Generate SSH Key (if needed)

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "ansible@${{ values.name }}" -f ~/.ssh/ansible_key

# Copy public key to target hosts
ssh-copy-id -i ~/.ssh/ansible_key.pub user@target-host
```

#### Configure SSH Agent

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/ansible_key

# Test connectivity
ssh -i ~/.ssh/ansible_key user@target-host hostname
```

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                    | Description                          | Required |
| ------------------------- | ------------------------------------ | -------- |
| `SSH_PRIVATE_KEY`         | SSH private key for target hosts     | Yes      |
| `SSH_HOST`                | Target host for ssh-keyscan          | Yes      |
| `ANSIBLE_VAULT_PASSWORD`  | Password for decrypting vault files  | Yes      |

#### GitHub Environments

Configure environments in **Settings > Environments**:

| Environment | Protection Rules                  | Reviewers          |
| ----------- | --------------------------------- | ------------------ |
| `dev`       | None                              | -                  |
| `staging`   | Required reviewers (optional)     | Team leads         |
| `prod`      | Required reviewers, main only     | Senior engineers   |

---

## Usage

### Install Dependencies

```bash
# Install Galaxy collections and roles
ansible-galaxy install -r requirements.yml --force

# Verify installed collections
ansible-galaxy collection list
```

### Configure Inventory

Edit `inventory/hosts` or create environment-specific inventories:

```ini
# inventory/hosts (INI format)
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[databases]
db1.example.com ansible_host=192.168.1.20

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

Or use YAML format (`inventory/dev/hosts.yml`):

```yaml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_host: 192.168.1.10
        web2.example.com:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1.example.com:
          ansible_host: 192.168.1.20
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/ansible_key
```

### Run the Playbook

```bash
# Check connectivity to all hosts
ansible all -m ping -i inventory/hosts

# Run with default inventory
ansible-playbook playbook.yml

# Run with specific inventory
ansible-playbook playbook.yml -i inventory/production/hosts.yml

# Dry run (check mode) with diff output
ansible-playbook playbook.yml --check --diff

# Verbose output for debugging
ansible-playbook playbook.yml -vvv

# Limit to specific hosts or groups
ansible-playbook playbook.yml --limit webservers

# Run with extra variables
ansible-playbook playbook.yml -e "app_version=2.0.0 deploy_env=production"
```

### Using Tags

```bash
# List available tags
ansible-playbook playbook.yml --list-tags

# Run only tasks with specific tags
ansible-playbook playbook.yml --tags "install,configure"

# Skip tasks with specific tags
ansible-playbook playbook.yml --skip-tags "cleanup"
```

### Step-by-Step Execution

```bash
# Execute one task at a time (interactive)
ansible-playbook playbook.yml --step

# Start from a specific task
ansible-playbook playbook.yml --start-at-task="Configure application"
```

---

## Variables and Vault

### Variable Precedence

Ansible uses the following precedence (highest to lowest):

1. Extra vars (`-e` on command line)
2. Task vars
3. Block vars
4. Role and include vars
5. Set_facts / registered vars
6. Play vars_files
7. Play vars_prompt
8. Play vars
9. Host facts / cached set_facts
10. Playbook host_vars
11. Inventory host_vars
12. Playbook group_vars
13. Inventory group_vars
14. Role defaults

### Defining Variables

#### Group Variables (`group_vars/all.yml`)

```yaml
---
# Common variables for all hosts
app_name: ${{ values.name }}
app_user: appuser
app_group: appgroup

# Package management
common_packages:
  - vim
  - curl
  - git
  - htop

# Timezone
system_timezone: UTC
```

#### Host Variables (`host_vars/web1.example.com.yml`)

```yaml
---
# Host-specific overrides
nginx_worker_processes: 4
nginx_worker_connections: 2048
```

### Ansible Vault

#### Create Encrypted Variables

```bash
# Create a new vault file
ansible-vault create group_vars/all/vault.yml

# Edit existing vault file
ansible-vault edit group_vars/all/vault.yml

# Encrypt an existing file
ansible-vault encrypt secrets.yml

# Decrypt a file
ansible-vault decrypt secrets.yml

# View encrypted file contents
ansible-vault view group_vars/all/vault.yml
```

#### Vault File Structure

```yaml
# group_vars/all/vault.yml (encrypted)
---
vault_db_password: "supersecretpassword"
vault_api_key: "abc123def456"
vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
```

#### Using Vault Variables

```yaml
# group_vars/all/main.yml (unencrypted)
---
db_password: "{{ vault_db_password }}"
api_key: "{{ vault_api_key }}"
```

#### Running with Vault

```bash
# Prompt for vault password
ansible-playbook playbook.yml --ask-vault-pass

# Use a password file
ansible-playbook playbook.yml --vault-password-file=.vault_password

# Multiple vault passwords
ansible-playbook playbook.yml --vault-id dev@.vault_password_dev --vault-id prod@.vault_password_prod
```

---

## Testing with Molecule

This playbook includes Molecule for automated testing.

### Molecule Configuration

The test configuration is in `molecule/default/molecule.yml`:

```yaml
---
driver:
  name: docker

platforms:
  - name: instance
    image: "geerlingguy/docker-${MOLECULE_DISTRO:-rockylinux8}-ansible:latest"
    privileged: true
    pre_build_image: true

provisioner:
  name: ansible
  playbooks:
    converge: converge.yml
    verify: verify.yml

verifier:
  name: ansible
```

### Running Tests

```bash
# Full test sequence (create, converge, verify, destroy)
molecule test

# Create test instance without running tests
molecule create

# Run playbook against test instance
molecule converge

# Run verification tests
molecule verify

# Test for idempotence (run converge twice)
molecule converge && molecule idempotence

# SSH into test instance for debugging
molecule login

# Destroy test environment
molecule destroy

# Test against specific distribution
MOLECULE_DISTRO=ubuntu2404 molecule test
MOLECULE_DISTRO=debian12 molecule test
MOLECULE_DISTRO=rockylinux9 molecule test
```

### Test Sequence

| Stage        | Description                                       |
| ------------ | ------------------------------------------------- |
| dependency   | Install Galaxy dependencies                       |
| cleanup      | Run cleanup playbook                              |
| destroy      | Destroy any existing instances                    |
| syntax       | Verify playbook syntax                            |
| create       | Create test instances                             |
| prepare      | Run preparation playbook                          |
| converge     | Run the main playbook                             |
| idempotence  | Run converge again (should have no changes)       |
| side_effect  | Run side effect playbook                          |
| verify       | Run verification tests                            |
| cleanup      | Run cleanup playbook                              |
| destroy      | Destroy test instances                            |

### Writing Verification Tests

```yaml
# molecule/default/verify.yml
---
- name: Verify
  hosts: all
  gather_facts: true
  tasks:
    - name: Check application directory exists
      stat:
        path: /opt/${{ values.name }}
      register: app_dir
      failed_when: not app_dir.stat.exists

    - name: Verify service is running
      service_facts:

    - name: Assert service is running
      assert:
        that:
          - "'myservice' in services"
          - "services['myservice'].state == 'running'"
        fail_msg: "Service is not running"
```

---

## Troubleshooting

### Connection Issues

**SSH Connection Failures**

```bash
# Test SSH connectivity directly
ssh -vvv -i ~/.ssh/ansible_key user@target-host

# Test Ansible connectivity
ansible all -m ping -i inventory/hosts -vvv

# Check SSH configuration
ansible-config dump | grep -i ssh
```

**Host Key Verification Failed**

```bash
# Option 1: Add to known_hosts
ssh-keyscan -H target-host >> ~/.ssh/known_hosts

# Option 2: Disable in ansible.cfg (not recommended for production)
# host_key_checking = False
```

### Permission Issues

**Permission Denied (Sudo)**

```bash
# Run with become and password prompt
ansible-playbook playbook.yml --become --ask-become-pass

# Verify sudo access on target
ssh user@target-host "sudo -l"
```

**Unreachable Host**

```bash
# Check firewall rules
ansible target-host -m raw -a "sudo iptables -L -n"

# Verify port is open
nc -zv target-host 22
```

### Syntax and Validation Errors

**Check Playbook Syntax**

```bash
# Validate syntax
ansible-playbook playbook.yml --syntax-check

# List all tasks
ansible-playbook playbook.yml --list-tasks

# List all hosts
ansible-playbook playbook.yml --list-hosts
```

**Debug Variable Values**

```yaml
# Add debug task to playbook
- name: Debug variables
  debug:
    var: my_variable

- name: Debug all variables
  debug:
    var: vars
```

### Vault Issues

**Vault Password Errors**

```bash
# Reset vault password
ansible-vault rekey group_vars/all/vault.yml

# Verify vault file is encrypted
head -1 group_vars/all/vault.yml
# Should show: $ANSIBLE_VAULT;1.1;AES256
```

### Molecule Test Failures

**Docker Connection Issues**

```bash
# Verify Docker is running
docker info

# Clean up Docker resources
docker system prune -f

# Rebuild Molecule instances
molecule destroy && molecule create
```

**Idempotence Failures**

```bash
# Run converge with verbose output
molecule converge -- -vvv

# Check for changed tasks
molecule idempotence
```

### Common Error Messages

| Error                                           | Cause                                     | Solution                                    |
| ----------------------------------------------- | ----------------------------------------- | ------------------------------------------- |
| `UNREACHABLE!`                                  | SSH connection failed                     | Check SSH key, firewall, host availability  |
| `Permission denied`                             | Insufficient privileges                   | Add `become: true` or check sudo access     |
| `Vault password file not found`                 | Missing vault password file               | Create `.vault_password` file               |
| `No hosts matched`                              | Inventory mismatch                        | Check inventory file and host patterns      |
| `MODULE FAILURE`                                | Task execution error                      | Run with `-vvv` for detailed error          |
| `ANSIBLE_VAULT; decryption failed`              | Wrong vault password                      | Verify vault password                       |

---

## Related Templates

| Template                                                        | Description                            |
| --------------------------------------------------------------- | -------------------------------------- |
| [ansible-role](/docs/default/template/ansible-role)             | Standalone Ansible role                |
| [ansible-collection](/docs/default/template/ansible-collection) | Ansible Galaxy collection              |
| [terraform-module](/docs/default/template/terraform-module)     | Terraform infrastructure module        |
| [aws-ec2](/docs/default/template/aws-ec2)                       | AWS EC2 instances to target            |
| [azure-vm](/docs/default/template/azure-vm)                     | Azure VMs for Ansible management       |
| [gcp-compute](/docs/default/template/gcp-compute)               | GCP Compute instances                  |

---

## References

### Documentation

- [Ansible Documentation](https://docs.ansible.com/ansible/latest/index.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Molecule Testing Documentation](https://molecule.readthedocs.io/)
- [Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [Ansible Galaxy](https://galaxy.ansible.com/)

### Tools

- [ansible-lint](https://ansible.readthedocs.io/projects/lint/) - Linting for Ansible
- [yamllint](https://yamllint.readthedocs.io/) - YAML linter
- [Molecule](https://molecule.readthedocs.io/) - Testing framework
- [ansible-doctor](https://ansible-doctor.geekdocs.de/) - Documentation generator

### Community

- [Ansible Community Forum](https://forum.ansible.com/)
- [Ansible GitHub](https://github.com/ansible/ansible)
- [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)

---

## Support

- **Owner**: ${{ values.owner }}
- **System**: ${{ values.system }}
- **Repository**: [GitHub](${{ values.repoUrl }})
