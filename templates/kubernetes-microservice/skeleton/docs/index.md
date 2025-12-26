# ${{ values.name }}

${{ values.description }}

## Overview

A Kubernetes microservice application with complete deployment manifests.

## Quick Start

### Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured
- Docker for building images

### Building

```bash
docker build -t ${{ values.name }} .
```

### Deploying

```bash
kubectl apply -f kubernetes/
```

## Project Structure

```
.
├── src/                 # Application source code
├── kubernetes/
│   ├── deployment.yaml  # Deployment manifest
│   ├── service.yaml     # Service manifest
│   ├── configmap.yaml   # Configuration
│   └── ingress.yaml     # Ingress rules
├── Dockerfile           # Container image
├── docs/                # Documentation
└── catalog-info.yaml    # Backstage metadata
```

## API Specification

See [api-spec.yaml](../api-spec.yaml) for OpenAPI specification.

## Endpoints

| Path | Method | Description |
|------|--------|-------------|
| `/health` | GET | Health check |
| `/ready` | GET | Readiness check |
| `/metrics` | GET | Prometheus metrics |

## Configuration

ConfigMap values:
- `LOG_LEVEL`: Logging level
- `SERVICE_PORT`: Service port

## Scaling

```bash
kubectl scale deployment ${{ values.name }} --replicas=3
```

## Monitoring

Metrics exposed at `/metrics` for Prometheus scraping.
