# Ansible Webserver Overview

## Role Architecture

### Role Dependencies

```d2
direction: down

title: Ansible Webserver Role Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

site: site.yml {
  shape: document
  style.fill: "#E3F2FD"
}

common: Common Role {
  shape: rectangle
  style.fill: "#C8E6C9"

  tasks: |md
    - Update packages
    - Install prerequisites
    - Configure firewall
    - Set timezone/NTP
    - Create service users
  |
}

security: Security Role {
  shape: rectangle
  style.fill: "#FFCDD2"

  tasks: |md
    - SSH hardening
    - Fail2ban setup
    - SELinux/AppArmor
    - Audit logging
  |
}

webserver: Webserver Role {
  shape: rectangle
  style.fill: "#BBDEFB"

  nginx: Nginx {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  apache: Apache {
    shape: hexagon
    style.fill: "#FF5722"
    style.font-color: white
  }

  tasks: |md
    - Install web server
    - Configure main settings
    - Setup virtual hosts
    - Enable modules
    - Configure logging
  |
}

ssl: SSL Role {
  shape: rectangle
  style.fill: "#FFF9C4"

  tasks: |md
    - Let's Encrypt setup
    - Certificate deployment
    - Auto-renewal cron
    - OCSP stapling
  |
}

site -> common: includes
common -> security: depends
security -> webserver: depends
webserver -> ssl: depends
webserver.nginx -> ssl
webserver.apache -> ssl
```

## Nginx Role

### Default Configuration

```yaml
# roles/nginx/defaults/main.yml
nginx_version: '1.24'
nginx_user: 'www-data'
nginx_worker_processes: 'auto'
nginx_worker_connections: 4096
nginx_multi_accept: 'on'

# Performance
nginx_keepalive_timeout: 65
nginx_keepalive_requests: 1000
nginx_client_max_body_size: '64m'
nginx_client_body_buffer_size: '128k'

# Gzip compression
nginx_gzip: 'on'
nginx_gzip_types:
  - text/plain
  - text/css
  - text/javascript
  - application/javascript
  - application/json
  - application/xml
  - image/svg+xml

# Security headers
nginx_security_headers:
  X-Frame-Options: 'SAMEORIGIN'
  X-Content-Type-Options: 'nosniff'
  X-XSS-Protection: '1; mode=block'
  Referrer-Policy: 'strict-origin-when-cross-origin'
  Content-Security-Policy: "default-src 'self'"

# SSL settings
nginx_ssl_protocols: 'TLSv1.2 TLSv1.3'
nginx_ssl_ciphers: 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256'
nginx_ssl_prefer_server_ciphers: 'on'
nginx_ssl_session_cache: 'shared:SSL:10m'
nginx_ssl_session_timeout: '1d'
nginx_ssl_stapling: 'on'
nginx_ssl_stapling_verify: 'on'

# Logging
nginx_access_log: '/var/log/nginx/access.log'
nginx_error_log: '/var/log/nginx/error.log'
nginx_log_format: 'combined'
```

### Virtual Host Configuration

```yaml
# group_vars/webservers.yml
nginx_vhosts:
  - server_name: 'example.com www.example.com'
    root: '/var/www/example.com/public'
    index: 'index.html index.php'
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

      - path: '/api'
        proxy_pass: 'http://backend_servers'
        proxy_options:
          - 'proxy_http_version 1.1'
          - 'proxy_set_header Upgrade $http_upgrade'
          - "proxy_set_header Connection 'upgrade'"
          - 'proxy_set_header Host $host'
          - 'proxy_set_header X-Real-IP $remote_addr'
          - 'proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for'
          - 'proxy_set_header X-Forwarded-Proto $scheme'
          - 'proxy_cache_bypass $http_upgrade'

      - path: "~* \\.(jpg|jpeg|png|gif|ico|css|js|woff2)$"
        options:
          - 'expires 30d'
          - "add_header Cache-Control 'public, immutable'"
          - 'access_log off'

    extra_config: |
      # Rate limiting
      limit_req zone=api burst=20 nodelay;

      # Security
      location ~ /\\. {
          deny all;
      }

nginx_upstreams:
  - name: 'backend_servers'
    strategy: 'least_conn'
    keepalive: 32
    servers:
      - '10.0.1.10:8080 weight=5'
      - '10.0.1.11:8080 weight=5'
      - '10.0.1.12:8080 backup'

nginx_rate_limits:
  - name: 'api'
    zone_size: '10m'
    rate: '10r/s'
```

### Nginx Main Template

```jinja2
# roles/nginx/templates/nginx.conf.j2
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
error_log {{ nginx_error_log }} warn;
pid /run/nginx.pid;

worker_rlimit_nofile 65535;

events {
    worker_connections {{ nginx_worker_connections }};
    multi_accept {{ nginx_multi_accept }};
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    log_format json escape=json '{'
        '"time_local":"$time_local",'
        '"remote_addr":"$remote_addr",'
        '"request":"$request",'
        '"status":$status,'
        '"body_bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"upstream_response_time":"$upstream_response_time",'
        '"http_referrer":"$http_referer",'
        '"http_user_agent":"$http_user_agent"'
    '}';

    access_log {{ nginx_access_log }} {{ nginx_log_format }};

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    keepalive_requests {{ nginx_keepalive_requests }};

    # Buffer sizes
    client_max_body_size {{ nginx_client_max_body_size }};
    client_body_buffer_size {{ nginx_client_body_buffer_size }};
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;

    # Gzip
{% if nginx_gzip == 'on' %}
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types {{ nginx_gzip_types | join(' ') }};
{% endif %}

    # SSL
    ssl_protocols {{ nginx_ssl_protocols }};
    ssl_ciphers {{ nginx_ssl_ciphers }};
    ssl_prefer_server_ciphers {{ nginx_ssl_prefer_server_ciphers }};
    ssl_session_cache {{ nginx_ssl_session_cache }};
    ssl_session_timeout {{ nginx_ssl_session_timeout }};
{% if nginx_ssl_stapling == 'on' %}
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
{% endif %}

    # Security headers
    add_header X-Frame-Options "{{ nginx_security_headers['X-Frame-Options'] }}" always;
    add_header X-Content-Type-Options "{{ nginx_security_headers['X-Content-Type-Options'] }}" always;
    add_header X-XSS-Protection "{{ nginx_security_headers['X-XSS-Protection'] }}" always;
    add_header Referrer-Policy "{{ nginx_security_headers['Referrer-Policy'] }}" always;

    # Rate limiting zones
{% for limit in nginx_rate_limits | default([]) %}
    limit_req_zone $binary_remote_addr zone={{ limit.name }}:{{ limit.zone_size }} rate={{ limit.rate }};
{% endfor %}

    # Upstreams
{% for upstream in nginx_upstreams | default([]) %}
    upstream {{ upstream.name }} {
{% if upstream.strategy is defined %}
        {{ upstream.strategy }};
{% endif %}
{% if upstream.keepalive is defined %}
        keepalive {{ upstream.keepalive }};
{% endif %}
{% for server in upstream.servers %}
        server {{ server }};
{% endfor %}
    }
{% endfor %}

    # Virtual hosts
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

## Apache Role

### Default Configuration

```yaml
# roles/apache/defaults/main.yml
apache_version: '2.4'
apache_user: 'www-data'
apache_group: 'www-data'

# MPM configuration
apache_mpm: 'event' # prefork, worker, or event
apache_mpm_start_servers: 2
apache_mpm_min_spare_threads: 25
apache_mpm_max_spare_threads: 75
apache_mpm_thread_limit: 64
apache_mpm_threads_per_child: 25
apache_mpm_max_request_workers: 150
apache_mpm_max_connections_per_child: 0

# Performance
apache_keepalive: 'On'
apache_keepalive_timeout: 5
apache_max_keepalive_requests: 100
apache_timeout: 60

# Modules to enable
apache_modules:
  - rewrite
  - ssl
  - headers
  - expires
  - deflate
  - proxy
  - proxy_http
  - proxy_fcgi
  - http2

# Security settings
apache_server_tokens: 'Prod'
apache_server_signature: 'Off'
apache_trace_enable: 'Off'
```

### Apache Virtual Host

```yaml
# group_vars/webservers.yml (Apache)
apache_vhosts:
  - server_name: 'example.com'
    server_aliases:
      - 'www.example.com'
    document_root: '/var/www/example.com/public'
    ssl: true
    ssl_certificate: '/etc/letsencrypt/live/example.com/fullchain.pem'
    ssl_certificate_key: '/etc/letsencrypt/live/example.com/privkey.pem'

    directory_options:
      - 'Options -Indexes +FollowSymLinks'
      - 'AllowOverride All'
      - 'Require all granted'

    custom_log: '/var/log/apache2/example.com-access.log combined'
    error_log: '/var/log/apache2/example.com-error.log'

    extra_config: |
      # PHP-FPM proxy
      <FilesMatch \.php$>
          SetHandler "proxy:unix:/var/run/php/php8.2-fpm.sock|fcgi://localhost"
      </FilesMatch>

      # Security headers
      Header always set X-Frame-Options "SAMEORIGIN"
      Header always set X-Content-Type-Options "nosniff"
      Header always set X-XSS-Protection "1; mode=block"

      # Compression
      <IfModule mod_deflate.c>
          AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
          AddOutputFilterByType DEFLATE application/javascript application/json
      </IfModule>

      # Caching
      <IfModule mod_expires.c>
          ExpiresActive On
          ExpiresByType image/jpg "access plus 1 month"
          ExpiresByType image/jpeg "access plus 1 month"
          ExpiresByType image/gif "access plus 1 month"
          ExpiresByType image/png "access plus 1 month"
          ExpiresByType text/css "access plus 1 week"
          ExpiresByType application/javascript "access plus 1 week"
      </IfModule>
```

## SSL/TLS Role

### Let's Encrypt Configuration

```yaml
# roles/ssl/defaults/main.yml
ssl_provider: 'letsencrypt' # letsencrypt or custom
ssl_letsencrypt_email: 'admin@example.com'
ssl_letsencrypt_staging: false
ssl_letsencrypt_webroot: '/var/www/letsencrypt'
ssl_auto_renew: true
ssl_renew_cron_hour: 2
ssl_renew_cron_minute: 30

# Certificate domains
ssl_certificates:
  - domains:
      - 'example.com'
      - 'www.example.com'
    webroot: '/var/www/example.com/public'

  - domains:
      - 'api.example.com'
    webroot: '/var/www/api.example.com/public'

# Custom certificate deployment
ssl_custom_certificates:
  - name: 'internal.example.com'
    cert_content: '{{ vault_ssl_cert }}'
    key_content: '{{ vault_ssl_key }}'
    chain_content: '{{ vault_ssl_chain }}'
```

### SSL Hardening Task

```yaml
# roles/ssl/tasks/hardening.yml
- name: Generate DH parameters
  community.crypto.openssl_dhparam:
    path: /etc/ssl/certs/dhparam.pem
    size: 2048
  notify: Reload nginx

- name: Configure SSL session tickets
  copy:
    content: |
      ssl_session_tickets off;
      ssl_session_cache shared:SSL:10m;
      ssl_session_timeout 1d;
    dest: /etc/nginx/conf.d/ssl-hardening.conf
  notify: Reload nginx

- name: Enable HSTS
  lineinfile:
    path: /etc/nginx/conf.d/security-headers.conf
    line: 'add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;'
    create: yes
  notify: Reload nginx
```

## Security Role

### Security Hardening Tasks

```yaml
# roles/security/tasks/main.yml
- name: Configure SSH hardening
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: '0600'
    validate: '/usr/sbin/sshd -t -f %s'
  notify: Restart sshd

- name: Install and configure fail2ban
  block:
    - name: Install fail2ban
      package:
        name: fail2ban
        state: present

    - name: Configure fail2ban jail
      template:
        src: jail.local.j2
        dest: /etc/fail2ban/jail.local
      notify: Restart fail2ban

    - name: Enable fail2ban
      service:
        name: fail2ban
        state: started
        enabled: yes

- name: Configure firewall (UFW)
  when: ansible_os_family == 'Debian'
  block:
    - name: Install UFW
      package:
        name: ufw
        state: present

    - name: Allow SSH
      ufw:
        rule: allow
        port: "{{ ssh_port | default('22') }}"
        proto: tcp

    - name: Allow HTTP
      ufw:
        rule: allow
        port: 80
        proto: tcp

    - name: Allow HTTPS
      ufw:
        rule: allow
        port: 443
        proto: tcp

    - name: Enable UFW
      ufw:
        state: enabled
        policy: deny
        direction: incoming

- name: Configure ModSecurity (WAF)
  when: modsecurity_enabled | default(false)
  block:
    - name: Install ModSecurity
      package:
        name: '{{ modsecurity_packages[ansible_os_family] }}'
        state: present

    - name: Deploy OWASP Core Rule Set
      git:
        repo: https://github.com/coreruleset/coreruleset.git
        dest: /etc/modsecurity/crs
        version: 'v3.3.5'

    - name: Configure ModSecurity
      template:
        src: modsecurity.conf.j2
        dest: /etc/modsecurity/modsecurity.conf
      notify: Reload nginx
```

### Fail2ban Configuration

```yaml
# roles/security/defaults/main.yml
fail2ban_bantime: 3600
fail2ban_findtime: 600
fail2ban_maxretry: 5
fail2ban_ignoreips:
  - 127.0.0.1/8
  - 10.0.0.0/8

fail2ban_jails:
  - name: sshd
    enabled: true
    port: "{{ ssh_port | default('22') }}"
    filter: sshd
    logpath: /var/log/auth.log
    maxretry: 3

  - name: nginx-http-auth
    enabled: true
    port: http,https
    filter: nginx-http-auth
    logpath: /var/log/nginx/error.log
    maxretry: 5

  - name: nginx-botsearch
    enabled: true
    port: http,https
    filter: nginx-botsearch
    logpath: /var/log/nginx/access.log
    maxretry: 2
```

## Inventory Configuration

### Production Inventory

```ini
# inventory/production.ini
[webservers]
web01.example.com ansible_host=10.0.1.10 nginx_worker_processes=4
web02.example.com ansible_host=10.0.1.11 nginx_worker_processes=4
web03.example.com ansible_host=10.0.1.12 nginx_worker_processes=8

[webservers:vars]
ansible_user=deploy
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[nginx]
web01.example.com
web02.example.com

[apache]
web03.example.com

[load_balancers]
lb01.example.com ansible_host=10.0.1.5
lb02.example.com ansible_host=10.0.1.6
```

### Dynamic Inventory (AWS)

```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-west-2
  - us-east-1

filters:
  tag:Environment: production
  tag:Role: webserver
  instance-state-name: running

keyed_groups:
  - key: tags.Environment
    prefix: env
  - key: tags.Role
    prefix: role
  - key: placement.availability_zone
    prefix: az

hostnames:
  - private-ip-address

compose:
  ansible_host: private_ip_address
```

## Handlers

```yaml
# roles/nginx/handlers/main.yml
- name: Validate nginx config
  command: nginx -t
  register: nginx_validate
  changed_when: false
  listen: 'Reload nginx'

- name: Reload nginx
  service:
    name: nginx
    state: reloaded
  when: nginx_validate is succeeded

- name: Restart nginx
  service:
    name: nginx
    state: restarted

# roles/apache/handlers/main.yml
- name: Validate apache config
  command: apachectl configtest
  register: apache_validate
  changed_when: false
  listen: 'Reload apache'

- name: Reload apache
  service:
    name: '{{ apache_service_name }}'
    state: reloaded
  when: apache_validate is succeeded

- name: Restart apache
  service:
    name: '{{ apache_service_name }}'
    state: restarted
```

## Monitoring Integration

### Prometheus Nginx Exporter

```yaml
# roles/nginx/tasks/monitoring.yml
- name: Install nginx-prometheus-exporter
  when: nginx_prometheus_exporter | default(false)
  block:
    - name: Download nginx-prometheus-exporter
      get_url:
        url: 'https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v1.1.0/nginx-prometheus-exporter_1.1.0_linux_amd64.tar.gz'
        dest: /tmp/nginx-prometheus-exporter.tar.gz
        checksum: sha256:abc123...

    - name: Extract nginx-prometheus-exporter
      unarchive:
        src: /tmp/nginx-prometheus-exporter.tar.gz
        dest: /usr/local/bin/
        remote_src: yes

    - name: Create systemd service
      template:
        src: nginx-exporter.service.j2
        dest: /etc/systemd/system/nginx-exporter.service
      notify: Restart nginx-exporter

    - name: Enable stub_status for Prometheus
      template:
        src: stub_status.conf.j2
        dest: /etc/nginx/conf.d/stub_status.conf
      notify: Reload nginx

    - name: Start nginx-exporter
      systemd:
        name: nginx-exporter
        state: started
        enabled: yes
        daemon_reload: yes
```

### Log Shipping (Filebeat)

```yaml
# roles/common/tasks/logging.yml
- name: Configure Filebeat for web server logs
  template:
    src: filebeat-webserver.yml.j2
    dest: /etc/filebeat/inputs.d/webserver.yml
  notify: Restart filebeat

# templates/filebeat-webserver.yml.j2
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
  fields:
    log_type: nginx_access
  fields_under_root: true
  json.keys_under_root: true
  json.add_error_key: true

- type: log
  enabled: true
  paths:
    - /var/log/nginx/error.log
  fields:
    log_type: nginx_error
  fields_under_root: true
```
