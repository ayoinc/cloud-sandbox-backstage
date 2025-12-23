# GCP Cloud Run Service Template

This template creates a serverless Cloud Run service on Google Cloud Platform with Terraform.

## Overview

Cloud Run is a fully managed compute platform that automatically scales your stateless containers. This template provisions:

- Cloud Run service with configurable resources
- Auto-scaling based on traffic
- Custom domain support (optional)
- VPC connector for private networking
- Cloud IAM for authentication

## Features

### Serverless Container Deployment
- Zero infrastructure management
- Scale to zero when not in use
- Automatic scaling based on concurrent requests

### Configuration Options
| Parameter | Description | Default |
|-----------|-------------|---------|
| `memory` | Container memory allocation | 512Mi |
| `cpu` | CPU allocation | 1 |
| `maxInstances` | Maximum scaling instances | 10 |
| `allowUnauthenticated` | Public access control | false |

### Security
- IAM-based authentication by default
- HTTPS endpoints with managed certificates
- VPC egress controls

## Getting Started

### Prerequisites
- GCP project with billing enabled
- Cloud Run API enabled
- Terraform >= 1.0

### Deployment

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Review the plan**
   ```bash
   terraform plan
   ```

3. **Apply the configuration**
   ```bash
   terraform apply
   ```

### Testing the Service

After deployment, test your service:

```bash
# Get the service URL
gcloud run services describe SERVICE_NAME --region=REGION --format='value(status.url)'

# Test the endpoint
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" SERVICE_URL
```

## Architecture

```
                    ┌─────────────────┐
                    │   Cloud Run     │
    Internet ──────►│    Service      │──────► VPC (optional)
                    │                 │
                    └─────────────────┘
                           │
                           ▼
                    ┌─────────────────┐
                    │  Cloud Logging  │
                    │  Cloud Monitor  │
                    └─────────────────┘
```

## Cost Optimization

- Pay only for resources used during request processing
- Scale to zero eliminates idle costs
- Use committed use discounts for predictable workloads

## Monitoring

The template includes integration with:
- Cloud Logging for application logs
- Cloud Monitoring for metrics and alerts
- Cloud Trace for distributed tracing

## Related Templates

- [GCP GKE Cluster](../gcp-gke) - For workloads requiring Kubernetes
- [GCP VPC Network](../gcp-vpc) - For custom networking requirements
