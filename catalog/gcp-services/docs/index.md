# Google Cloud Platform Services

Comprehensive Google Cloud Platform services and infrastructure management for the Cloud Sandbox platform.

## Quick Start

```bash
# Install Google Cloud SDK
brew install google-cloud-sdk  # macOS
curl https://sdk.cloud.google.com | bash  # Linux

# Initialize and authenticate
gcloud init
gcloud auth login

# Set default project
gcloud config set project my-project-id

# Verify configuration
gcloud config list
```

## Core Services

| Service | Purpose | Use Case |
|---------|---------|----------|
| **Compute Engine** | Virtual machines | Custom workloads, lift-and-shift |
| **GKE** | Managed Kubernetes | Container orchestration |
| **Cloud Functions** | Serverless compute | Event-driven functions |
| **Cloud Storage** | Object storage | Files, backups, data lakes |
| **Cloud SQL** | Managed databases | PostgreSQL, MySQL, SQL Server |
| **VPC** | Networking | Network isolation, connectivity |
| **IAM** | Identity & access | Authentication, authorization |
| **Deployment Manager** | Infrastructure as Code | Automated provisioning |

## Features

- **Global Network**: Premium tier network with global load balancing
- **AI/ML Platform**: Vertex AI, BigQuery ML, and pre-trained APIs
- **Data Analytics**: BigQuery, Dataflow, Dataproc, and Pub/Sub
- **Security**: IAM, VPC Service Controls, and Security Command Center
- **Cost Optimization**: Committed use discounts, preemptible VMs, and recommendations

## Architecture Overview

```
                         ┌─────────────────┐
                         │   Cloud DNS     │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │  Cloud CDN      │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │  Cloud Load     │
                         │  Balancer       │
                         └────────┬────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │      GKE        │ │ Cloud Functions │ │  Compute        │
     │   Cluster       │ │  / Cloud Run    │ │  Engine         │
     └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │   Cloud SQL     │ │   Memorystore   │ │ Cloud Storage   │
     │                 │ │   (Redis)       │ │                 │
     └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
