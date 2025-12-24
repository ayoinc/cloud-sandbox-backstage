# Ansible Docker Host Usage Guide

## Architecture Overview

```d2
direction: right

title: Ansible Docker Host Deployment Flow {
  shape: text
  near: top-center
  style.font-size: 24
}

control: Control Node {
  shape: rectangle
  style.fill: "#E3F2FD"
  
  ansible: Ansible {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }
  
  playbooks: Playbooks {
    shape: document
    style.fill: "#BBDEFB"
  }
  
  inventory: Inventory {
    shape: document
    style.fill: "#BBDEFB"
  }
}

targets: Target Hosts {
  shape: rectangle
  style.fill: "#C8E6C9"
  
  docker1: docker01 {
    shape: rectangle
    style.fill: "#81C784"
    
    engine: Docker Engine
    compose: Docker Compose
    containers: Containers
  }
  
  docker2: docker02 {
    shape: rectangle
    style.fill: "#81C784"
    
    engine: Docker Engine
    compose: Docker Compose
    containers: Containers
  }
  
  docker3: docker03 {
    shape: rectangle
    style.fill: "#81C784"
    
    engine: Docker Engine
    compose: Docker Compose
    containers: Containers
  }
}

swarm: Docker Swarm Cluster {
  shape: rectangle
  style.fill: "#E1BEE7"
  style.stroke-dash: 3
  
  manager: Manager Node
  workers: Worker Nodes
  overlay: Overlay Networks
}

control.ansible -> targets: SSH
targets.docker1 -> swarm: optional
targets.docker2 -> swarm: optional
targets.docker3 -> swarm: optional
```

## Installation

### Requirements File

```yaml
# requirements.yml
---
collections:
  - name: community.docker
    version: ">=3.4.0"
  - name: community.general
    version: ">=7.0.0"
  - name: ansible.posix
    version: ">=1.5.0"
```

```bash
# Install requirements
ansible-galaxy install -r requirements.yml --force
```

## Deployment Examples

### Basic Docker Installation

```yaml
# playbooks/docker.yml
---
- name: Install Docker on Linux Hosts
  hosts: docker_hosts
  become: yes
  
  vars:
    docker_users:
      - deploy
      - developer
    
    docker_daemon_config:
      storage-driver: overlay2
      log-driver: json-file
      log-opts:
        max-size: "100m"
        max-file: "5"
      live-restore: true
  
  roles:
    - common
    - docker
    - compose
```

```bash
# Execute deployment
ansible-playbook playbooks/docker.yml

# With specific inventory
ansible-playbook -i inventory/staging.ini playbooks/docker.yml

# Limit to specific hosts
ansible-playbook playbooks/docker.yml --limit docker01.example.com
```

### Production Docker Host Configuration

```yaml
# group_vars/docker_hosts.yml
---
# Docker Engine configuration
docker_version: "latest"
docker_data_root: "/data/docker"
docker_storage_driver: "overlay2"

docker_daemon_config:
  storage-driver: "overlay2"
  log-driver: "json-file"
  log-opts:
    max-size: "100m"
    max-file: "10"
    labels: "service,environment"
  live-restore: true
  userland-proxy: false
  no-new-privileges: true
  icc: false
  default-ulimits:
    nofile:
      Name: nofile
      Hard: 65536
      Soft: 65536
    nproc:
      Name: nproc
      Hard: 65536
      Soft: 65536
  default-address-pools:
    - base: "172.20.0.0/16"
      size: 24
    - base: "172.21.0.0/16"
      size: 24

# Registry configuration
docker_registry_mirrors:
  - "https://mirror.gcr.io"
  - "https://docker-mirror.example.com"

docker_insecure_registries:
  - "registry.internal.example.com:5000"

# Users with Docker access
docker_users:
  - deploy
  - jenkins
  - gitlab-runner

# Security settings
docker_content_trust: true
docker_audit_enabled: true
docker_cis_benchmark: true

# Cleanup configuration
docker_cleanup_enabled: true
docker_cleanup_schedule: "0 2 * * *"  # Daily at 2 AM
docker_cleanup_keep_images: 10

# Monitoring
docker_metrics_addr: "0.0.0.0:9323"
```

### Private Registry Configuration

```yaml
# playbooks/docker-with-registry.yml
---
- name: Configure Docker with Private Registry
  hosts: docker_hosts
  become: yes
  
  vars:
    docker_insecure_registries:
      - "registry.internal.example.com:5000"
    
    docker_registry_mirrors:
      - "https://registry.internal.example.com"
    
    # Registry authentication (stored in vault)
    docker_registry_auth:
      - registry: "registry.internal.example.com"
        username: "{{ vault_registry_username }}"
        password: "{{ vault_registry_password }}"
      - registry: "ghcr.io"
        username: "{{ vault_github_username }}"
        password: "{{ vault_github_token }}"
  
  tasks:
    - name: Include Docker role
      include_role:
        name: docker

    - name: Configure registry authentication
      community.docker.docker_login:
        registry_url: "{{ item.registry }}"
        username: "{{ item.username }}"
        password: "{{ item.password }}"
        reauthorize: yes
      loop: "{{ docker_registry_auth }}"
      no_log: true
```

### Docker Swarm Cluster Setup

```yaml
# playbooks/swarm-cluster.yml
---
- name: Initialize Docker Swarm Cluster
  hosts: swarm_managers[0]
  become: yes
  
  tasks:
    - name: Initialize Swarm
      community.docker.docker_swarm:
        state: present
        advertise_addr: "{{ ansible_default_ipv4.address }}"
      register: swarm_init

    - name: Get Swarm info
      community.docker.docker_swarm_info:
      register: swarm_info

    - name: Store join tokens
      set_fact:
        swarm_manager_token: "{{ swarm_info.swarm_facts.JoinTokens.Manager }}"
        swarm_worker_token: "{{ swarm_info.swarm_facts.JoinTokens.Worker }}"
        swarm_manager_addr: "{{ ansible_default_ipv4.address }}:2377"

- name: Join Manager Nodes
  hosts: swarm_managers:!swarm_managers[0]
  become: yes
  
  tasks:
    - name: Join Swarm as manager
      community.docker.docker_swarm:
        state: join
        advertise_addr: "{{ ansible_default_ipv4.address }}"
        join_token: "{{ hostvars[groups['swarm_managers'][0]]['swarm_manager_token'] }}"
        remote_addrs: ["{{ hostvars[groups['swarm_managers'][0]]['swarm_manager_addr'] }}"]

- name: Join Worker Nodes
  hosts: swarm_workers
  become: yes
  
  tasks:
    - name: Join Swarm as worker
      community.docker.docker_swarm:
        state: join
        advertise_addr: "{{ ansible_default_ipv4.address }}"
        join_token: "{{ hostvars[groups['swarm_managers'][0]]['swarm_worker_token'] }}"
        remote_addrs: ["{{ hostvars[groups['swarm_managers'][0]]['swarm_manager_addr'] }}"]

- name: Configure Swarm Networks and Labels
  hosts: swarm_managers[0]
  become: yes
  
  tasks:
    - name: Create overlay networks
      community.docker.docker_network:
        name: "{{ item.name }}"
        driver: overlay
        attachable: "{{ item.attachable | default(true) }}"
        scope: swarm
      loop:
        - { name: "traefik-public", attachable: true }
        - { name: "monitoring", attachable: true }
        - { name: "app-network", attachable: true }

    - name: Label nodes
      community.docker.docker_node:
        hostname: "{{ item.hostname }}"
        labels: "{{ item.labels }}"
      loop:
        - { hostname: "docker01", labels: { "role": "manager", "tier": "frontend" } }
        - { hostname: "docker02", labels: { "role": "worker", "tier": "backend" } }
        - { hostname: "docker03", labels: { "role": "worker", "tier": "database" } }
```

### Deploy Swarm Stack

```yaml
# playbooks/deploy-stack.yml
---
- name: Deploy Application Stack to Swarm
  hosts: swarm_managers[0]
  become: yes
  
  vars:
    stack_name: "myapp"
    stack_compose_file: "files/docker-compose.yml"
  
  tasks:
    - name: Copy compose file
      copy:
        src: "{{ stack_compose_file }}"
        dest: "/opt/stacks/{{ stack_name }}/docker-compose.yml"
        mode: '0644'

    - name: Deploy stack
      community.docker.docker_stack:
        state: present
        name: "{{ stack_name }}"
        compose:
          - "/opt/stacks/{{ stack_name }}/docker-compose.yml"
      register: stack_deploy

    - name: Wait for services to be running
      community.docker.docker_swarm_service_info:
        name: "{{ stack_name }}_{{ item }}"
      register: service_info
      until: service_info.exists and service_info.service.Spec.Mode.Replicated.Replicas == service_info.service.ServiceStatus.RunningTasks
      retries: 30
      delay: 10
      loop:
        - web
        - api
        - worker
```

## Docker Compose Application Deployment

### Deploy Compose Stack

```yaml
# playbooks/deploy-compose-app.yml
---
- name: Deploy Application with Docker Compose
  hosts: docker_hosts
  become: yes
  
  vars:
    app_name: "webapp"
    app_dir: "/opt/apps/{{ app_name }}"
    compose_files:
      - docker-compose.yml
      - docker-compose.prod.yml
  
  tasks:
    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        mode: '0755'

    - name: Copy compose files
      copy:
        src: "files/{{ item }}"
        dest: "{{ app_dir }}/{{ item }}"
        mode: '0644'
      loop: "{{ compose_files }}"

    - name: Copy environment file
      template:
        src: "templates/{{ app_name }}.env.j2"
        dest: "{{ app_dir }}/.env"
        mode: '0600'

    - name: Pull latest images
      community.docker.docker_compose_v2:
        project_src: "{{ app_dir }}"
        files: "{{ compose_files }}"
        pull: always
        state: present
      register: pull_result

    - name: Deploy application
      community.docker.docker_compose_v2:
        project_src: "{{ app_dir }}"
        files: "{{ compose_files }}"
        state: present
        remove_orphans: yes
      register: deploy_result

    - name: Display deployment status
      debug:
        msg: |
          Deployment completed:
          - Services started: {{ deploy_result.containers | map(attribute='Name') | list }}
          - Images pulled: {{ pull_result.images | default([]) | length }}
```

### Rolling Update with Compose

```yaml
# playbooks/rolling-update.yml
---
- name: Rolling Update Docker Compose Application
  hosts: docker_hosts
  become: yes
  serial: 1  # One host at a time
  
  vars:
    app_dir: "/opt/apps/webapp"
    health_check_url: "http://localhost:8080/health"
  
  pre_tasks:
    - name: Remove from load balancer
      uri:
        url: "{{ lb_api }}/remove/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost
      when: lb_api is defined

    - name: Wait for connections to drain
      pause:
        seconds: 30

  tasks:
    - name: Pull new images
      community.docker.docker_compose_v2:
        project_src: "{{ app_dir }}"
        pull: always
        state: present

    - name: Update containers
      community.docker.docker_compose_v2:
        project_src: "{{ app_dir }}"
        state: present
        recreate: always
      register: update_result

    - name: Wait for health check
      uri:
        url: "{{ health_check_url }}"
        status_code: 200
      register: health
      until: health.status == 200
      retries: 30
      delay: 5

  post_tasks:
    - name: Add back to load balancer
      uri:
        url: "{{ lb_api }}/add/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost
      when: lb_api is defined
```

## Container Management

### Container Lifecycle Management

```yaml
# playbooks/manage-containers.yml
---
- name: Manage Docker Containers
  hosts: docker_hosts
  become: yes
  
  vars:
    containers:
      - name: nginx-proxy
        image: nginx:1.25-alpine
        state: started
        restart_policy: unless-stopped
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - "/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro"
          - "/etc/nginx/ssl:/etc/nginx/ssl:ro"
        env:
          TZ: "UTC"
        labels:
          app: proxy
          tier: frontend
      
      - name: redis-cache
        image: redis:7-alpine
        state: started
        restart_policy: unless-stopped
        ports:
          - "6379:6379"
        volumes:
          - "redis-data:/data"
        command: "redis-server --appendonly yes"
        memory: "512m"
        cpus: 1
  
  tasks:
    - name: Create Docker volumes
      community.docker.docker_volume:
        name: "{{ item }}"
        state: present
      loop:
        - redis-data
        - nginx-logs

    - name: Manage containers
      community.docker.docker_container:
        name: "{{ item.name }}"
        image: "{{ item.image }}"
        state: "{{ item.state | default('started') }}"
        restart_policy: "{{ item.restart_policy | default('unless-stopped') }}"
        ports: "{{ item.ports | default(omit) }}"
        volumes: "{{ item.volumes | default(omit) }}"
        env: "{{ item.env | default(omit) }}"
        labels: "{{ item.labels | default(omit) }}"
        command: "{{ item.command | default(omit) }}"
        memory: "{{ item.memory | default(omit) }}"
        cpus: "{{ item.cpus | default(omit) }}"
        pull: yes
        comparisons:
          image: strict
      loop: "{{ containers }}"
```

### Container Cleanup

```yaml
# playbooks/cleanup.yml
---
- name: Docker System Cleanup
  hosts: docker_hosts
  become: yes
  
  vars:
    cleanup_unused_images: true
    cleanup_stopped_containers: true
    cleanup_unused_volumes: true
    cleanup_unused_networks: true
    cleanup_build_cache: true
    keep_images_count: 5

  tasks:
    - name: Get Docker disk usage before cleanup
      command: docker system df
      register: df_before
      changed_when: false

    - name: Display current usage
      debug:
        msg: "{{ df_before.stdout_lines }}"

    - name: Remove stopped containers
      when: cleanup_stopped_containers
      community.docker.docker_prune:
        containers: yes
        containers_filters:
          status: exited

    - name: Remove unused images
      when: cleanup_unused_images
      community.docker.docker_prune:
        images: yes
        images_filters:
          dangling: false

    - name: Remove unused volumes
      when: cleanup_unused_volumes
      community.docker.docker_prune:
        volumes: yes

    - name: Remove unused networks
      when: cleanup_unused_networks
      community.docker.docker_prune:
        networks: yes

    - name: Remove build cache
      when: cleanup_build_cache
      community.docker.docker_prune:
        builder_cache: yes

    - name: Get Docker disk usage after cleanup
      command: docker system df
      register: df_after
      changed_when: false

    - name: Display usage after cleanup
      debug:
        msg: "{{ df_after.stdout_lines }}"
```

## Docker Upgrade

### Upgrade Docker Engine

```yaml
# playbooks/upgrade-docker.yml
---
- name: Upgrade Docker Engine
  hosts: docker_hosts
  become: yes
  serial: 1  # One host at a time for safety
  
  vars:
    docker_target_version: "5:25.0.0-1~ubuntu.22.04~jammy"
    backup_containers: true

  pre_tasks:
    - name: Get current Docker version
      command: docker version --format '{{ '{{' }}.Server.Version{{ '}}' }}'
      register: current_version
      changed_when: false

    - name: Display current version
      debug:
        msg: "Current Docker version: {{ current_version.stdout }}"

    - name: List running containers
      command: docker ps --format '{{ '{{' }}.Names{{ '}}' }}'
      register: running_containers
      changed_when: false

    - name: Stop running containers gracefully
      when: backup_containers and running_containers.stdout_lines | length > 0
      command: docker stop {{ running_containers.stdout_lines | join(' ') }}
      register: stopped_containers

  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
      when: ansible_os_family == 'Debian'

    - name: Upgrade Docker packages
      package:
        name:
          - "docker-ce={{ docker_target_version }}"
          - "docker-ce-cli={{ docker_target_version }}"
          - containerd.io
          - docker-buildx-plugin
          - docker-compose-plugin
        state: present
      notify: Restart docker

    - name: Verify Docker is running
      service:
        name: docker
        state: started
      register: docker_service

    - name: Get new Docker version
      command: docker version --format '{{ '{{' }}.Server.Version{{ '}}' }}'
      register: new_version
      changed_when: false

    - name: Display new version
      debug:
        msg: "Docker upgraded to: {{ new_version.stdout }}"

  post_tasks:
    - name: Start previously running containers
      when: backup_containers and stopped_containers is defined
      command: docker start {{ running_containers.stdout_lines | join(' ') }}

    - name: Verify all containers are running
      command: docker ps
      register: verify_containers
      changed_when: false

    - name: Display running containers
      debug:
        msg: "{{ verify_containers.stdout_lines }}"

  handlers:
    - name: Restart docker
      service:
        name: docker
        state: restarted
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Docker daemon won't start | Invalid daemon.json | Validate JSON syntax: `python3 -m json.tool /etc/docker/daemon.json` |
| Cannot connect to Docker | Socket permissions | Add user to docker group: `usermod -aG docker $USER` |
| Storage driver error | Unsupported filesystem | Use overlay2 on ext4/xfs, check `/var/lib/docker` filesystem |
| Network conflicts | IP range overlap | Modify `docker_bip` or `default-address-pools` |
| Container DNS issues | DNS not configured | Set `docker_dns` in daemon.json |
| Registry auth fails | Wrong credentials | Verify credentials, check `~/.docker/config.json` |
| Swarm join fails | Firewall blocking | Open ports 2377, 7946, 4789 |
| Live-restore not working | Version mismatch | Ensure all containers use compatible API version |

### Debug Commands

```bash
# Check Docker daemon status
ansible docker_hosts -m shell -a "systemctl status docker"

# View Docker logs
ansible docker_hosts -m shell -a "journalctl -u docker -n 100 --no-pager"

# Verify daemon.json
ansible docker_hosts -m shell -a "cat /etc/docker/daemon.json | python3 -m json.tool"

# Check Docker info
ansible docker_hosts -m shell -a "docker info"

# Test registry connectivity
ansible docker_hosts -m shell -a "docker pull hello-world"

# Check Swarm status
ansible swarm_managers -m shell -a "docker node ls"

# View container logs
ansible docker_hosts -m shell -a "docker logs --tail 100 container_name"
```

## Best Practices

### Security

1. **Never expose Docker socket** - Use TLS for remote API access
2. **Enable Content Trust** - Verify image signatures
3. **Use user namespace remapping** - Isolate container root
4. **Disable ICC** - Prevent container-to-container communication
5. **Enable audit logging** - Track Docker operations
6. **Regular updates** - Keep Docker and base images updated

### Performance

1. **Use overlay2** - Recommended storage driver
2. **Separate data partition** - Isolate Docker storage
3. **Configure log rotation** - Prevent disk exhaustion
4. **Set resource limits** - Use cgroups for containers
5. **Enable live-restore** - Minimize restart impact

### Operations

1. **Regular cleanup** - Schedule `docker system prune`
2. **Monitor disk usage** - Alert on Docker partition usage
3. **Backup volumes** - Implement volume backup strategy
4. **Test upgrades** - Stage upgrades in non-production first
5. **Document images** - Track image sources and versions

### CI/CD Integration

```yaml
# .github/workflows/ansible-docker.yml
name: Ansible Docker CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ansible-lint
        uses: ansible/ansible-lint-action@v6

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install molecule molecule-docker ansible-lint
          ansible-galaxy install -r requirements.yml
      - name: Run Molecule tests
        run: molecule test
```
