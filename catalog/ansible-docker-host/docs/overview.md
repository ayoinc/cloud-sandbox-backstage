# Ansible Docker Host Overview

## Role Architecture

### Role Dependencies

```
site.yml
├── common (base system)
│   ├── Update packages
│   ├── Install prerequisites
│   ├── Configure firewall
│   ├── Set timezone/NTP
│   └── Configure sysctl
│
├── docker (Docker Engine)
│   ├── Add Docker repository
│   ├── Install Docker CE
│   ├── Configure daemon.json
│   ├── Configure storage driver
│   └── Start Docker service
│
├── compose (Docker Compose)
│   ├── Install Compose plugin
│   ├── Install standalone (optional)
│   └── Configure aliases
│
├── security (hardening)
│   ├── Docker daemon security
│   ├── User namespace remapping
│   ├── Content trust
│   └── Audit logging
│
└── swarm (optional)
    ├── Initialize Swarm
    ├── Join managers
    ├── Join workers
    └── Configure overlay network
```

## Docker Role

### Default Configuration

```yaml
# roles/docker/defaults/main.yml
---
# Docker version (latest or specific)
docker_version: "latest"  # or "5:24.0.7-1~ubuntu.22.04~jammy"
docker_edition: "ce"      # ce or ee

# Docker packages
docker_packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin

# Docker daemon configuration
docker_daemon_config:
  storage-driver: "overlay2"
  log-driver: "json-file"
  log-opts:
    max-size: "100m"
    max-file: "5"
  live-restore: true
  userland-proxy: false
  no-new-privileges: true
  
# Storage configuration
docker_storage_driver: "overlay2"
docker_data_root: "/var/lib/docker"

# Network configuration
docker_bip: "172.17.0.1/16"
docker_fixed_cidr: ""
docker_default_address_pools: []
docker_dns: []
docker_dns_search: []

# Registry configuration
docker_insecure_registries: []
docker_registry_mirrors: []

# Users to add to docker group
docker_users: []

# Enable Docker service
docker_service_enabled: true
docker_service_state: started

# Cleanup options
docker_cleanup_enabled: true
docker_cleanup_schedule: "0 3 * * 0"  # Weekly at 3 AM Sunday
```

### Daemon Configuration Template

```jinja2
# roles/docker/templates/daemon.json.j2
{
{% if docker_data_root != "/var/lib/docker" %}
  "data-root": "{{ docker_data_root }}",
{% endif %}
  "storage-driver": "{{ docker_storage_driver }}",
{% if docker_storage_opts | default([]) | length > 0 %}
  "storage-opts": {{ docker_storage_opts | to_json }},
{% endif %}
  "log-driver": "{{ docker_log_driver | default('json-file') }}",
  "log-opts": {
    "max-size": "{{ docker_log_max_size | default('100m') }}",
    "max-file": "{{ docker_log_max_file | default('5') }}"
{% if docker_log_driver == 'fluentd' %}
    ,"fluentd-address": "{{ docker_fluentd_address }}"
{% endif %}
  },
{% if docker_bip %}
  "bip": "{{ docker_bip }}",
{% endif %}
{% if docker_fixed_cidr %}
  "fixed-cidr": "{{ docker_fixed_cidr }}",
{% endif %}
{% if docker_default_address_pools | length > 0 %}
  "default-address-pools": {{ docker_default_address_pools | to_json }},
{% endif %}
{% if docker_dns | length > 0 %}
  "dns": {{ docker_dns | to_json }},
{% endif %}
{% if docker_dns_search | length > 0 %}
  "dns-search": {{ docker_dns_search | to_json }},
{% endif %}
{% if docker_insecure_registries | length > 0 %}
  "insecure-registries": {{ docker_insecure_registries | to_json }},
{% endif %}
{% if docker_registry_mirrors | length > 0 %}
  "registry-mirrors": {{ docker_registry_mirrors | to_json }},
{% endif %}
{% if docker_userns_remap %}
  "userns-remap": "{{ docker_userns_remap }}",
{% endif %}
{% if docker_default_runtime %}
  "default-runtime": "{{ docker_default_runtime }}",
{% endif %}
{% if docker_runtimes %}
  "runtimes": {{ docker_runtimes | to_json }},
{% endif %}
  "live-restore": {{ docker_live_restore | default(true) | lower }},
  "userland-proxy": {{ docker_userland_proxy | default(false) | lower }},
  "no-new-privileges": {{ docker_no_new_privileges | default(true) | lower }},
  "icc": {{ docker_icc | default(false) | lower }},
  "experimental": {{ docker_experimental | default(false) | lower }},
  "metrics-addr": "{{ docker_metrics_addr | default('') }}",
  "features": {
    "buildkit": true
  }
}
```

### Docker Installation Tasks

```yaml
# roles/docker/tasks/install.yml
---
- name: Install prerequisites
  package:
    name: "{{ docker_prerequisites[ansible_os_family] }}"
    state: present

- name: Add Docker GPG key (Debian)
  when: ansible_os_family == 'Debian'
  apt_key:
    url: https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg
    state: present

- name: Add Docker repository (Debian)
  when: ansible_os_family == 'Debian'
  apt_repository:
    repo: "deb [arch={{ docker_arch }}] https://download.docker.com/linux/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} stable"
    state: present
    filename: docker

- name: Add Docker repository (RedHat)
  when: ansible_os_family == 'RedHat'
  yum_repository:
    name: docker-ce-stable
    description: Docker CE Stable
    baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
    gpgkey: https://download.docker.com/linux/centos/gpg
    gpgcheck: yes

- name: Install Docker packages
  package:
    name: "{{ docker_packages }}"
    state: present
  notify: Restart docker

- name: Ensure Docker data directory exists
  file:
    path: "{{ docker_data_root }}"
    state: directory
    mode: '0711'
  when: docker_data_root != "/var/lib/docker"

- name: Configure Docker daemon
  template:
    src: daemon.json.j2
    dest: /etc/docker/daemon.json
    owner: root
    group: root
    mode: '0644'
    validate: 'python3 -m json.tool %s'
  notify: Restart docker

- name: Add users to docker group
  user:
    name: "{{ item }}"
    groups: docker
    append: yes
  loop: "{{ docker_users }}"
  when: docker_users | length > 0

- name: Ensure Docker service is started
  service:
    name: docker
    state: "{{ docker_service_state }}"
    enabled: "{{ docker_service_enabled }}"
```

## Docker Compose Role

### Compose Configuration

```yaml
# roles/compose/defaults/main.yml
---
# Compose plugin (Docker CLI plugin)
docker_compose_plugin: true
docker_compose_plugin_version: "latest"

# Standalone compose (optional)
docker_compose_standalone: false
docker_compose_standalone_version: "2.24.5"
docker_compose_standalone_path: "/usr/local/bin/docker-compose"

# Bash aliases
docker_compose_aliases:
  - alias: "dc"
    command: "docker compose"
  - alias: "dcu"
    command: "docker compose up -d"
  - alias: "dcd"
    command: "docker compose down"
  - alias: "dcl"
    command: "docker compose logs -f"
  - alias: "dcps"
    command: "docker compose ps"
```

### Compose Installation Tasks

```yaml
# roles/compose/tasks/main.yml
---
- name: Install Docker Compose plugin
  when: docker_compose_plugin
  package:
    name: docker-compose-plugin
    state: present

- name: Install standalone Docker Compose
  when: docker_compose_standalone
  block:
    - name: Download Docker Compose
      get_url:
        url: "https://github.com/docker/compose/releases/download/v{{ docker_compose_standalone_version }}/docker-compose-linux-{{ ansible_architecture }}"
        dest: "{{ docker_compose_standalone_path }}"
        mode: '0755'
        owner: root
        group: root

    - name: Verify Docker Compose installation
      command: "{{ docker_compose_standalone_path }} version"
      changed_when: false

- name: Configure bash aliases
  blockinfile:
    path: "/home/{{ item.0 }}/.bashrc"
    block: |
      {% for alias in docker_compose_aliases %}
      alias {{ alias.alias }}='{{ alias.command }}'
      {% endfor %}
    marker: "# {mark} ANSIBLE MANAGED - Docker aliases"
    create: yes
  loop: "{{ docker_users | product([docker_compose_aliases]) | list }}"
  loop_control:
    label: "{{ item.0 }}"
```

## Security Role

### Security Hardening Configuration

```yaml
# roles/security/defaults/main.yml
---
# CIS Docker Benchmark compliance
docker_cis_benchmark: true

# User namespace remapping
docker_userns_remap: ""  # "default" or specific user

# Content trust
docker_content_trust: true
docker_content_trust_server: ""

# Seccomp profile
docker_seccomp_profile: "default"

# AppArmor
docker_apparmor_enabled: true

# Audit logging
docker_audit_enabled: true
docker_audit_rules:
  - "-w /usr/bin/docker -k docker"
  - "-w /var/lib/docker -k docker"
  - "-w /etc/docker -k docker"
  - "-w /lib/systemd/system/docker.service -k docker"
  - "-w /lib/systemd/system/docker.socket -k docker"
  - "-w /etc/docker/daemon.json -k docker"

# TLS configuration for remote API
docker_tls_enabled: false
docker_tls_ca_cert: ""
docker_tls_server_cert: ""
docker_tls_server_key: ""
docker_tls_verify: true

# Resource limits
docker_default_ulimits:
  nofile:
    soft: 65536
    hard: 65536
  nproc:
    soft: 65536
    hard: 65536
```

### Security Hardening Tasks

```yaml
# roles/security/tasks/main.yml
---
- name: Configure sysctl for Docker security
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  loop:
    - { name: "net.ipv4.ip_forward", value: "1" }
    - { name: "net.bridge.bridge-nf-call-iptables", value: "1" }
    - { name: "net.bridge.bridge-nf-call-ip6tables", value: "1" }
    - { name: "kernel.pid_max", value: "4194304" }
    - { name: "vm.max_map_count", value: "262144" }

- name: Enable Docker Content Trust
  when: docker_content_trust
  lineinfile:
    path: /etc/environment
    regexp: '^DOCKER_CONTENT_TRUST='
    line: 'DOCKER_CONTENT_TRUST=1'
    create: yes

- name: Configure audit rules for Docker
  when: docker_audit_enabled
  template:
    src: docker-audit.rules.j2
    dest: /etc/audit/rules.d/docker.rules
    owner: root
    group: root
    mode: '0640'
  notify: Restart auditd

- name: Restrict Docker socket permissions
  file:
    path: /var/run/docker.sock
    owner: root
    group: docker
    mode: '0660'

- name: Configure Docker TLS
  when: docker_tls_enabled
  block:
    - name: Create Docker TLS directory
      file:
        path: /etc/docker/certs.d
        state: directory
        mode: '0700'

    - name: Copy TLS certificates
      copy:
        content: "{{ item.content }}"
        dest: "/etc/docker/{{ item.name }}"
        mode: '0600'
      loop:
        - { name: "ca.pem", content: "{{ docker_tls_ca_cert }}" }
        - { name: "server-cert.pem", content: "{{ docker_tls_server_cert }}" }
        - { name: "server-key.pem", content: "{{ docker_tls_server_key }}" }
      no_log: true
      notify: Restart docker

- name: Configure systemd drop-in for Docker security
  template:
    src: docker-security.conf.j2
    dest: /etc/systemd/system/docker.service.d/security.conf
  notify:
    - Daemon reload
    - Restart docker
```

### CIS Benchmark Compliance

```yaml
# roles/security/tasks/cis-benchmark.yml
---
# 1.1.1 - Ensure a separate partition for containers has been created
- name: Check Docker data partition
  when: docker_data_root != "/var/lib/docker"
  stat:
    path: "{{ docker_data_root }}"
  register: docker_partition

# 1.2.1 - Ensure the container host is hardened
- name: Ensure unnecessary packages are removed
  package:
    name: "{{ item }}"
    state: absent
  loop:
    - telnet
    - rsh-client
    - rsh-server

# 2.1 - Run the Docker daemon as a non-root user (rootless mode)
- name: Configure rootless Docker (optional)
  when: docker_rootless_mode | default(false)
  block:
    - name: Install rootless prerequisites
      package:
        name:
          - uidmap
          - dbus-user-session
        state: present

# 2.5 - Ensure aufs storage driver is not used
- name: Verify storage driver is not aufs
  assert:
    that:
      - docker_storage_driver != "aufs"
    msg: "AUFS storage driver is deprecated and insecure"

# 2.8 - Enable user namespace support
- name: Configure user namespace remapping
  when: docker_userns_remap | default('') != ''
  block:
    - name: Create subuid entry
      lineinfile:
        path: /etc/subuid
        line: "dockremap:100000:65536"
        create: yes

    - name: Create subgid entry
      lineinfile:
        path: /etc/subgid
        line: "dockremap:100000:65536"
        create: yes

# 2.14 - Restrict network traffic between containers
- name: Ensure ICC is disabled
  assert:
    that:
      - docker_icc | default(false) == false
    msg: "Inter-container communication should be disabled by default"
```

## Swarm Role

### Swarm Configuration

```yaml
# roles/swarm/defaults/main.yml
---
docker_swarm_enabled: false
docker_swarm_init: false
docker_swarm_advertise_addr: "{{ ansible_default_ipv4.address }}"
docker_swarm_listen_addr: "0.0.0.0:2377"

# Swarm node labels
docker_swarm_labels: {}

# Swarm networks
docker_swarm_networks:
  - name: traefik-public
    driver: overlay
    attachable: true

# Swarm secrets (from vault)
docker_swarm_secrets: []

# Swarm configs
docker_swarm_configs: []
```

### Swarm Initialization

```yaml
# roles/swarm/tasks/init.yml
---
- name: Initialize Docker Swarm
  community.docker.docker_swarm:
    state: present
    advertise_addr: "{{ docker_swarm_advertise_addr }}"
    listen_addr: "{{ docker_swarm_listen_addr }}"
  register: swarm_init
  run_once: true
  delegate_to: "{{ groups['swarm_managers'][0] }}"

- name: Get Swarm join tokens
  community.docker.docker_swarm_info:
  register: swarm_info
  run_once: true
  delegate_to: "{{ groups['swarm_managers'][0] }}"

- name: Join managers to Swarm
  community.docker.docker_swarm:
    state: join
    advertise_addr: "{{ docker_swarm_advertise_addr }}"
    join_token: "{{ swarm_info.swarm_facts.JoinTokens.Manager }}"
    remote_addrs: ["{{ hostvars[groups['swarm_managers'][0]]['ansible_default_ipv4']['address'] }}:2377"]
  when:
    - inventory_hostname in groups['swarm_managers']
    - inventory_hostname != groups['swarm_managers'][0]

- name: Join workers to Swarm
  community.docker.docker_swarm:
    state: join
    advertise_addr: "{{ docker_swarm_advertise_addr }}"
    join_token: "{{ swarm_info.swarm_facts.JoinTokens.Worker }}"
    remote_addrs: ["{{ hostvars[groups['swarm_managers'][0]]['ansible_default_ipv4']['address'] }}:2377"]
  when: inventory_hostname in groups['swarm_workers']

- name: Apply node labels
  community.docker.docker_node:
    hostname: "{{ inventory_hostname }}"
    labels: "{{ docker_swarm_labels }}"
  when: docker_swarm_labels | length > 0
  delegate_to: "{{ groups['swarm_managers'][0] }}"

- name: Create overlay networks
  community.docker.docker_network:
    name: "{{ item.name }}"
    driver: "{{ item.driver | default('overlay') }}"
    attachable: "{{ item.attachable | default(true) }}"
    scope: swarm
  loop: "{{ docker_swarm_networks }}"
  run_once: true
  delegate_to: "{{ groups['swarm_managers'][0] }}"
```

## Inventory Configuration

### Static Inventory

```ini
# inventory/production.ini
[docker_hosts]
docker01.example.com ansible_host=10.0.1.10
docker02.example.com ansible_host=10.0.1.11
docker03.example.com ansible_host=10.0.1.12

[docker_hosts:vars]
ansible_user=deploy
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[swarm_managers]
docker01.example.com

[swarm_workers]
docker02.example.com
docker03.example.com

[gpu_hosts]
gpu01.example.com nvidia_driver_version=535
```

### Dynamic Inventory (AWS)

```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-west-2

filters:
  tag:Role: docker
  instance-state-name: running

keyed_groups:
  - key: tags.Environment
    prefix: env
  - key: tags.SwarmRole
    prefix: swarm

compose:
  ansible_host: private_ip_address
```

## Handlers

```yaml
# roles/docker/handlers/main.yml
---
- name: Daemon reload
  systemd:
    daemon_reload: yes

- name: Restart docker
  service:
    name: docker
    state: restarted

- name: Restart containerd
  service:
    name: containerd
    state: restarted

- name: Restart auditd
  service:
    name: auditd
    state: restarted
```

## Monitoring Integration

### Prometheus Metrics

```yaml
# Enable Docker metrics endpoint
docker_metrics_addr: "0.0.0.0:9323"
docker_experimental: true

# Prometheus scrape config
prometheus_scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['docker01:9323', 'docker02:9323', 'docker03:9323']
```

### cAdvisor Deployment

```yaml
# Deploy cAdvisor container
- name: Deploy cAdvisor
  community.docker.docker_container:
    name: cadvisor
    image: gcr.io/cadvisor/cadvisor:v0.47.2
    state: started
    restart_policy: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    privileged: true
    devices:
      - /dev/kmsg
```

## NVIDIA GPU Support

```yaml
# roles/docker/tasks/nvidia.yml
---
- name: Install NVIDIA Container Toolkit
  when: nvidia_gpu_support | default(false)
  block:
    - name: Add NVIDIA GPG key
      apt_key:
        url: https://nvidia.github.io/libnvidia-container/gpgkey
        state: present

    - name: Add NVIDIA repository
      apt_repository:
        repo: "deb https://nvidia.github.io/libnvidia-container/stable/ubuntu22.04/$(ARCH) /"
        state: present
        filename: nvidia-container-toolkit

    - name: Install nvidia-container-toolkit
      package:
        name: nvidia-container-toolkit
        state: present
      notify: Restart docker

    - name: Configure NVIDIA runtime
      set_fact:
        docker_runtimes:
          nvidia:
            path: /usr/bin/nvidia-container-runtime
            runtimeArgs: []
```
