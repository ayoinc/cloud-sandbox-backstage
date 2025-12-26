# ${{ values.name }}

${{ values.description }}

## Overview

Kubernetes microservice with container deployment, health checks, and observability.

## Getting Started

```bash
# Build image
docker build -t ${{ values.name }} .

# Run locally
docker run -p 8080:8080 ${{ values.name }}
```

## Kubernetes Deployment

```bash
kubectl apply -f k8s/
```

## Project Structure

```
├── Dockerfile          # Container definition
├── k8s/                # Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── src/                # Application source
└── api-spec.yaml       # OpenAPI specification
```

## Endpoints

| Path | Description |
|------|-------------|
| `/health` | Health check |
| `/ready` | Readiness probe |
| `/metrics` | Prometheus metrics |

## Configuration

Environment variables via ConfigMap or Secrets.

## License

MIT

## Author

${{ values.owner }}
