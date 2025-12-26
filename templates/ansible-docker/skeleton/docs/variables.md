# Role Variables

This document describes all available variables for the Docker role.

## Docker Installation

| Variable               | Default                       | Description                                           |
| ---------------------- | ----------------------------- | ----------------------------------------------------- |
| `docker_edition`       | `ce`                          | Docker edition: `ce` (Community) or `ee` (Enterprise) |
| `docker_version`       | `""`                          | Specific Docker version to install (empty for latest) |
| `docker_channel`       | `stable`                      | Docker release channel: `stable`, `edge`, or `test`   |
| `docker_package`       | `docker-{{ docker_edition }}` | Docker package name                                   |
| `docker_package_state` | `present`                     | Package state: `present`, `latest`, or `absent`       |

## Docker Compose

| Variable                 | Default | Description                                 |
| ------------------------ | ------- | ------------------------------------------- |
| `docker_compose_install` | `true`  | Whether to install Docker Compose plugin    |
| `docker_compose_version` | `""`    | Specific Compose version (empty for latest) |

## User Management

| Variable       | Default | Description                              |
| -------------- | ------- | ---------------------------------------- |
| `docker_users` | `[]`    | List of users to add to the docker group |

## Docker Daemon Configuration

| Variable                       | Default     | Description                                    |
| ------------------------------ | ----------- | ---------------------------------------------- |
| `docker_daemon_options`        | `{}`        | Docker daemon options (written to daemon.json) |
| `docker_service_enabled`       | `true`      | Enable Docker service on boot                  |
| `docker_service_state`         | `started`   | Docker service state                           |
| `docker_restart_handler_state` | `restarted` | Handler state on config change                 |

## Storage Configuration

| Variable                | Default | Description                                   |
| ----------------------- | ------- | --------------------------------------------- |
| `docker_storage_driver` | `""`    | Storage driver (overlay2, devicemapper, etc.) |
| `docker_data_root`      | `""`    | Custom Docker data directory                  |

## Network Configuration

| Variable                      | Default | Description                        |
| ----------------------------- | ------- | ---------------------------------- |
| `docker_default_address_pool` | `[]`    | Default address pools for networks |
| `docker_dns`                  | `[]`    | Custom DNS servers                 |
| `docker_dns_search`           | `[]`    | DNS search domains                 |

## Registry Configuration

| Variable                     | Default | Description                 |
| ---------------------------- | ------- | --------------------------- |
| `docker_insecure_registries` | `[]`    | List of insecure registries |
| `docker_registry_mirrors`    | `[]`    | Registry mirror URLs        |

## Logging Configuration

| Variable             | Default     | Description            |
| -------------------- | ----------- | ---------------------- |
| `docker_log_driver`  | `json-file` | Default logging driver |
| `docker_log_options` | `{}`        | Logging driver options |

## Example Values

### Minimal Configuration

```yaml
docker_edition: ce
docker_compose_install: true
```

### Production Configuration

```yaml
docker_edition: ce
docker_channel: stable
docker_compose_install: true
docker_users:
  - deploy
  - jenkins
docker_daemon_options:
  storage-driver: overlay2
  log-driver: json-file
  log-opts:
    max-size: '50m'
    max-file: '5'
  default-ulimits:
    nofile:
      Name: nofile
      Hard: 65536
      Soft: 65536
docker_insecure_registries:
  - 'registry.internal:5000'
```

### Development Configuration

```yaml
docker_edition: ce
docker_channel: stable
docker_compose_install: true
docker_users:
  - '{{ ansible_user }}'
docker_daemon_options:
  live-restore: true
  userland-proxy: false
```
