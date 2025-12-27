# ${{ values.name }}

${{ values.description }}

## Overview

This Ansible role provides production-ready Nginx web server installation and configuration with:

- Multi-distribution support (Ubuntu, Debian, CentOS, RHEL, Amazon Linux)
- Virtual host management with SSL/TLS termination
- Reverse proxy and load balancing configuration
- Gzip compression for optimized content delivery
- Security hardening with modern TLS settings
- Molecule-based testing for reliability

```d2
direction: right

title: {
  label: Nginx Deployment Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

ansible: Ansible Controller {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

role: ${{ values.name }} Role {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  install: Installation {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
    label: "Package\nManagement"
  }

  config: Configuration {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
    label: "nginx.conf\nWorkers\nGzip"
  }

  ssl: SSL/TLS {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "Certificates\nProtocols\nCiphers"
  }

  vhosts: Virtual Hosts {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "Sites\nUpstreams\nProxies"
  }

  install -> config -> ssl -> vhosts
}

servers: Target Servers {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  ubuntu: Ubuntu {
    shape: rectangle
  }
  debian: Debian {
    shape: rectangle
  }
  rhel: RHEL/CentOS {
    shape: rectangle
  }
}

clients: Web Clients {
  shape: cloud
  style.fill: "#ECEFF1"
  style.stroke: "#607D8B"
}

ansible -> role.install
role.vhosts -> servers
clients -> servers: HTTPS
```

## Configuration Summary

| Setting            | Value                                     |
| ------------------ | ----------------------------------------- |
| Role Name          | `${{ values.name }}`                      |
| Owner              | `${{ values.owner }}`                     |
| Repository         | `${{ values.destination.repo }}`          |
| Worker Processes   | `${{ values.nginxWorkerProcesses }}`      |
| Worker Connections | `${{ values.nginxWorkerConnections }}`    |
| SSL Protocols      | TLSv1.2, TLSv1.3                          |

## Role Structure

This role follows Ansible best practices with a modular structure:

```
${{ values.name }}/
├── defaults/
│   └── main.yml          # Default variable values
├── handlers/
│   └── main.yml          # Service handlers (reload/restart)
├── tasks/
│   ├── main.yml          # Main task entry point
│   ├── configure.yml     # Core Nginx configuration
│   ├── setup-debian.yml  # Debian/Ubuntu specific tasks
│   ├── setup-redhat.yml  # RHEL/CentOS specific tasks
│   ├── vhosts.yml        # Virtual host configuration
│   └── upstreams.yml     # Upstream/load balancer configuration
├── templates/
│   ├── nginx.conf.j2     # Main configuration template
│   ├── vhost.conf.j2     # Virtual host template
│   └── upstream.conf.j2  # Upstream template
├── molecule/
│   └── default/          # Test scenarios
├── meta/
│   └── main.yml          # Role metadata
└── docs/
    ├── index.md          # This documentation
    └── variables.md      # Variable reference
```

---

## CI/CD Pipeline

This role includes a comprehensive GitHub Actions pipeline for continuous integration:

- **Linting**: YAML syntax validation and Ansible best practices
- **Molecule Testing**: Automated testing across multiple platforms
- **Idempotence Checks**: Ensures role can be run multiple times safely

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
  label: "yamllint\nansible-lint"
}

molecule: Molecule {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  create: Create {
    label: "Docker\nContainers"
  }

  converge: Converge {
    label: "Run\nRole"
  }

  idempotence: Idempotence {
    label: "Verify\nNo Changes"
  }

  verify: Verify {
    label: "Test\nAssertions"
  }

  create -> converge -> idempotence -> verify
}

success: Success {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

pr -> lint -> molecule -> success
```

### Pipeline Triggers

| Trigger          | Actions                    |
| ---------------- | -------------------------- |
| Pull Request     | Lint, Molecule Test        |
| Push to main     | Lint, Molecule Test        |
| Manual           | Full test suite (optional) |

---

## Prerequisites

### 1. Ansible Controller Setup

#### Install Ansible

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible

# macOS
brew install ansible

# pip (any platform)
pip install ansible
```

#### Verify Installation

```bash
ansible --version
# Requires Ansible 2.9 or higher
```

### 2. Target Server Requirements

| Requirement    | Details                                           |
| -------------- | ------------------------------------------------- |
| OS             | Ubuntu 20.04+, Debian 10+, CentOS 7+, RHEL 7+     |
| Access         | SSH access with sudo/root privileges              |
| Python         | Python 3.x installed on target hosts              |
| Network        | Ports 80 (HTTP) and 443 (HTTPS) accessible        |

### 3. Ansible Inventory

Create an inventory file for your target servers:

```ini
# inventory/hosts.ini
[webservers]
web1.example.com ansible_user=ubuntu
web2.example.com ansible_user=ubuntu

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

## Usage

### Installation

```bash
# Install from Ansible Galaxy
ansible-galaxy install ${{ values.destination.owner }}.${{ values.name }}

# Or clone directly
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
```

### Basic Playbook

Create a playbook to run the role:

```yaml
# playbook.yml
---
- name: Configure Nginx web servers
  hosts: webservers
  become: true
  roles:
    - role: ${{ values.name }}
```

Run the playbook:

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

### Configuring Virtual Hosts

```yaml
# playbook.yml
---
- name: Configure Nginx with virtual hosts
  hosts: webservers
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_vhosts:
          - server_name: example.com www.example.com
            root: /var/www/example
            index: index.html index.htm
            listen: 80
            extra_parameters: |
              location /api {
                  proxy_pass http://backend;
              }

          - server_name: api.example.com
            listen: 443 ssl
            ssl_certificate: /etc/ssl/certs/api.example.com.crt
            ssl_certificate_key: /etc/ssl/private/api.example.com.key
            extra_parameters: |
              location / {
                  proxy_pass http://api_backend;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
              }
```

### Configuring Upstreams (Load Balancing)

```yaml
# playbook.yml
---
- name: Configure Nginx with load balancing
  hosts: webservers
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_upstreams:
          - name: backend
            strategy: least_conn
            servers:
              - 10.0.1.10:8080 weight=3
              - 10.0.1.11:8080 weight=2
              - 10.0.1.12:8080 backup

          - name: api_backend
            strategy: ip_hash
            keepalive: 32
            servers:
              - 10.0.2.10:3000
              - 10.0.2.11:3000
              - 10.0.2.12:3000
```

---

## Variables Documentation

### Package Configuration

| Variable               | Default   | Description                       |
| ---------------------- | --------- | --------------------------------- |
| `nginx_package_name`   | `nginx`   | Name of the Nginx package         |
| `nginx_package_state`  | `present` | Package state (present/latest)    |

### Service Configuration

| Variable                | Default   | Description                       |
| ----------------------- | --------- | --------------------------------- |
| `nginx_service_enabled` | `true`    | Enable Nginx on boot              |
| `nginx_service_state`   | `started` | Desired service state             |

### Worker Configuration

| Variable                   | Default                                | Description                         |
| -------------------------- | -------------------------------------- | ----------------------------------- |
| `nginx_worker_processes`   | `${{ values.nginxWorkerProcesses }}`   | Number of worker processes          |
| `nginx_worker_connections` | `${{ values.nginxWorkerConnections }}` | Max connections per worker          |
| `nginx_multi_accept`       | `on`                                   | Accept multiple connections at once |

### HTTP Core Settings

| Variable                   | Default | Description                        |
| -------------------------- | ------- | ---------------------------------- |
| `nginx_sendfile`           | `on`    | Enable sendfile                    |
| `nginx_tcp_nopush`         | `on`    | Enable TCP_NOPUSH                  |
| `nginx_tcp_nodelay`        | `on`    | Enable TCP_NODELAY                 |
| `nginx_keepalive_timeout`  | `65`    | Keep-alive timeout in seconds      |
| `nginx_server_tokens`      | `off`   | Hide Nginx version (security)      |

### Gzip Configuration

| Variable              | Default      | Description                    |
| --------------------- | ------------ | ------------------------------ |
| `nginx_gzip`          | `on`         | Enable gzip compression        |
| `nginx_gzip_vary`     | `on`         | Enable Vary header             |
| `nginx_gzip_proxied`  | `any`        | Compress proxied responses     |
| `nginx_gzip_comp_level` | `6`        | Compression level (1-9)        |
| `nginx_gzip_min_length` | `256`      | Minimum response size to gzip  |
| `nginx_gzip_types`    | See defaults | MIME types to compress         |

### Virtual Host Variables

| Variable                     | Default                       | Description                    |
| ---------------------------- | ----------------------------- | ------------------------------ |
| `nginx_vhosts`               | `[]`                          | List of virtual host configs   |
| `nginx_remove_default_vhost` | `true`                        | Remove default site            |
| `nginx_vhost_path`           | `/etc/nginx/sites-available`  | Path for vhost configs         |
| `nginx_vhost_enabled_path`   | `/etc/nginx/sites-enabled`    | Path for enabled vhosts        |

### Upstream Variables

| Variable          | Default | Description                       |
| ----------------- | ------- | --------------------------------- |
| `nginx_upstreams` | `[]`    | List of upstream configurations   |

---

## SSL/TLS Configuration

This role implements modern SSL/TLS best practices:

### Default SSL Settings

| Setting                  | Value                                          |
| ------------------------ | ---------------------------------------------- |
| Protocols                | TLSv1.2, TLSv1.3                               |
| Cipher Suite             | ECDHE-ECDSA/RSA with AES-GCM                   |
| Session Cache            | Shared 10MB cache                              |
| Session Timeout          | 1 day                                          |
| Session Tickets          | Disabled (for forward secrecy)                 |
| Prefer Server Ciphers    | Enabled                                        |

### Configuring SSL Virtual Host

```yaml
nginx_vhosts:
  - server_name: secure.example.com
    listen: "443 ssl http2"
    ssl_certificate: /etc/ssl/certs/example.com.crt
    ssl_certificate_key: /etc/ssl/private/example.com.key
    root: /var/www/secure
    extra_parameters: |
      # HSTS (optional)
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
      
      # OCSP Stapling
      ssl_stapling on;
      ssl_stapling_verify on;
      resolver 8.8.8.8 8.8.4.4 valid=300s;
```

### Let's Encrypt Integration

For automated certificate management, combine with certbot:

```yaml
# Pre-task: Install certbot and obtain certificates
- name: Install certbot
  ansible.builtin.package:
    name:
      - certbot
      - python3-certbot-nginx
    state: present

- name: Obtain SSL certificate
  ansible.builtin.command: >
    certbot certonly --nginx
    -d example.com -d www.example.com
    --email admin@example.com
    --agree-tos
    --non-interactive
  args:
    creates: /etc/letsencrypt/live/example.com/fullchain.pem
```

### HTTP to HTTPS Redirect

```yaml
nginx_vhosts:
  # HTTP redirect
  - server_name: example.com www.example.com
    listen: 80
    extra_parameters: |
      return 301 https://$server_name$request_uri;

  # HTTPS site
  - server_name: example.com www.example.com
    listen: "443 ssl http2"
    ssl_certificate: /etc/letsencrypt/live/example.com/fullchain.pem
    ssl_certificate_key: /etc/letsencrypt/live/example.com/privkey.pem
    root: /var/www/example
```

---

## Molecule Testing

This role includes comprehensive Molecule tests for automated validation.

### Running Tests Locally

```bash
# Install test dependencies
pip install molecule molecule-docker ansible-lint yamllint

# Run full test suite
molecule test

# Run specific test stages
molecule create    # Create test containers
molecule converge  # Run the role
molecule verify    # Run verification tests
molecule destroy   # Clean up containers

# Run with debug output
molecule --debug test
```

### Test Scenarios

The default scenario tests against Ubuntu 22.04:

| Stage       | Description                                      |
| ----------- | ------------------------------------------------ |
| dependency  | Install role dependencies                        |
| lint        | Run yamllint and ansible-lint                    |
| syntax      | Verify playbook syntax                           |
| create      | Create Docker containers                         |
| prepare     | Prepare containers (install prerequisites)       |
| converge    | Run the role                                     |
| idempotence | Verify role is idempotent                        |
| verify      | Run Ansible verification tasks                   |
| destroy     | Clean up test containers                         |

### Adding New Test Platforms

Edit `molecule/default/molecule.yml`:

```yaml
platforms:
  - name: ubuntu-22.04
    image: ubuntu:22.04
    pre_build_image: false
    dockerfile: Dockerfile.j2
    privileged: true
    command: /lib/systemd/systemd
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host

  - name: debian-12
    image: debian:12
    pre_build_image: false
    dockerfile: Dockerfile.j2
    privileged: true
    command: /lib/systemd/systemd
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host

  - name: centos-9
    image: quay.io/centos/centos:stream9
    pre_build_image: false
    dockerfile: Dockerfile.j2
    privileged: true
    command: /lib/systemd/systemd
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
```

### Verification Tests

The `molecule/default/verify.yml` contains test assertions:

```yaml
---
- name: Verify Nginx installation
  hosts: all
  gather_facts: false
  tasks:
    - name: Check Nginx is installed
      ansible.builtin.package:
        name: nginx
        state: present
      check_mode: true
      register: pkg
      failed_when: pkg.changed

    - name: Check Nginx is running
      ansible.builtin.service:
        name: nginx
        state: started
      check_mode: true
      register: svc
      failed_when: svc.changed

    - name: Verify Nginx responds on port 80
      ansible.builtin.uri:
        url: http://localhost
        return_content: true
      register: response
      failed_when: response.status != 200
```

---

## Troubleshooting

### Common Issues

#### Nginx fails to start

**Error: Address already in use**

```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
```

**Resolution:**

1. Check for conflicting services:
   ```bash
   sudo lsof -i :80
   sudo lsof -i :443
   ```

2. Stop conflicting services:
   ```bash
   sudo systemctl stop apache2  # or httpd
   ```

#### Configuration syntax error

**Error: nginx configuration test failed**

```
nginx: [emerg] unexpected "}" in /etc/nginx/sites-enabled/example.conf:25
```

**Resolution:**

1. Test configuration manually:
   ```bash
   sudo nginx -t
   ```

2. Check template syntax in your vhost configuration

3. Validate Jinja2 template:
   ```bash
   ansible-playbook playbook.yml --syntax-check
   ```

#### Permission denied for SSL certificates

**Error: cannot load certificate**

```
nginx: [emerg] cannot load certificate "/etc/ssl/certs/example.crt": BIO_new_file() failed
```

**Resolution:**

1. Check file permissions:
   ```bash
   ls -la /etc/ssl/certs/example.crt
   ls -la /etc/ssl/private/example.key
   ```

2. Ensure Nginx user can read certificates:
   ```bash
   sudo chown root:root /etc/ssl/private/example.key
   sudo chmod 600 /etc/ssl/private/example.key
   ```

#### Molecule test failures

**Error: Container creation failed**

**Resolution:**

1. Ensure Docker is running:
   ```bash
   sudo systemctl status docker
   ```

2. Clean up orphaned containers:
   ```bash
   docker system prune -f
   molecule destroy
   ```

3. Check Docker socket permissions:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

### Debug Mode

Run Ansible with increased verbosity:

```bash
# Verbose output
ansible-playbook -i inventory playbook.yml -v

# More verbose
ansible-playbook -i inventory playbook.yml -vvv

# Debug mode
ansible-playbook -i inventory playbook.yml -vvvv
```

### Validating Configuration

```bash
# Test Nginx configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Check Nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log
```

---

## Supported Platforms

| Platform     | Versions       | Status      |
| ------------ | -------------- | ----------- |
| Ubuntu       | 20.04, 22.04   | Tested      |
| Debian       | 10, 11, 12     | Tested      |
| CentOS       | 7, 8, 9 Stream | Tested      |
| RHEL         | 7, 8, 9        | Supported   |
| Amazon Linux | 2, 2023        | Supported   |

---

## Related Templates

| Template                                                                | Description                        |
| ----------------------------------------------------------------------- | ---------------------------------- |
| [ansible-haproxy](/docs/default/template/ansible-haproxy)               | HAProxy load balancer role         |
| [ansible-certbot](/docs/default/template/ansible-certbot)               | Let's Encrypt certificate role     |
| [ansible-docker](/docs/default/template/ansible-docker)                 | Docker installation role           |
| [ansible-postgresql](/docs/default/template/ansible-postgresql)         | PostgreSQL database role           |
| [aws-ec2-instance](/docs/default/template/aws-ec2-instance)             | AWS EC2 instance for hosting       |

---

## References

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Nginx Best Practices](https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

---

## License

MIT

## Author

${{ values.owner }}
