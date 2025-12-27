# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible role provides automated installation and configuration of Docker on target hosts. It supports multiple Linux distributions and includes comprehensive testing with Molecule.

**Key Features:**

- Docker CE (Community Edition) and Docker EE (Enterprise Edition) support
- Multiple Linux distributions (Ubuntu, Debian, CentOS, RHEL, Amazon Linux)
- Docker Compose plugin installation
- User management for Docker group membership
- Custom Docker daemon configuration via `daemon.json`
- Molecule-based testing with Docker driver
- CI/CD pipeline with linting, testing, and Ansible Galaxy publishing

```d2
direction: right

title: {
  label: Ansible Role Structure
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

role: ${{ values.name }} {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  defaults: defaults/ {
    shape: document
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "defaults/\nmain.yml"
  }

  tasks: tasks/ {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"

    main: main.yml
    install: install.yml
    configure: configure.yml
    compose: compose.yml
    users: users.yml
    debian: setup-debian.yml
    redhat: setup-redhat.yml
  }

  handlers: handlers/ {
    shape: hexagon
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "handlers/\nmain.yml"
  }

  molecule: molecule/ {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"

    converge: converge.yml
    verify: verify.yml
    config: molecule.yml
  }

  meta: meta/ {
    shape: document
    style.fill: "#E0F7FA"
    style.stroke: "#00838F"
    label: "meta/\nmain.yml"
  }

  defaults -> tasks.main: provides variables
  tasks.main -> handlers: triggers
  molecule -> tasks.main: tests
}

target: Target Hosts {
  style.fill: "#ECEFF1"
  style.stroke: "#546E7A"

  docker: Docker Engine {
    shape: hexagon
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"
  }

  compose: Docker Compose {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }
}

role.tasks -> target: configures
```

## Configuration Summary

| Setting                | Value                                 |
| ---------------------- | ------------------------------------- |
| Role Name              | `${{ values.name }}`                  |
| Owner                  | `${{ values.owner }}`                 |
| Docker Edition         | `${{ values.dockerEdition }}`         |
| Docker Compose Install | `${{ values.dockerComposeInstall }}`  |
| Repository             | `${{ values.destination.repo }}`      |

---

## Role Structure

This role follows Ansible best practices with a modular task structure:

| Directory/File | Purpose |
| -------------- | ------- |
| `defaults/main.yml` | Default variables with sensible defaults |
| `tasks/main.yml` | Main entry point, includes other task files |
| `tasks/setup-debian.yml` | Debian/Ubuntu-specific repository setup |
| `tasks/setup-redhat.yml` | RHEL/CentOS-specific repository setup |
| `tasks/install.yml` | Docker package installation |
| `tasks/configure.yml` | Docker daemon configuration |
| `tasks/compose.yml` | Docker Compose installation |
| `tasks/users.yml` | Docker group user management |
| `handlers/main.yml` | Service restart handlers |
| `meta/main.yml` | Role metadata and dependencies |
| `molecule/` | Molecule test scenarios |

### Task Flow

```d2
direction: down

start: Role Execution {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

vars: Include OS Variables {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

os_check: OS Family? {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
}

debian: setup-debian.yml {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Setup Debian/Ubuntu\nAPT Repository"
}

redhat: setup-redhat.yml {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Setup RHEL/CentOS\nYUM Repository"
}

install: install.yml {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Install Docker\nPackages"
}

configure: configure.yml {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Configure\ndaemon.json"
}

users: users.yml {
  style.fill: "#E0F7FA"
  style.stroke: "#00838F"
  label: "Add Users to\nDocker Group"
}

compose: compose.yml {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Install Docker\nCompose"
}

service: Start Service {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

start -> vars -> os_check
os_check -> debian: Debian
os_check -> redhat: RedHat
debian -> install
redhat -> install
install -> configure -> users -> compose -> service
```

---

## CI/CD Pipeline

This repository includes a GitHub Actions pipeline for continuous integration and delivery:

- **Linting**: YAML linting with yamllint, Ansible linting with ansible-lint
- **Testing**: Molecule tests across multiple distributions
- **Publishing**: Automatic release to Ansible Galaxy on main branch

### Pipeline Workflow

```d2
direction: right

push: Push/PR {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "yamllint\nansible-lint"
}

matrix: Matrix Test {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  ubuntu: Ubuntu 22.04
  debian: Debian 12
}

release: Release {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Ansible Galaxy\nPublish"
}

push -> lint -> matrix -> release

release: {
  style.stroke-dash: 3
}
```

### Pipeline Jobs

| Job | Trigger | Description |
| --- | ------- | ----------- |
| `lint` | All pushes and PRs | Runs yamllint and ansible-lint |
| `molecule` | After lint passes | Runs Molecule tests on Ubuntu 22.04 and Debian 12 |
| `release` | Push to main (after tests pass) | Publishes role to Ansible Galaxy |

---

## Prerequisites

### 1. Control Node Requirements

#### Python and Ansible

```bash
# Install Python 3.11+
python3 --version  # Should be 3.11 or higher

# Install Ansible
pip install ansible>=2.9

# Verify installation
ansible --version
```

#### Development Dependencies

```bash
# Install linting and testing tools
pip install yamllint ansible-lint molecule molecule-docker

# Verify Molecule installation
molecule --version
```

### 2. Docker (for Molecule Testing)

Molecule uses Docker to create test containers:

```bash
# Install Docker (macOS)
brew install --cask docker

# Install Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker

# Install Docker (RHEL/CentOS)
sudo yum install -y docker
sudo systemctl enable --now docker

# Verify Docker is running
docker ps
```

### 3. Target Host Requirements

| Requirement | Details |
| ----------- | ------- |
| OS | Ubuntu 20.04+, Debian 10+, CentOS 7+, RHEL 7+, Amazon Linux 2+ |
| Access | SSH access with sudo/root privileges |
| Python | Python 3.x installed on target hosts |
| Network | Internet access to download Docker packages |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# Install dependencies
pip install -r requirements.txt  # if exists
pip install molecule molecule-docker ansible-lint yamllint

# Run linting
yamllint .
ansible-lint

# Run Molecule tests
molecule test
```

### Installation from Ansible Galaxy

```bash
# Install from Ansible Galaxy
ansible-galaxy install ${{ values.destination.owner }}.${{ values.name }}

# Or add to requirements.yml
cat >> requirements.yml << EOF
roles:
  - name: ${{ values.destination.owner }}.${{ values.name }}
    version: main
EOF

ansible-galaxy install -r requirements.yml
```

### Running the Role

#### Basic Playbook

```yaml
---
- name: Install Docker
  hosts: docker_hosts
  become: true

  roles:
    - role: ${{ values.name }}
      vars:
        docker_edition: ${{ values.dockerEdition }}
        docker_compose_install: ${{ values.dockerComposeInstall }}
```

#### With Custom Configuration

```yaml
---
- name: Install Docker with custom configuration
  hosts: docker_hosts
  become: true

  roles:
    - role: ${{ values.name }}
      vars:
        docker_edition: ce
        docker_compose_install: true
        docker_users:
          - deploy
          - jenkins
          - "{{ ansible_user }}"
        docker_daemon_options:
          storage-driver: overlay2
          log-driver: json-file
          log-opts:
            max-size: '50m'
            max-file: '5'
          live-restore: true
        docker_insecure_registries:
          - 'registry.internal:5000'
```

#### Execute Playbook

```bash
# Run with inventory file
ansible-playbook -i inventory.ini playbook.yml

# Run with specific hosts
ansible-playbook -i "192.168.1.100," playbook.yml

# Run with SSH key
ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_rsa

# Dry run (check mode)
ansible-playbook -i inventory.ini playbook.yml --check

# Verbose output
ansible-playbook -i inventory.ini playbook.yml -vvv
```

---

## Variables

### Docker Installation Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_edition` | `ce` | Docker edition: `ce` (Community) or `ee` (Enterprise) |
| `docker_version` | `""` | Specific Docker version (empty for latest) |
| `docker_channel` | `stable` | Release channel: `stable`, `edge`, or `test` |
| `docker_package_state` | `present` | Package state: `present`, `latest`, or `absent` |

### Docker Compose Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_compose_install` | `true` | Whether to install Docker Compose plugin |
| `docker_compose_version` | `""` | Specific Compose version (empty for latest) |

### User Management Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_users` | `[]` | List of users to add to the docker group |

### Service Configuration Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_service_enabled` | `true` | Enable Docker service on boot |
| `docker_service_state` | `started` | Docker service state |
| `docker_restart_handler_state` | `restarted` | Handler state on config change |

### Daemon Configuration Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_daemon_options` | `{}` | Custom daemon.json options |
| `docker_storage_driver` | `""` | Storage driver (overlay2, devicemapper) |
| `docker_data_root` | `""` | Custom Docker data directory |
| `docker_log_driver` | `json-file` | Default logging driver |
| `docker_log_options` | `{}` | Logging driver options |

### Network Configuration Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `docker_dns` | `[]` | Custom DNS servers |
| `docker_dns_search` | `[]` | DNS search domains |
| `docker_insecure_registries` | `[]` | List of insecure registries |
| `docker_registry_mirrors` | `[]` | Registry mirror URLs |

See [Variables](variables.md) for complete documentation and examples.

---

## Molecule Testing

This role includes comprehensive Molecule tests using the Docker driver.

### Test Platforms

| Platform | Image | Purpose |
| -------- | ----- | ------- |
| Ubuntu 22.04 | `ubuntu:22.04` | Primary Debian-based testing |
| Debian 12 | `debian:12` | Additional Debian-based testing |

### Test Sequence

The default Molecule scenario runs the following sequence:

1. **dependency** - Install Galaxy dependencies
2. **lint** - Run yamllint and ansible-lint
3. **cleanup** - Clean up previous test artifacts
4. **destroy** - Destroy previous test instances
5. **syntax** - Check playbook syntax
6. **create** - Create test containers
7. **prepare** - Prepare containers (if prepare.yml exists)
8. **converge** - Run the role
9. **idempotence** - Verify role is idempotent
10. **verify** - Run verification tests
11. **cleanup** - Clean up test artifacts
12. **destroy** - Destroy test containers

### Running Tests

```bash
# Full test sequence
molecule test

# Create instances and converge only (for development)
molecule converge

# Run verification tests on existing instances
molecule verify

# Login to a running instance
molecule login --host ubuntu-22.04

# Destroy test instances
molecule destroy

# Run with specific distro
MOLECULE_DISTRO=debian12 molecule test
```

### Verification Tests

The verify playbook validates:

| Check | Description |
| ----- | ----------- |
| Docker installed | Verifies `docker --version` returns successfully |
| Docker service running | Confirms Docker service is in started state |
| Docker Compose installed | Checks `docker compose version` if installed |
| User group membership | Verifies test user is in docker group |
| Container execution | Runs hello-world container to validate functionality |

---

## Supported Platforms

| Platform | Versions | Status |
| -------- | -------- | ------ |
| Ubuntu | 20.04, 22.04, 24.04 | Fully Supported |
| Debian | 10, 11, 12 | Fully Supported |
| CentOS | 7, 8, 9 | Fully Supported |
| RHEL | 7, 8, 9 | Fully Supported |
| Amazon Linux | 2, 2023 | Fully Supported |
| Fedora | 38, 39 | Community Tested |

---

## Troubleshooting

### Installation Issues

**Error: Unable to find Docker package**

```
TASK [install : Install Docker packages] ***************************************
fatal: [host]: FAILED! => {"msg": "No package matching 'docker-ce' found"}
```

**Resolution:**

1. Verify the target OS is supported
2. Check repository setup completed successfully
3. Ensure the host has internet access to Docker repositories

```bash
# Debug: Check if repository was added (Debian/Ubuntu)
ansible target -m shell -a "cat /etc/apt/sources.list.d/docker.list"

# Debug: Check if repository was added (RHEL/CentOS)
ansible target -m shell -a "yum repolist | grep docker"
```

### Permission Issues

**Error: Permission denied while connecting to Docker daemon**

```
Got permission denied while trying to connect to the Docker daemon socket
```

**Resolution:**

1. Ensure the user is in the docker group:
   ```yaml
   docker_users:
     - "{{ ansible_user }}"
   ```
2. Log out and log back in for group changes to take effect
3. Or run: `newgrp docker`

### Service Issues

**Error: Docker service failed to start**

```
TASK [Ensure Docker service is in desired state] ******************************
fatal: [host]: FAILED! => {"msg": "Unable to start service docker"}
```

**Resolution:**

1. Check system logs:
   ```bash
   ansible target -m shell -a "journalctl -xeu docker.service"
   ```
2. Verify daemon.json is valid JSON:
   ```bash
   ansible target -m shell -a "cat /etc/docker/daemon.json | python3 -m json.tool"
   ```
3. Check for conflicting container runtimes

### Molecule Test Failures

**Error: Container creation failed**

```
CRITICAL Failed to create a container
```

**Resolution:**

1. Ensure Docker is running on your local machine:
   ```bash
   docker ps
   ```
2. Check for port conflicts
3. Ensure sufficient disk space
4. Try cleaning up and rerunning:
   ```bash
   molecule destroy
   molecule test
   ```

**Error: Idempotence test failed**

```
CRITICAL Idempotence test failed because of the following tasks:
```

**Resolution:**

1. Review the task output to identify non-idempotent tasks
2. Ensure tasks use proper `changed_when` conditions
3. Check for external state changes (package updates, etc.)

### CI Pipeline Failures

**Error: ansible-lint violations**

**Resolution:**

1. Run ansible-lint locally:
   ```bash
   ansible-lint
   ```
2. Fix reported violations
3. Use `.ansible-lint` to configure rules if needed

**Error: yamllint violations**

**Resolution:**

1. Run yamllint locally:
   ```bash
   yamllint .
   ```
2. Fix formatting issues
3. Use `.yamllint` to configure rules if needed

---

## Related Templates

| Template | Description |
| -------- | ----------- |
| [ansible-nginx](/docs/default/template/ansible-nginx) | Ansible role for NGINX installation |
| [ansible-kubernetes](/docs/default/template/ansible-kubernetes) | Ansible role for Kubernetes setup |
| [ansible-postgresql](/docs/default/template/ansible-postgresql) | Ansible role for PostgreSQL |
| [docker-compose-app](/docs/default/template/docker-compose-app) | Docker Compose application template |
| [terraform-aws-ecs](/docs/default/template/terraform-aws-ecs) | Terraform AWS ECS cluster |

---

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Installation Guide](https://docs.docker.com/engine/install/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [ansible-lint Documentation](https://ansible-lint.readthedocs.io/)
- [yamllint Documentation](https://yamllint.readthedocs.io/)
- [Docker Daemon Configuration](https://docs.docker.com/engine/reference/commandline/dockerd/)

---

## License

MIT

## Author

${{ values.owner }}
