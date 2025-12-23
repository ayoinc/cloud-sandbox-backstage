# Kubernetes Microservice Template

This template creates a production-ready microservice with Kubernetes deployment, CI/CD pipelines, monitoring, and security best practices.

## Overview

Build and deploy containerized microservices to Kubernetes with built-in observability, security scanning, and deployment automation across multiple cloud providers.

## Features

### Multi-Language Support
- **Node.js** (Express)
- **Python** (FastAPI)
- **Java** (Spring Boot)
- **Go** (Gin)
- **.NET Core**

### Architecture Patterns
- REST API Service
- GraphQL API Service
- gRPC Service
- Event-Driven Service
- Batch Processor

### Database Integration
- PostgreSQL
- MySQL
- MongoDB
- Redis
- Elasticsearch

### Message Queues
- RabbitMQ
- Apache Kafka
- Redis Pub/Sub
- AWS SQS

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `language` | Programming language | nodejs |
| `architecture_type` | Service architecture | rest-api |
| `database_type` | Database technology | postgresql |
| `cloud_provider` | Target cloud | aws |
| `deployment_strategy` | K8s deployment strategy | rolling-update |

## Getting Started

### Prerequisites
- Kubernetes cluster (EKS, AKS, GKE, or on-premise)
- kubectl configured
- Docker installed
- CI/CD platform access

### Local Development

1. **Clone and install dependencies**
   ```bash
   git clone <repository-url>
   cd <service-name>
   npm install  # or pip install, mvn install, etc.
   ```

2. **Start local services**
   ```bash
   docker-compose up -d
   ```

3. **Run the application**
   ```bash
   npm run dev
   ```

### Kubernetes Deployment

1. **Build and push container**
   ```bash
   docker build -t your-registry/service-name:tag .
   docker push your-registry/service-name:tag
   ```

2. **Deploy to Kubernetes**
   ```bash
   kubectl apply -f k8s/
   ```

3. **Verify deployment**
   ```bash
   kubectl get pods -l app=service-name
   kubectl get svc service-name
   ```

## Architecture

```
                         ┌─────────────────────────────────────┐
                         │         Kubernetes Cluster          │
                         │                                     │
   ┌──────────┐         │  ┌─────────────────────────────┐   │
   │ Ingress  │─────────┼──│         Service             │   │
   │Controller│         │  │    (ClusterIP/LoadBalancer) │   │
   └──────────┘         │  └─────────────────────────────┘   │
                         │              │                     │
                         │  ┌───────────┴───────────┐        │
                         │  │                       │        │
                         │  ▼                       ▼        │
                         │ ┌───┐                  ┌───┐      │
                         │ │Pod│                  │Pod│      │
                         │ │ 1 │                  │ 2 │      │
                         │ └───┘                  └───┘      │
                         │                                    │
                         │  ┌─────────────────────────────┐  │
                         │  │   HPA (Horizontal Pod        │  │
                         │  │   Autoscaler)                │  │
                         │  └─────────────────────────────┘  │
                         └─────────────────────────────────────┘
```

## Kubernetes Resources

### Deployment Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-name
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: service-name
```

## Observability

### Monitoring Stack Options
- **Prometheus + Grafana** - Cloud-native metrics
- **Elastic Stack (ELK)** - Centralized logging
- **Datadog** - Full-stack observability
- **New Relic** - APM and infrastructure

### Distributed Tracing
OpenTelemetry integration for end-to-end request tracing across services.

### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Security

### Container Security
- Non-root container execution
- Read-only root filesystem
- Resource limits enforced
- Security context constraints

### CI/CD Security Scanning
- **Trivy** - Container vulnerability scanning
- **Snyk** - Dependency scanning
- **OWASP** - Security testing

### Policy Enforcement
OPA/Gatekeeper policies for Kubernetes resource compliance.

## CI/CD Platforms

- GitHub Actions
- GitLab CI/CD
- Jenkins
- Azure DevOps
- Tekton Pipelines

## Deployment Strategies

### Rolling Update
Zero-downtime deployment with gradual pod replacement.

### Blue-Green
Run two identical environments, switch traffic instantly.

### Canary
Gradual traffic shifting to new version for safe rollouts.

## Related Templates

- [Python API](../python-api) - Python-specific API template
- [React Frontend](../react-frontend) - Frontend application template
- [Terraform Infrastructure](../terraform-infrastructure) - Infrastructure provisioning
