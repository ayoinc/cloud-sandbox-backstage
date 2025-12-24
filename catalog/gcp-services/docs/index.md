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

```d2
direction: down

title: GCP Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

dns: Cloud DNS {
  shape: rectangle
  style.fill: "#2196F3"
  style.font-color: white
}

cdn: Cloud CDN {
  shape: hexagon
  style.fill: "#64B5F6"
  style.font-color: white
}

lb: Cloud Load Balancer {
  shape: hexagon
  style.fill: "#64B5F6"
  style.font-color: white
}

compute: Compute Tier {
  style.fill: "#E8F5E9"
  
  gke: GKE Cluster {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  functions: Cloud Functions\n/ Cloud Run {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  gce: Compute Engine {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

data: Data Tier {
  style.fill: "#FFF3E0"
  
  sql: Cloud SQL {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
  redis: Memorystore\n(Redis) {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
  storage: Cloud Storage {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
}

dns -> cdn
cdn -> lb
lb -> compute.gke
lb -> compute.functions
lb -> compute.gce
compute.gke -> data
compute.functions -> data
compute.gce -> data
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
