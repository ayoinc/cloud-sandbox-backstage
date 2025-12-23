# Ansible Playbook Template

This template creates a production-ready Ansible playbook project with best practices for infrastructure automation. It provides a structured foundation for managing servers, deploying applications, and automating operational tasks.

## Overview

Ansible is a powerful configuration management and infrastructure automation tool that enables Infrastructure as Code (IaC) through simple, human-readable YAML playbooks. This template streamlines the creation of Ansible projects with:

- **Standardized directory structure** following Ansible best practices
- **Pre-configured roles** for common automation tasks
- **Multi-environment inventory management** (development, staging, production)
- **Integrated testing** with Molecule framework
- **CI/CD pipeline** for automated linting and testing
- **Security hardening** with Ansible Vault integration
- **Performance optimizations** for large-scale deployments

This template is ideal for:
- **Server provisioning and configuration**
- **Application deployment automation**
- **Multi-tier infrastructure management**
- **Configuration drift remediation**
- **Patch management across fleets**
- **Disaster recovery automation**

## Features

### Directory Structure

The template provides a well-organized directory structure that separates concerns and follows Ansible's best practices:

```
project-name/
├── inventories/           # Inventory files per environment
│   ├── production/
│   │   ├── hosts.ini     # Production server inventory
│   │   └── group_vars/   # Production-specific variables
│   ├── staging/
│   │   ├── hosts.ini     # Staging server inventory
│   │   └── group_vars/   # Staging-specific variables
│   └── development/
│       ├── hosts.ini     # Development server inventory
│       └── group_vars/   # Development-specific variables
├── playbooks/           # Main playbook files
│   ├── site.yml        # Master playbook (includes others)
│   ├── webservers.yml   # Web server configuration
│   ├── databases.yml    # Database server setup
│   └── monitoring.yml   # Monitoring and observability
├── roles/              # Reusable automation components
│   ├── common/         # Common system configurations
│   ├── webapp/         # Web application deployment
│   └── database/       # Database management
├── group_vars/         # Global group variables
├── host_vars/          # Host-specific variables
├── requirements.yml    # Ansible Galaxy dependencies
├── ansible.cfg        # Ansible configuration
├── molecule/          # Testing framework
└── .github/workflows/ # CI/CD automation
```

### Automation Features

- **Idempotent Operations** - Safe to run repeatedly without side effects
- **Parallel Execution** - Configure up to 50 parallel forks for faster deployments
- **Smart Fact Caching** - Reduces connection overhead on repeated runs
- **SSH Optimization** - Connection multiplexing and pipelining for speed
- **Error Handling** - Comprehensive failure modes with detailed logging
- **Tag-based Execution** - Run specific parts of your automation
- **Check Mode Support** - Dry-run capability for testing changes

### Governance Features

- **Multi-Environment Support** - Separate configurations for dev/staging/prod
- **Role Reusability** - Shareable automation components
- **Version Control Ready** - Git-optimized structure
- **Documentation Generation** - Inline documentation and examples
- **Security by Design** - Vault integration for secrets management
- **Testing Framework** - Molecule for role validation
- **CI/CD Integration** - GitHub Actions for automation

## Prerequisites

Before using this template, ensure you have the following:

### Required Software

| Component | Version | Purpose |
|-----------|---------|---------|
| Ansible | ${{ values.ansible_version }}+ | Core automation engine |
| Python | 3.8+ | Ansible runtime environment |
| OpenSSH | 7.0+ | Secure remote access |

### Installation Commands

**On macOS (using Homebrew):**
```bash
brew install ansible python@3.11
```

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y ansible python3 python3-pip sshpass
```

**On RHEL/CentOS:**
```bash
sudo dnf install -y ansible python3 python3-pip openssh-clients
```

**Using pip (cross-platform):**
```bash
pip3 install ansible>=${{ values.ansible_version }}
```

### Target System Requirements

- **SSH Access** - Key-based authentication configured
- **Python** - 3.6+ installed on target hosts (required for Ansible)
- **Sudo Privileges** - User must have passwordless sudo or provide credentials
- **Network Access** - Port 22 (SSH) accessible from control node
- **Operating System Support** - Primary target: ${{ values.target_os }}

### SSH Key Configuration

```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t rsa -b 4096 -C "ansible@yourdomain.com"

# Copy key to target hosts
ssh-copy-id user@target-server

# Test SSH connection
ssh user@target-server "echo 'SSH works!'"

# Verify sudo access
ssh user@target-server "sudo echo 'Sudo works!'"
```

## Configuration Options

The template supports the following parameters during project creation:

| Parameter | Description | Type | Default | Required |
|-----------|-------------|------|---------|----------|
| `name` | Unique name of the playbook project | string | - | Yes |
| `description` | Brief description of the playbook's purpose | string | - | Yes |
| `owner` | Team or individual responsible for automation | string | - | Yes |
| `target_os` | Primary operating system for targets | enum | linux | No |
| `ansible_version` | Minimum Ansible version requirement | enum | 2.9 | No |
| `collections` | Required Ansible collections | array | `[community.general, ansible.posix]` | No |
| `galaxy_requirements` | Include requirements.yml for Galaxy | boolean | true | No |
| `molecule_testing` | Include Molecule testing framework | boolean | true | No |

### Parameter Details

**`name`** (required)
- Lowercase letters, numbers, and hyphens only
- Used as project directory name
- Example: `webserver-deployment`, `database-automation`

**`description`** (required)
- Clear purpose description
- Displayed in playbook headers
- Helps with documentation and maintenance

**`target_os`** (optional)
- Determines default task conditions
- Options: `linux` (default), `windows`, `macos`, `any`
- Influences module selection and package managers

**`collections`** (optional)
- List of Ansible collections to include
- Default includes commonly used collections
- Additional collections can be added during project setup

## Getting Started

### Step 1: Create Repository from Template

1. Navigate to the Backstage portal
2. Select **"Create New Component"**
3. Choose **"Ansible Playbook"** template
4. Fill in required parameters (name, description, owner)
5. Configure optional settings as needed
6. Click **"Create"** and wait for completion
7. Clone the generated repository:

```bash
git clone <repository-url>
cd <repository-name>
```

### Step 2: Install Dependencies

Install Ansible collections and dependencies:

```bash
# Install collections from Ansible Galaxy (if requirements.yml included)
ansible-galaxy install -r requirements.yml

# Install base collections
ansible-galaxy collection install community.general ansible.posix

# Verify installation
ansible --version
ansible-galaxy collection list
```

### Step 3: Configure Inventory

Update the inventory files with your target hosts:

```bash
# Edit development inventory
nano inventories/development/hosts.ini

# Edit production inventory  
nano inventories/production/hosts.ini
```

Example inventory configuration:
```ini
[webservers]
web01.example.com ansible_host=10.0.1.101
web02.example.com ansible_host=10.0.1.102

[database]
db01.example.com ansible_host=10.0.2.201

[monitoring]
monitor01.example.com ansible_host=10.0.3.301

[all:vars]
ansible_user=deploy
ansible_ssh_private_key_file=~/.ssh/id_deploy_key
```

### Step 4: Set Variables

Configure environment-specific variables:

```bash
# Development variables
nano inventories/development/group_vars/all.yml

# Production variables
nano inventories/production/group_vars/all.yml
```

### Step 5: Customize Playbooks

Edit main playbooks to match your needs:

```bash
# Review site.yml playbook
nano playbooks/site.yml

# Customize web server configuration
nano playbooks/webservers.yml
```

### Step 6: Test Configuration

Run Ansible in check mode to validate setup:

```bash
# Syntax check only
ansible-playbook --syntax-check playbooks/site.yml

# Check mode (dry run)
ansible-playbook --check playbooks/site.yml

# Check specific inventory
ansible-playbook --check -i inventories/development playbooks/site.yml
```

### Step 7: Execute Playbook

Run the playbook in normal mode:

```bash
# Execute against development
ansible-playbook -i inventories/development playbooks/site.yml

# Execute against production (be careful!)
ansible-playbook -i inventories/production playbooks/site.yml

# Execute with verbosity for debugging
ansible-playbook -i inventories/development playbooks/site.yml -vvv
```

## Project Structure

### Inventories Directory

**Location:** `inventories/`

Contains environment-specific inventory files and variables:

```
inventories/
├── production/
│   ├── hosts.ini           # Production host definitions
│   ├── group_vars/
│   │   ├── all.yml        # Global production variables
│   │   └── web.yml        # Web server variables
│   └── host_vars/
│       └── db01.yml       # Host-specific variables
├── staging/
│   └── hosts.ini          # Staging inventory
└── development/
    └── hosts.ini          # Development inventory
```

**Example hosts.ini:**
```ini
[webservers]
web01.dev.example.com ansible_host=192.168.1.101
web02.dev.example.com ansible_host=192.168.1.102

[database]
db01.dev.example.com ansible_host=192.168.1.201

[monitoring:children]
webservers
database

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
```

### Playbooks Directory

**Location:** `playbooks/`

Contains automation playbooks organized by function:

```
playbooks/
├── site.yml              # Master playbook (includes all others)
├── webservers.yml        # Web server configuration
├── databases.yml         # Database server setup
├── monitoring.yml        # Monitoring and logging
└── utility/
    ├── backup.yml       # Backup automation
    └── patch.yml        # Security patching
```

**Example playbook (webservers.yml):**
```yaml
---
- name: Configure Web Servers
  hosts: webservers
  become: true
  
  vars:
    nginx_version: "1.24.0"
    
  roles:
    - common
    - nginx
    - php
    - webapp
    
  tasks:
    - name: Configure nginx firewall
      firewalld:
        service: http
        state: enabled
        permanent: true
        immediate: true
      notify: restart firewalld
      
  handlers:
    - name: restart firewalld
      service:
        name: firewalld
        state: restarted
```

### Roles Directory

**Location:** `roles/`

Contains reusable automation components:

```
roles/
├── common/              # Common system configuration
│   ├── tasks/
│   │   └── main.yml
│   ├── handlers/
│   │   └── main.yml
│   ├── templates/
│   │   └── motd.j2
│   └── vars/
│       └── main.yml
├── webapp/             # Web application deployment
│   ├── tasks/
│   │   └── main.yml
│   ├── files/
│   │   └── app.tar.gz
│   ├── templates/
│   │   └── config.yml.j2
│   └── defaults/
│       └── main.yml
└── database/           # Database management
    └── tasks/
        └── main.yml
```

### Configuration Files

**ansible.cfg** - Main Ansible configuration:
```ini
[defaults]
inventory = inventories/production/hosts.ini
remote_user = ansible
private_key_file = ~/.ssh/ansible_key
host_key_checking = False
forks = 50
gathering = smart
stdout_callback = yaml
```

**requirements.yml** - Ansible Galaxy dependencies:
```yaml
---
collections:
  - community.general
  - community.crypto
  - ansible.posix

roles:
  - name: nginxinc.nginx
    version: 0.24.2
  - name: geerlingguy.pip
    version: 2.2.0
```

## Role Development

### Creating a New Role

Use `ansible-galaxy` to scaffold new roles:

```bash
# Create a new role in the roles directory
cd roles/
ansible-galaxy init webapp

# Or create with specific structure
ansible-galaxy init --role-skeleton=templates/my_ansible_role webapp
```

### Role Directory Structure

```
roles/webapp/
├── tasks/              # Main tasks to execute
│   ├── main.yml       # Primary task list
│   ├── install.yml    # Installation tasks
│   └── configure.yml  # Configuration tasks
├── handlers/           # Event handlers
│   └── main.yml
├── templates/          # Jinja2 templates
│   └── config.j2
├── files/             # Static files to copy
│   └── binary.tar.gz
├── vars/              # Role variables
│   └── main.yml
├── defaults/          # Default variables (lowest priority)
│   └── main.yml
├── meta/              # Role metadata
│   └── main.yml
└── tests/             # Role tests
    └── test.yml
```

### Role Task Example

**tasks/main.yml:**
```yaml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family | lower }}.yml"

- name: Include installation tasks
  import_tasks: install.yml

- name: Include configuration tasks
  import_tasks: configure.yml
```

**tasks/install.yml:**
```yaml
---
- name: Install required packages
  package:
    name: "{{ item }}"
    state: present
  loop: "{{ webapp_packages }}"
  notify: restart webapp
```

**tasks/configure.yml:**
```yaml
---
- name: Create application directory
  file:
    path: "{{ webapp_dir }}"
    state: directory
    owner: "{{ webapp_user }}"
    group: "{{ webapp_group }}"
    mode: '0755'

- name: Deploy application configuration
  template:
    src: config.yml.j2
    dest: "{{ webapp_config_path }}"
    owner: "{{ webapp_user }}"
    group: "{{ webapp_group }}"
    mode: '0640'
  notify: restart webapp
```

**handlers/main.yml:**
```yaml
---
- name: restart webapp
  systemd:
    name: "{{ webapp_service_name }}"
    state: restarted
    enabled: true
```

**defaults/main.yml:**
```yaml
---
webapp_name: "myapp"
webapp_version: "1.0.0"
webapp_dir: "/opt/{{ webapp_name }}"
webapp_user: "{{ webapp_name }}"
webapp_group: "{{ webapp_name }}"
webapp_config_path: "{{ webapp_dir }}/config.yml"
webapp_packages:
  - python3
  - python3-pip
  - nginx
```

### Using Roles in Playbooks

**Method 1: Local roles**
```yaml
---
- name: Deploy web application
  hosts: webservers
  become: true
  
  roles:
    - common
    - database
    - webapp
```

**Method 2: With parameters**
```yaml
---
- name: Deploy web application
  hosts: webservers
  become: true
  
  roles:
    - role: webapp
      vars:
        webapp_version: "2.1.0"
        webapp_port: 8080
```

**Method 3: Dependencies**
```yaml
# In meta/main.yml
---
dependencies:
  - role: geerlingguy.java
    version: 2.0.1
    when: install_java | default(false)
```

## Inventory Management

### Static Inventory

Static inventory files define hosts in INI or YAML format:

**INI Format:**
```ini
[webservers]
web01.example.com ansible_host=10.0.1.101
web02.example.com ansible_host=10.0.1.102

[databases]
db01.example.com ansible_host=10.0.2.201

[monitoring:children]
webservers
database

[all:vars]
ansible_user=deploy
ansible_ssh_private_key_file=~/.ssh/id_deploy_key
ansible_python_interpreter=/usr/bin/python3
```

**YAML Format:**
```yaml
---
all:
  children:
    webservers:
      hosts:
        web01.example.com:
          ansible_host: 10.0.1.101
          ansible_user: deploy
        web02.example.com:
          ansible_host: 10.0.1.102
          ansible_user: deploy
    databases:
      hosts:
        db01.example.com:
          ansible_host: 10.0.2.201
          ansible_user: deploy
```

### Dynamic Inventory

Dynamic inventories fetch hosts from external sources:

**AWS EC2 Dynamic Inventory:**
```bash
# Install AWS inventory plugin
pip3 install ansible[aws]

# Configure in ansible.cfg
[inventory]
enable_plugins = aws_ec2

# Example: Tag-based inventory
ansible-inventory --list -i aws_ec2.yaml
```

**aws_ec2.yaml:**
```yaml
---
plugin: aws_ec2
regions:
  - us-east-1
  - us-west-2
filters:
  tag:Environment:
    - production
  instance-state-name:
    - running
keyed_groups:
  - prefix: tag
    key: tags
compose:
  ansible_host: public_ip_address
```

**VMware vSphere Dynamic Inventory:**
```yaml
---
plugin: vmware.vmware_rest.vcenter_vm_info
hostnames:
  - name
properties:
  - name
  - guest.ipAddress
filters:
  - runtime.powerState == "poweredOn"
```

### Group Variables

Configure group-specific variables:

**group_vars/webservers.yml:**
```yaml
---
apache_version: "2.4"
apache_port: 80
apache_ssl_port: 443
apache_document_root: /var/www/html

# Firewall rules
firewall_services:
  - http
  - https
```

**group_vars/databases.yml:**
```yaml
---
postgres_version: "15"
postgres_port: 5432
postgres_data_dir: /var/lib/postgresql/data

# Performance tuning
postgres_max_connections: 100
postgres_shared_buffers: "256MB"
```

### Host Variables

Configure host-specific overrides:

**host_vars/web01.yml:**
```yaml
---
apache_vhost_name: "app1.example.com"
apache_custom_config: true
```

### Inventory Best Practices

1. **Use group variables** for common configurations
2. **Separate environments** (dev/staging/prod) in different inventory files
3. **Use dynamic inventory** for cloud environments
4. **Document hosts** with `ansible_host` for clarity
5. **Define common variables** at the `all` group level
6. **Use hierarchy** to minimize duplication

## Testing

### Molecule Testing Framework

Molecule provides role testing in isolated containers:

**Installation:**
```bash
# Install molecule and docker driver
pip3 install molecule molecule-docker ansible-lint yamllint

# Initialize molecule in role
cd roles/webapp
molecule init scenario --driver-name docker
```

**molecule/default/molecule.yml:**
```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    command: ${MOLECULE_DOCKER_COMMAND:-""}
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    privileged: true
provisioner:
  name: ansible
  config_options:
    defaults:
      become: true
  playbooks:
    converge: ${MOLECULE_PLAYBOOK:-converge.yml}
verifier:
  name: ansible
lint: |
  set -e
  yamllint .
  ansible-lint .
```

**molecule/default/converge.yml:**
```yaml
---
- name: Converge
  hosts: all
  collections: ${{ values.collections | join(', ') }}
  tasks:
    - name: "Include webapp role"
      include_role:
        name: "webapp"
```

**molecule/default/verify.yml:**
```yaml
---
- name: Verify
  hosts: all
  gather_facts: false
  tasks:
    - name: Check if application is present
      stat:
        path: "/opt/webapp"
      register: app_stat
      
    - name: Verify application status
      assert:
        that:
          - app_stat.stat.exists
        fail_msg: "Application directory not found"
        success_msg: "Application directory exists"
```

**Running Molecule Tests:**
```bash
# Test all steps
cd roles/webapp
molecule test

# Manual workflow
cd roles/webapp
molecule create        # Create containers
molecule converge      # Run playbook
molecule verify        # Run tests
molecule destroy       # Clean up

# Run specific scenario
molecule test --scenario-name docker
```

### Linting and Syntax Checking

**Syntax Check:**
```bash
# Check playbook syntax
ansible-playbook --syntax-check playbooks/site.yml

# Check role syntax
ansible-playbook --syntax-check roles/webapp/tasks/main.yml
```

**Ansible Lint:**
```bash
# Install ansible-lint
pip3 install ansible-lint

# Lint playbooks
ansible-lint playbooks/*.yml

# Lint roles
ansible-lint roles/webapp/

# Auto-fix issues where possible
ansible-lint --fix playbooks/site.yml
```

**YAML Lint:**
```bash
# Install yamllint
pip3 install yamllint

# Lint all YAML files
yamllint .

# Lint specific files
yamllint playbooks/ roles/ *.yml

# Use custom configuration
yamllint -c .yamllint.yml playbooks/
```

### Test Recommendations

1. **Always test in staging** before production deployment
2. **Use Molecule** for role development and testing
3. **Integrate linting** in CI/CD pipelines
4. **Test idempotency** - run playbooks twice, verify no changes
5. **Use tags** to test specific parts of your automation
6. **Document test procedures** for team knowledge sharing

## CI/CD Integration

### GitHub Actions Workflow

The template includes pre-configured GitHub Actions for continuous integration:

**.github/workflows/ansible-lint.yml:**
```yaml
name: Ansible Lint

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ansible ansible-lint yamllint

      - name: Lint YAML files
        run: yamllint .

      - name: Lint Ansible playbooks and roles
        run: ansible-lint playbooks/ roles/

      - name: Check playbook syntax
        run: |
          for playbook in playbooks/*.yml; do
            ansible-playbook --syntax-check "$playbook"
          done
```

**.github/workflows/molecule-test.yml:**
```yaml
name: Molecule Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  molecule:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        role:
          - common
          - webapp
          - database

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install molecule molecule-docker ansible ansible-lint

      - name: Run Molecule tests
        run: |
          cd roles/${{ matrix.role }}
          molecule test
```

### Deployment Pipeline

**.github/workflows/deploy.yml:**
```yaml
name: Deploy to Staging

on:
  push:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install Ansible
        run: |
          python -m pip install --upgrade pip
          pip install ansible
          ansible-galaxy install -r requirements.yml

      - name: Run playbook (check mode)
        run: |
          ansible-playbook -i inventories/staging \
                          --check \
                          playbooks/site.yml

      - name: Run playbook (actual deployment)
        if: github.ref == 'refs/heads/main'
        run: |
          ansible-playbook -i inventories/staging \
                          playbooks/site.yml
```

### Pre-commit Hooks

**Installation:**
```bash
# Install pre-commit
pip3 install pre-commit

# Set up hooks
pre-commit install
```

**.pre-commit-config.yaml:**
```yaml
repos:
  - repo: https://github.com/ansible-community/ansible-lint
    rev: v6.20.0
    hooks:
      - id: ansible-lint
        files: \\\.(yaml|yml)$

  - repo: https://github.com/adrienverge/yamllint
    rev: v1.32.0
    hooks:
      - id: yamllint

  - repo: https://github.com/ambv/black
    rev: 23.9.1
    hooks:
      - id: black
        language_version: python3.11
```

## Best Practices

### Ansible Coding Standards

1. **Naming Conventions:**
   - Use lowercase with underscores for variables: `app_name`, `db_port`
   - Use descriptive names for tasks: "Install nginx package"
   - Prefix role variables with role name: `webapp_port`

2. **Formatting:**
   - Use 2 spaces for indentation (not tabs)
   - Put spaces around operators: `var: "{{ value }}"`
   - Use meaningful names and comments

3. **Task Design:**
   - **Always use names:** Every task must have a descriptive name
   - **Idempotent tasks:** Ensure tasks can be run multiple times safely
   - **Error handling:** Use `block`, `rescue`, `always` for error handling
   - **`register` and `when`** for conditional execution

**Example of proper task structure:**
```yaml
- name: Install Apache web server
  package:
    name: "{{ apache_package_name }}"
    state: present
  register: apache_install
  until: apache_install is success
  retries: 3
  delay: 5
  notify: restart apache
```

### Idempotency

Target: "apache2 state=present"
1. Check if package installed
2. If not, install

Always produce the same result without side effects.

### Idempotency Guidelines

**Good Examples:**
```yaml
# Idempotent - Ansible checks state before acting
- name: Ensure Apache is installed
  package:
    name: apache2
    state: present

# Idempotent - File checks content and permissions
- name: Configure Apache
  template:
    src: apache.conf.j2
    dest: /etc/apache2/apache.conf
    owner: root
    group: root
    mode: '0644'
```

**Avoid these patterns:**
```yaml
# BAD: Always executes command without checking state
- name: Start Apache (not idempotent)
  command: systemctl start apache2

# GOOD: Use Ansible service module
- name: Ensure Apache is started and enabled
  service:
    name: apache2
    state: started
    enabled: true
```

### Vault Usage for Secrets

**Create encrypted vault:**
```bash
# Create vault password file
echo "mypassword" > ~/.ansible/vault_password
chmod 600 ~/.ansible/vault_password

# Create encrypted variable file
ansible-vault create group_vars/all/vault.yml
# Editor opens, enter:
vault_mysql_password: "supersecret123"
vault_app_secret_key: "secretkey123"
```

**Use vault variables in playbooks:**
```yaml
- name: Configure MySQL database
  mysql_user:
    name: app_user
    password: "{{ vault_mysql_password }}"
    priv: "mydb.*:ALL"
    state: present
  no_log: true  # Hide output containing secrets
```

**Edit vault file:**
```bash
# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Rekey vault file (change password)
ansible-vault rekey group_vars/all/vault.yml

# View vault content
ansible-vault view group_vars/all/vault.yml
```

**Use vault password in playbook:**
```bash
ansible-playbook -i inventories/production playbooks/site.yml --vault-password-file ~/.ansible/vault_password
```

## Troubleshooting

### Common Issues and Solutions

**1. SSH Connection Failures**

```bash
# Issue: Host unreachable or SSH errors

# Solutions:
# a) Test SSH manually
ssh user@target-host

# b) Check inventory configuration
ansible -i inventories/development -m ping all

# c) Use ansible with increased verbosity
ansible-playbook -i inventories/development playbooks/site.yml -vvv

# d) Disable host key checking temporarily
export ANSIBLE_HOST_KEY_CHECKING=False
```

**2. Permission Denied Errors**

```bash
# Issue: Sudo/passwordless sudo problems

# Solutions:
# a) Test sudo access
sudo echo "Test sudo"  # Should not prompt for password

# b) Use become with password
ansible-playbook playbooks/site.yml --ask-become-pass

# c) Check sudoers file on target
visudo  # Ensure: ansible ALL=(ALL) NOPASSWD:ALL
```

**3. Module Not Found**

```bash
# Issue: Missing Ansible modules

# Solutions:
# a) Install required collections
ansible-galaxy collection install community.general

# b) Update Ansible
pip3 install --upgrade ansible

# c) Check module availability
ansible-doc -l | grep module_name
```

**4. Idempotency Issues**

```bash
# Issue: Tasks show "changed" on every run

# Solutions:
# a) Use proper modules instead of command/shell
# BAD:
- command: echo "hello" > /tmp/file.txt

# GOOD:
- copy:
    content: "hello"
    dest: /tmp/file.txt

# b) Use creates/removes parameters
- command: /usr/bin/setup.sh
  args:
    creates: /etc/app/installed

# c) Check state before executing
- stat:
    path: /etc/config.conf
  register: config_file
  
- command: configure-script
  when: not config_file.stat.exists
```

**5. Performance Issues**

```bash
# Issue: Playbook runs too slowly

# Solutions:
# a) Increase forks for parallel execution
# In ansible.cfg:
forks = 50  # Default is 5

# b) Enable pipelining
# In ansible.cfg:
[ssh_connection]
pipelining = True

# c) Use fact caching
# In ansible.cfg:
gathering = smart
fact_caching = memory
fact_caching_timeout = 86400

# d) Disable unnecessary facts
- hosts: all
  gather_facts: false  # Or limit with gather_subset
  gather_subset:
    - network
    - hardware
```

### Debug Mode and Verbosity

```bash
# Level 1 verbosity
ansible-playbook playbooks/site.yml -v

# Level 2 verbosity
ansible-playbook playbooks/site.yml -vv

# Level 3 verbosity (most detailed)
ansible-playbook playbooks/site.yml -vvv

# Include connection debug
ansible-playbook playbooks/site.yml -vvvv

# Enable debug strategy (pause on tasks)
ansible-playbook playbooks/site.yml --strategy debug

# Start at specific task
ansible-playbook playbooks/site.yml --start-at-task="Install packages"
```

### Testing Specific Tasks

```bash
# Run with specific tags
ansible-playbook playbooks/site.yml --tags configure

# Skip specific tags
ansible-playbook playbooks/site.yml --skip-tags debug

# List all tasks without executing
ansible-playbook playbooks/site.yml --list-tasks

# List all hosts
ansible-playbook playbooks/site.yml --list-hosts
```

### Useful Debugging Modules

```yaml
# Debug module for variable inspection
- name: Debug variable
  debug:
    var: ansible_hostname
    
# Debug with msg
- name: Show custom message
  debug:
    msg: "Installing version {{ app_version }} on {{ inventory_hostname }}"

# Assert module for validation
- name: Verify variable is set
  assert:
    that:
      - app_version is defined
      - app_version | length > 0
    fail_msg: "app_version must be defined and not empty"
    success_msg: "app_version is valid"

# Fail module for custom errors
- name: Check OS version
  fail:
    msg: "Unsupported OS version: {{ ansible_distribution_version }}"
  when: ansible_distribution_version < "7.0"
```

### Connection Debugging

```bash
# Test connectivity with ping module
ansible -i inventories/development all -m ping

# Test with specific user
ansible -i inventories/development all -m ping -u deploy

# Test with sudo
ansible -i inventories/development all -m ping --become

# Test raw SSH
ansible -i inventories/development all -m raw -a "uptime"
```

## Related Templates

- **[AWX Deployment](../awx-deployment)** - Deploy and manage AWX automation platform
- **[Ansible Nginx](../ansible-nginx)** - Specialized template for nginx web server automation
- **[Docker Application](../docker-application)** - Containerize applications orchestrated by Ansible
- **[Kubernetes Microservice](../kubernetes-microservice)** - Deploy microservices to Kubernetes clusters  
- **Test Playwright** - End-to-end testing for web applications (docs reference: ~350 lines)
- **Test k6 Load** - Performance testing infrastructure (docs reference: ~200 lines)

## Support and Resources

- **Ansible Documentation:** https://docs.ansible.com/
- **Ansible Galaxy:** https://galaxy.ansible.com/
- **Molecule Testing:** https://molecule.readthedocs.io/
- **Ansible Lint:** https://ansible-lint.readthedocs.io/
- **Community Forum:** https://forum.ansible.com/
- **GitHub Issues:** Report issues in your project repository

---

**Generated with {{ values.target_os }} support and Ansible {{ values.ansible_version }}+ compatibility**

**Owner:** {{ values.owner }} | **Template:** ansible-playbook | **Generated:** {% now 'local', '%Y-%m-%d' %}
