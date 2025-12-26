# Configuration

This guide covers all configuration options for ${{ values.name }}.

## Configuration File

The main configuration file is `config.yaml`:

```yaml
# config.yaml
app:
  name: ${{ values.name }}
  environment: development
  debug: false

server:
  host: localhost
  port: 3000

logging:
  level: info
  format: json

database:
  host: localhost
  port: 5432
  name: mydb
```

## Environment Variables

Configuration can also be set via environment variables:

| Variable    | Description            | Default       |
| ----------- | ---------------------- | ------------- |
| `APP_ENV`   | Environment (dev/prod) | `development` |
| `APP_PORT`  | Server port            | `3000`        |
| `LOG_LEVEL` | Logging level          | `info`        |
| `DB_HOST`   | Database host          | `localhost`   |

## Configuration Options

### App Settings

| Option            | Type    | Default       | Description       |
| ----------------- | ------- | ------------- | ----------------- |
| `app.name`        | string  | -             | Application name  |
| `app.environment` | string  | `development` | Environment       |
| `app.debug`       | boolean | `false`       | Enable debug mode |

### Server Settings

| Option        | Type    | Default     | Description  |
| ------------- | ------- | ----------- | ------------ |
| `server.host` | string  | `localhost` | Bind address |
| `server.port` | integer | `3000`      | Listen port  |

### Logging Settings

| Option           | Type   | Default | Description   |
| ---------------- | ------ | ------- | ------------- |
| `logging.level`  | string | `info`  | Log level     |
| `logging.format` | string | `json`  | Output format |

## Troubleshooting {#troubleshooting}

### Common Configuration Issues

**Issue: Configuration file not found**

```bash
Error: Could not find config.yaml
```

Solution: Create a config file or specify the path:

```bash
<command> --config /path/to/config.yaml
```

**Issue: Invalid configuration value**

```bash
Error: Invalid value for 'server.port'
```

Solution: Ensure the port is a valid number between 1-65535.

### Validation

Validate your configuration:

```bash
<command> config validate
```

### Debug Mode

Enable debug mode to see detailed configuration:

```bash
APP_DEBUG=true <command> start
```
