# Usage

## Basic Installation

```yaml
- name: Install Nginx
  hosts: webservers
  become: true
  roles:
    - ${{ values.name }}
```

## Serve a Static Site

```yaml
- name: Serve a static site
  hosts: webservers
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_vhosts:
          - server_name: example.com www.example.com
            default_server: true
            root: /var/www/example
            index: index.html
```

## Reverse Proxy with an Upstream

```yaml
- name: Proxy to application servers
  hosts: webservers
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        nginx_upstreams:
          - name: backend
            strategy: least_conn
            servers:
              - 10.0.0.11:8080
              - 10.0.0.12:8080
        nginx_vhosts:
          - server_name: app.example.com
            extra_parameters: |
              location /api {
                  proxy_pass http://backend;
              }
```

## Testing the Role

```bash
pip install ansible molecule "molecule-plugins[docker]"
molecule test

# Another distribution
MOLECULE_DISTRO=rockylinux9 molecule test
```
