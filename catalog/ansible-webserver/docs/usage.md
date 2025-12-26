# Ansible Webserver Usage Guide

## Architecture Overview

```d2
direction: right

title: Web Server Deployment Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

clients: Clients {
  shape: rectangle
  style.fill: "#E3F2FD"

  browser: Browser
  mobile: Mobile App
  api: API Client
}

lb: Load Balancer {
  shape: hexagon
  style.fill: "#FF9800"
  style.font-color: white
}

webservers: Web Server Cluster {
  shape: rectangle
  style.fill: "#C8E6C9"

  web1: web01 {
    shape: rectangle
    style.fill: "#81C784"
    nginx1: Nginx
    php1: PHP-FPM
  }

  web2: web02 {
    shape: rectangle
    style.fill: "#81C784"
    nginx2: Nginx
    php2: PHP-FPM
  }

  web3: web03 {
    shape: rectangle
    style.fill: "#81C784"
    nginx3: Nginx
    php3: PHP-FPM
  }
}

backends: Backend Services {
  shape: rectangle
  style.fill: "#E1BEE7"

  api_servers: API Servers
  database: Database
  cache: Redis Cache
}

ssl: SSL/TLS {
  shape: rectangle
  style.fill: "#FFF9C4"

  letsencrypt: Let's Encrypt
  certs: Certificates
}

clients -> lb: HTTPS
lb -> webservers: HTTP/2
webservers -> backends: Internal
ssl -> lb: Terminates TLS
ssl -> webservers: End-to-end TLS
```

## Installation

### Requirements File

```yaml
# requirements.yml
---
collections:
  - name: community.general
    version: '>=7.0.0'
  - name: ansible.posix
    version: '>=1.5.0'
  - name: community.crypto
    version: '>=2.0.0'
  - name: amazon.aws
    version: '>=6.0.0'

roles:
  - name: geerlingguy.nginx
    version: '3.1.0'
  - name: geerlingguy.apache
    version: '3.2.0'
  - name: geerlingguy.certbot
    version: '5.1.0'
```

```bash
# Install requirements
ansible-galaxy install -r requirements.yml --force
```

### Ansible Configuration

```ini
# ansible.cfg
[defaults]
inventory = inventory/production.ini
remote_user = deploy
private_key_file = ~/.ssh/deploy_key
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
control_path = /tmp/ansible-%%r@%%h:%%p

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, aws_ec2
```

## Deployment Examples

### Basic Nginx Deployment

```yaml
# playbooks/webserver.yml
---
- name: Deploy Nginx Web Servers
  hosts: webservers
  become: yes

  vars:
    webserver_type: nginx
    nginx_worker_processes: '{{ ansible_processor_vcpus }}'
    nginx_worker_connections: 4096

    nginx_vhosts:
      - server_name: '{{ inventory_hostname }}'
        root: '/var/www/html'
        index: 'index.html'
        ssl: false

  roles:
    - common
    - security
    - nginx
```

```bash
# Execute deployment
ansible-playbook playbooks/webserver.yml

# With specific inventory
ansible-playbook -i inventory/staging.ini playbooks/webserver.yml

# Limit to specific hosts
ansible-playbook playbooks/webserver.yml --limit web01.example.com

# Run specific tags only
ansible-playbook playbooks/webserver.yml --tags "nginx,ssl"
```

### Production Multi-Site Deployment

```yaml
# playbooks/production-sites.yml
---
- name: Deploy Production Websites
  hosts: webservers
  become: yes

  vars:
    nginx_vhosts:
      # Main website
      - server_name: 'example.com www.example.com'
        root: '/var/www/example.com/public'
        index: 'index.php index.html'
        ssl: true
        ssl_certificate: '/etc/letsencrypt/live/example.com/fullchain.pem'
        ssl_certificate_key: '/etc/letsencrypt/live/example.com/privkey.pem'
        http2: true
        locations:
          - path: '/'
            options:
              - 'try_files $uri $uri/ /index.php?$query_string'
          - path: "~ \\.php$"
            options:
              - 'fastcgi_pass unix:/var/run/php/php8.2-fpm.sock'
              - 'fastcgi_index index.php'
              - 'include fastcgi_params'
              - 'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name'

      # API subdomain
      - server_name: 'api.example.com'
        ssl: true
        ssl_certificate: '/etc/letsencrypt/live/api.example.com/fullchain.pem'
        ssl_certificate_key: '/etc/letsencrypt/live/api.example.com/privkey.pem'
        locations:
          - path: '/'
            proxy_pass: 'http://api_backend'
            proxy_options:
              - 'proxy_http_version 1.1'
              - 'proxy_set_header Host $host'
              - 'proxy_set_header X-Real-IP $remote_addr'
              - 'proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for'
              - 'proxy_set_header X-Forwarded-Proto $scheme'
              - 'proxy_connect_timeout 60s'
              - 'proxy_send_timeout 60s'
              - 'proxy_read_timeout 60s'

    nginx_upstreams:
      - name: api_backend
        strategy: least_conn
        keepalive: 32
        servers:
          - '10.0.2.10:3000 weight=5'
          - '10.0.2.11:3000 weight=5'
          - '10.0.2.12:3000 weight=3'

    ssl_certificates:
      - domains:
          - 'example.com'
          - 'www.example.com'
        webroot: '/var/www/example.com/public'
      - domains:
          - 'api.example.com'
        webroot: '/var/www/api.example.com/public'

  pre_tasks:
    - name: Create web directories
      file:
        path: '{{ item }}'
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
      loop:
        - /var/www/example.com/public
        - /var/www/api.example.com/public

  roles:
    - common
    - security
    - nginx
    - ssl

  post_tasks:
    - name: Verify Nginx configuration
      command: nginx -t
      changed_when: false

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: yes
```

### Load Balancer Configuration

```yaml
# playbooks/load-balancer.yml
---
- name: Configure Nginx Load Balancer
  hosts: load_balancers
  become: yes

  vars:
    nginx_worker_processes: '{{ ansible_processor_vcpus }}'
    nginx_worker_connections: 8192

    nginx_upstreams:
      - name: web_servers
        strategy: ip_hash
        keepalive: 64
        servers:
          - '10.0.1.10:80 weight=5 max_fails=3 fail_timeout=30s'
          - '10.0.1.11:80 weight=5 max_fails=3 fail_timeout=30s'
          - '10.0.1.12:80 weight=5 max_fails=3 fail_timeout=30s'
          - '10.0.1.13:80 backup'
        health_check:
          uri: '/health'
          interval: 5
          fails: 3
          passes: 2

    nginx_vhosts:
      - server_name: 'example.com www.example.com'
        ssl: true
        ssl_certificate: '/etc/letsencrypt/live/example.com/fullchain.pem'
        ssl_certificate_key: '/etc/letsencrypt/live/example.com/privkey.pem'
        locations:
          - path: '/'
            proxy_pass: 'http://web_servers'
            proxy_options:
              - 'proxy_http_version 1.1'
              - 'proxy_set_header Host $host'
              - 'proxy_set_header X-Real-IP $remote_addr'
              - 'proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for'
              - 'proxy_set_header X-Forwarded-Proto $scheme'
              - "proxy_set_header Connection ''"
              - 'proxy_buffering off'
              - 'proxy_request_buffering off'
              - 'proxy_connect_timeout 60s'
              - 'proxy_send_timeout 300s'
              - 'proxy_read_timeout 300s'
          - path: '/health'
            options:
              - 'access_log off'
              - "return 200 'OK'"
              - 'add_header Content-Type text/plain'

  roles:
    - common
    - security
    - nginx
    - ssl
```

### SSL Certificate Renewal

```yaml
# playbooks/ssl-renew.yml
---
- name: Renew SSL Certificates
  hosts: webservers
  become: yes
  serial: 1 # One server at a time

  tasks:
    - name: Check certificate expiration
      community.crypto.x509_certificate_info:
        path: '/etc/letsencrypt/live/{{ item.domains[0] }}/fullchain.pem'
      register: cert_info
      loop: '{{ ssl_certificates }}'
      loop_control:
        label: '{{ item.domains[0] }}'

    - name: Renew certificates expiring within 30 days
      command: >
        certbot renew
        --cert-name {{ item.item.domains[0] }}
        --webroot -w {{ item.item.webroot }}
        --non-interactive
        --quiet
      when: (item.not_after | to_datetime('%Y%m%d%H%M%SZ') - ansible_date_time.date | to_datetime('%Y-%m-%d')).days < 30
      loop: '{{ cert_info.results }}'
      loop_control:
        label: '{{ item.item.domains[0] }}'
      notify: Reload nginx

    - name: Verify renewed certificates
      community.crypto.x509_certificate_info:
        path: '/etc/letsencrypt/live/{{ item.domains[0] }}/fullchain.pem'
      register: new_cert_info
      loop: '{{ ssl_certificates }}'
      loop_control:
        label: '{{ item.domains[0] }}'

    - name: Display certificate expiration dates
      debug:
        msg: '{{ item.item.domains[0] }}: expires {{ item.not_after }}'
      loop: '{{ new_cert_info.results }}'
      loop_control:
        label: '{{ item.item.domains[0] }}'

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

## Zero-Downtime Deployment

### Rolling Update Playbook

```yaml
# playbooks/rolling-update.yml
---
- name: Rolling Update Web Servers
  hosts: webservers
  become: yes
  serial: 1 # One server at a time
  max_fail_percentage: 0 # Stop on any failure

  pre_tasks:
    - name: Disable server in load balancer
      uri:
        url: 'http://{{ lb_api_endpoint }}/api/servers/{{ inventory_hostname }}/disable'
        method: POST
        headers:
          Authorization: 'Bearer {{ lb_api_token }}'
      delegate_to: localhost
      when: lb_api_endpoint is defined

    - name: Wait for connections to drain
      wait_for:
        timeout: 30

    - name: Stop accepting new connections
      iptables:
        chain: INPUT
        protocol: tcp
        destination_port: 80
        jump: DROP
        comment: 'Block new connections during update'
      register: iptables_block

  roles:
    - nginx

  post_tasks:
    - name: Remove iptables block
      iptables:
        chain: INPUT
        protocol: tcp
        destination_port: 80
        jump: DROP
        state: absent
      when: iptables_block is changed

    - name: Verify Nginx is healthy
      uri:
        url: 'http://127.0.0.1/health'
        status_code: 200
      register: health_check
      retries: 5
      delay: 2
      until: health_check.status == 200

    - name: Re-enable server in load balancer
      uri:
        url: 'http://{{ lb_api_endpoint }}/api/servers/{{ inventory_hostname }}/enable'
        method: POST
        headers:
          Authorization: 'Bearer {{ lb_api_token }}'
      delegate_to: localhost
      when: lb_api_endpoint is defined

    - name: Wait for server to receive traffic
      pause:
        seconds: 10
```

### Blue-Green Deployment

```yaml
# playbooks/blue-green.yml
---
- name: Blue-Green Deployment
  hosts: localhost
  gather_facts: no

  vars:
    current_env: "{{ lookup('file', '/tmp/current_env') | default('blue') }}"
    new_env: "{{ 'green' if current_env == 'blue' else 'blue' }}"

  tasks:
    - name: Deploy to {{ new_env }} environment
      include_role:
        name: nginx
      delegate_to: '{{ item }}'
      loop: "{{ groups[new_env + '_webservers'] }}"

    - name: Verify {{ new_env }} environment health
      uri:
        url: 'http://{{ item }}/health'
        status_code: 200
      loop: "{{ groups[new_env + '_webservers'] }}"
      register: health_checks
      failed_when: health_checks is failed

    - name: Switch load balancer to {{ new_env }}
      uri:
        url: 'http://{{ lb_api_endpoint }}/api/backend'
        method: PUT
        body_format: json
        body:
          backend: '{{ new_env }}_servers'
        headers:
          Authorization: 'Bearer {{ lb_api_token }}'
      when: health_checks is succeeded

    - name: Record current environment
      copy:
        content: '{{ new_env }}'
        dest: /tmp/current_env

    - name: Notify deployment success
      slack:
        token: '{{ slack_token }}'
        channel: '#deployments'
        msg: 'Successfully deployed to {{ new_env }} environment'
      when: slack_token is defined
```

## Ansible Vault for Secrets

### Encrypting Secrets

```bash
# Create encrypted variables file
ansible-vault create group_vars/webservers/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/webservers/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/webservers/secrets.yml

# View encrypted file
ansible-vault view group_vars/webservers/vault.yml

# Decrypt file
ansible-vault decrypt group_vars/webservers/vault.yml
```

### Vault Variables Structure

```yaml
# group_vars/webservers/vault.yml (encrypted)
vault_ssl_certificate: |
  -----BEGIN CERTIFICATE-----
  MIIFazCCA1OgAwIBAgIUXXXXXXXX...
  -----END CERTIFICATE-----

vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  MIIEvgIBADANBgkqhkiG9w0BAQEF...
  -----END PRIVATE KEY-----

vault_htpasswd_users:
  - username: admin
    password: 'supersecretpassword'
  - username: deploy
    password: 'anothersecretpassword'

vault_api_keys:
  datadog: 'xxxxxxxxxxxxxxxxxxxx'
  newrelic: 'yyyyyyyyyyyyyyyyyyyy'
```

### Using Vault in Playbooks

```yaml
# group_vars/webservers/main.yml
ssl_certificate: "{{ vault_ssl_certificate }}"
ssl_private_key: "{{ vault_ssl_private_key }}"

# Run with vault password
ansible-playbook site.yml --ask-vault-pass

# Or use password file
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

## Testing with Molecule

### Molecule Configuration

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml

driver:
  name: docker

platforms:
  - name: ubuntu2204
    image: ubuntu:22.04
    command: /sbin/init
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host

  - name: rocky9
    image: rockylinux:9
    command: /sbin/init
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host

provisioner:
  name: ansible
  inventory:
    host_vars:
      ubuntu2204:
        ansible_python_interpreter: /usr/bin/python3
      rocky9:
        ansible_python_interpreter: /usr/bin/python3

verifier:
  name: ansible

scenario:
  name: default
  test_sequence:
    - dependency
    - syntax
    - create
    - prepare
    - converge
    - idempotence
    - verify
    - destroy
```

### Verification Tests

```yaml
# molecule/default/verify.yml
---
- name: Verify Nginx installation
  hosts: all
  become: yes

  tasks:
    - name: Check Nginx is installed
      package:
        name: nginx
        state: present
      check_mode: yes
      register: nginx_installed
      failed_when: nginx_installed.changed

    - name: Check Nginx is running
      service:
        name: nginx
        state: started
      check_mode: yes
      register: nginx_running
      failed_when: nginx_running.changed

    - name: Verify Nginx configuration syntax
      command: nginx -t
      changed_when: false

    - name: Check Nginx responds on port 80
      uri:
        url: http://127.0.0.1/
        status_code: 200
      register: nginx_response

    - name: Verify security headers
      uri:
        url: http://127.0.0.1/
        return_content: no
      register: response
      failed_when: >
        'X-Frame-Options' not in response.headers or
        'X-Content-Type-Options' not in response.headers
```

### Running Tests

```bash
# Run full test sequence
molecule test

# Run specific scenario
molecule test -s default

# Just converge (apply playbook)
molecule converge

# Run verification only
molecule verify

# Login to test container
molecule login -h ubuntu2204

# Destroy test environment
molecule destroy
```

## Troubleshooting

| Issue                         | Cause                    | Solution                                             |
| ----------------------------- | ------------------------ | ---------------------------------------------------- |
| SSH connection timeout        | Firewall blocking SSH    | Check security groups, ensure port 22 is open        |
| Permission denied (publickey) | Wrong SSH key            | Verify `ansible_ssh_private_key_file` path           |
| Module not found              | Missing collection       | Run `ansible-galaxy install -r requirements.yml`     |
| Nginx config test fails       | Syntax error in template | Check Jinja2 template syntax, run `nginx -t` locally |
| SSL certificate not found     | Let's Encrypt failed     | Check domain DNS, verify webroot accessible          |
| Handler not triggered         | Task unchanged           | Use `changed_when: true` or `notify` on correct task |
| Idempotence failure           | Task always changes      | Use `creates`, `removes`, or proper conditionals     |
| Variable undefined            | Missing in inventory     | Check `group_vars`, `host_vars`, and defaults        |

### Debug Commands

```bash
# Verbose output
ansible-playbook site.yml -vvv

# Debug specific task
ansible-playbook site.yml --start-at-task="Install Nginx"

# List all variables for a host
ansible web01.example.com -m debug -a "var=hostvars[inventory_hostname]"

# Check connectivity
ansible all -m ping

# Gather facts
ansible web01.example.com -m setup

# Syntax check
ansible-playbook site.yml --syntax-check

# List tasks
ansible-playbook site.yml --list-tasks

# Dry run
ansible-playbook site.yml --check --diff
```

## Best Practices

### Role Development

1. **Use defaults/main.yml** - Define all variables with sensible defaults
2. **Validate variables** - Use `assert` module for required variables
3. **Idempotency** - Ensure playbooks can run multiple times safely
4. **Tags** - Tag tasks for selective execution
5. **Handlers** - Use handlers for service restarts

### Security

1. **Use Ansible Vault** - Encrypt all sensitive data
2. **Limit sudo** - Use `become` only when necessary
3. **SSH keys** - Never use password authentication
4. **Rotate secrets** - Regularly update passwords and keys
5. **Audit logging** - Enable callback plugins for audit trails

### Performance

1. **Use pipelining** - Enable SSH pipelining in ansible.cfg
2. **Fact caching** - Cache facts to reduce gather time
3. **Async tasks** - Use async for long-running operations
4. **Limit scope** - Use `--limit` for targeted runs
5. **Parallelism** - Adjust `forks` in ansible.cfg

### CI/CD Integration

```yaml
# .github/workflows/ansible.yml
name: Ansible CI

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

  molecule:
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
