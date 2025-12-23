# Usage Guide

## Getting Started

### Prerequisites

1. Google Cloud SDK installed
2. GCP project with billing enabled
3. Appropriate IAM permissions

### Initial Setup

```bash
# Install Google Cloud SDK (macOS)
brew install google-cloud-sdk

# Install Google Cloud SDK (Linux)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize and authenticate
gcloud init
gcloud auth login
gcloud auth application-default login  # For local development
```

## Examples

### Project Management

```bash
# Create project
gcloud projects create my-project-id \
  --name="My Project" \
  --organization=123456789

# Link billing account
gcloud billing projects link my-project-id \
  --billing-account=0X0X0X-0X0X0X-0X0X0X

# Enable APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

# List enabled APIs
gcloud services list --enabled
```

### Compute Engine

```bash
# List available machine types
gcloud compute machine-types list --filter="zone:us-central1-a"

# Create VM instance
gcloud compute instances create my-instance \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=web-server \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install -y nginx'

# SSH to instance
gcloud compute ssh my-instance --zone=us-central1-a

# Stop/Start instance
gcloud compute instances stop my-instance --zone=us-central1-a
gcloud compute instances start my-instance --zone=us-central1-a

# Delete instance
gcloud compute instances delete my-instance --zone=us-central1-a
```

### Cloud Storage

```bash
# Create bucket
gcloud storage buckets create gs://my-unique-bucket \
  --location=us-central1 \
  --uniform-bucket-level-access

# Upload files
gcloud storage cp ./local-file.txt gs://my-bucket/path/
gcloud storage rsync ./local-folder/ gs://my-bucket/folder/

# Download files
gcloud storage cp gs://my-bucket/path/file.txt ./local-file.txt

# List bucket contents
gcloud storage ls gs://my-bucket/ --recursive

# Set lifecycle policy
gcloud storage buckets update gs://my-bucket \
  --lifecycle-file=lifecycle.json

# Enable versioning
gcloud storage buckets update gs://my-bucket --versioning
```

### VPC Networking

```bash
# Create VPC
gcloud compute networks create my-vpc \
  --subnet-mode=custom

# Create subnet
gcloud compute networks subnets create my-subnet \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.0.0/24

# Create Cloud NAT
gcloud compute routers create my-router \
  --network=my-vpc \
  --region=us-central1

gcloud compute routers nats create my-nat \
  --router=my-router \
  --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips

# Create firewall rule
gcloud compute firewall-rules create allow-ssh \
  --network=my-vpc \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0
```

### GKE Cluster

```bash
# Create GKE cluster
gcloud container clusters create my-cluster \
  --zone=us-central1-a \
  --num-nodes=3 \
  --machine-type=e2-medium \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --enable-autorepair \
  --enable-autoupgrade \
  --workload-pool=my-project.svc.id.goog

# Get credentials
gcloud container clusters get-credentials my-cluster \
  --zone=us-central1-a

# Resize cluster
gcloud container clusters resize my-cluster \
  --zone=us-central1-a \
  --num-nodes=5

# Upgrade cluster
gcloud container clusters upgrade my-cluster \
  --zone=us-central1-a \
  --master \
  --cluster-version=1.28
```

### Cloud SQL

```bash
# Create PostgreSQL instance
gcloud sql instances create my-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=SecurePassword123!

# Create database
gcloud sql databases create mydb \
  --instance=my-postgres

# Create user
gcloud sql users create myuser \
  --instance=my-postgres \
  --password=UserPassword123!

# Connect to instance
gcloud sql connect my-postgres --user=postgres

# Create backup
gcloud sql backups create \
  --instance=my-postgres

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --restore-instance=my-postgres
```

### Cloud Functions

```bash
# Deploy HTTP function
gcloud functions deploy my-function \
  --runtime=python311 \
  --trigger-http \
  --entry-point=main \
  --source=./src \
  --allow-unauthenticated

# Deploy Pub/Sub triggered function
gcloud functions deploy process-message \
  --runtime=nodejs18 \
  --trigger-topic=my-topic \
  --entry-point=processMessage

# Invoke function
gcloud functions call my-function \
  --data='{"name": "World"}'

# View logs
gcloud functions logs read my-function
```

### Cloud Run

```bash
# Deploy container
gcloud run deploy my-service \
  --image=gcr.io/my-project/my-image:latest \
  --platform=managed \
  --region=us-central1 \
  --allow-unauthenticated

# Update service
gcloud run services update my-service \
  --region=us-central1 \
  --memory=512Mi \
  --cpu=1

# View logs
gcloud run services logs read my-service --region=us-central1
```

## Terraform Examples

### Basic VPC and GKE

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = var.zone

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Permission denied | Missing IAM role | Check roles with `gcloud projects get-iam-policy` |
| API not enabled | Service not activated | Enable with `gcloud services enable` |
| Quota exceeded | Resource limits reached | Request quota increase in console |
| Region not found | Invalid region specified | Check with `gcloud compute regions list` |

### Debugging Commands

```bash
# Check current configuration
gcloud config list

# Check IAM permissions
gcloud projects get-iam-policy my-project

# Test service account permissions
gcloud auth print-access-token

# View operation status
gcloud compute operations list

# Debug API errors
gcloud logging read "protoPayload.status.code!=0" --limit=10
```

### Cost Management

```bash
# View billing account
gcloud billing accounts list

# Export billing to BigQuery
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Monthly Budget" \
  --budget-amount=1000USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9

# Find unused resources
gcloud compute addresses list --filter="status:RESERVED"
gcloud compute disks list --filter="NOT users:*"
```
