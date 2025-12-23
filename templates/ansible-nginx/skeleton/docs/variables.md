# Role Variables

## Nginx Core Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_worker_processes` | `auto` | Number of worker processes |
| `nginx_worker_connections` | `1024` | Max connections per worker |
| `nginx_multi_accept` | `on` | Accept multiple connections |
| `nginx_sendfile` | `on` | Use sendfile |
| `nginx_tcp_nopush` | `on` | Enable TCP_NOPUSH |
| `nginx_tcp_nodelay` | `on` | Enable TCP_NODELAY |
| `nginx_keepalive_timeout` | `65` | Keep-alive timeout |
| `nginx_types_hash_max_size` | `2048` | Types hash max size |

## SSL/TLS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_ssl_protocols` | `TLSv1.2 TLSv1.3` | SSL protocols |
| `nginx_ssl_ciphers` | See defaults | SSL cipher suite |
| `nginx_ssl_prefer_server_ciphers` | `on` | Prefer server ciphers |
| `nginx_ssl_session_cache` | `shared:SSL:10m` | SSL session cache |
| `nginx_ssl_session_timeout` | `1d` | Session timeout |

## Gzip Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_gzip` | `on` | Enable gzip |
| `nginx_gzip_vary` | `on` | Enable Vary header |
| `nginx_gzip_proxied` | `any` | Gzip for proxied requests |
| `nginx_gzip_comp_level` | `6` | Compression level (1-9) |
| `nginx_gzip_types` | See defaults | MIME types to compress |

## Virtual Hosts

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_vhosts` | `[]` | List of virtual hosts |
| `nginx_remove_default_vhost` | `true` | Remove default vhost |

### Virtual Host Structure

```yaml
nginx_vhosts:
  - server_name: example.com www.example.com
    root: /var/www/example
    index: index.html index.htm
    listen: 80
    ssl_certificate: /path/to/cert.pem
    ssl_certificate_key: /path/to/key.pem
    extra_parameters: |
      location /api {
        proxy_pass http://backend;
      }
```

## Upstream Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_upstreams` | `[]` | Upstream server groups |

### Upstream Structure

```yaml
nginx_upstreams:
  - name: backend
    servers:
      - 127.0.0.1:8080 weight=3
      - 127.0.0.1:8081
    strategy: least_conn
```
