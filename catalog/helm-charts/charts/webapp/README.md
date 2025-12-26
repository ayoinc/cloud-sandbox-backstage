# webapp

A production-ready Helm chart for deploying web applications to Kubernetes.

## Features

- Security-hardened with Pod Security Standards (restricted)
- Horizontal Pod Autoscaling (HPA) support
- Pod Disruption Budget (PDB) for high availability
- Ingress with TLS support
- Prometheus metrics and ServiceMonitor
- Network Policies for traffic control
- Database migration hooks
- Optional Redis and PostgreSQL subcharts

## Installation

```bash
# Add dependencies
helm dependency update

# Install
helm install my-app ./webapp

# Install with custom values
helm install my-app ./webapp -f my-values.yaml
```

## Quick Start

```bash
# Minimal installation
helm install my-app ./webapp \
  --set image.repository=myregistry/myapp \
  --set image.tag=1.0.0

# With ingress
helm install my-app ./webapp \
  --set image.repository=myregistry/myapp \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix

# With autoscaling
helm install my-app ./webapp \
  --set image.repository=myregistry/myapp \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10
```

## Values

| Key                              | Type   | Default            | Description                              |
| -------------------------------- | ------ | ------------------ | ---------------------------------------- |
| replicaCount                     | int    | `2`                | Number of replicas                       |
| image.repository                 | string | `"company/webapp"` | Container image repository               |
| image.pullPolicy                 | string | `"IfNotPresent"`   | Image pull policy                        |
| image.tag                        | string | `""`               | Image tag (defaults to chart appVersion) |
| service.type                     | string | `"ClusterIP"`      | Service type                             |
| service.port                     | int    | `80`               | Service port                             |
| service.targetPort               | int    | `8080`             | Target container port                    |
| ingress.enabled                  | bool   | `false`            | Enable ingress                           |
| ingress.className                | string | `"nginx"`          | Ingress class name                       |
| resources.limits.cpu             | string | `"500m"`           | CPU limit                                |
| resources.limits.memory          | string | `"512Mi"`          | Memory limit                             |
| resources.requests.cpu           | string | `"100m"`           | CPU request                              |
| resources.requests.memory        | string | `"128Mi"`          | Memory request                           |
| autoscaling.enabled              | bool   | `false`            | Enable HPA                               |
| autoscaling.minReplicas          | int    | `2`                | Minimum replicas                         |
| autoscaling.maxReplicas          | int    | `10`               | Maximum replicas                         |
| podDisruptionBudget.enabled      | bool   | `true`             | Enable PDB                               |
| podDisruptionBudget.minAvailable | int    | `1`                | Minimum available pods                   |
| metrics.enabled                  | bool   | `false`            | Enable metrics port                      |
| metrics.serviceMonitor.enabled   | bool   | `false`            | Enable ServiceMonitor                    |
| networkPolicy.enabled            | bool   | `false`            | Enable NetworkPolicy                     |

See [values.yaml](./values.yaml) for all available options.

## Security

This chart follows Kubernetes Pod Security Standards (restricted):

- Runs as non-root user (UID 1000)
- Read-only root filesystem
- No privilege escalation
- All capabilities dropped
- Seccomp profile enabled

## Testing

```bash
# Run Helm tests
helm test my-app

# Lint chart
helm lint .

# Template and validate
helm template test . | kubectl apply --dry-run=server -f -
```

## Upgrading

```bash
# Upgrade release
helm upgrade my-app ./webapp -f my-values.yaml

# Rollback if needed
helm rollback my-app 1
```

## Dependencies

| Repository                         | Name       | Version |
| ---------------------------------- | ---------- | ------- |
| https://charts.bitnami.com/bitnami | redis      | 18.x.x  |
| https://charts.bitnami.com/bitnami | postgresql | 14.x.x  |

Enable dependencies in values:

```yaml
redis:
  enabled: true
  architecture: standalone

postgresql:
  enabled: true
  auth:
    database: myapp
```
