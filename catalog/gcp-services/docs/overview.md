# Overview

## Architecture

Google Cloud Platform Services provides a comprehensive framework for managing GCP cloud infrastructure using Infrastructure as Code (IaC) principles.

### Resource Hierarchy

```d2
direction: down

title: GCP Organization {
  shape: text
  near: top-center
  style.font-size: 24
}

org: Organization {
  style.fill: "#E3F2FD"
  
  folders: Folders {
    style.fill: "#BBDEFB"
    
    prod: Production Folder {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
    }
    dev: Development Folder {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
    }
    sandbox: Sandbox Folder {
      shape: rectangle
      style.fill: "#2196F3"
      style.font-color: white
    }
  }
  
  projects: Projects {
    style.fill: "#E8F5E9"
    
    prod_proj: Prod Projects {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
    }
    dev_proj: Dev Projects {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
    }
    sandbox_proj: Sandbox Projects {
      shape: rectangle
      style.fill: "#4CAF50"
      style.font-color: white
    }
  }
  
  folders.prod -> projects.prod_proj
  folders.dev -> projects.dev_proj
  folders.sandbox -> projects.sandbox_proj
}
```

## Core Components

### Compute Services

| Service | Description | Best For |
|---------|-------------|----------|
| **Compute Engine** | Virtual machines | Custom workloads, Windows |
| **GKE** | Managed Kubernetes | Container orchestration |
| **Cloud Run** | Serverless containers | Stateless HTTP services |
| **Cloud Functions** | Serverless functions | Event-driven compute |
| **App Engine** | PaaS platform | Web applications |
| **Batch** | Batch job scheduling | HPC, data processing |

### Networking

| Component | Purpose |
|-----------|---------|
| **VPC** | Virtual private cloud network |
| **Subnets** | Regional network segments |
| **Firewall Rules** | Network traffic control |
| **Cloud NAT** | Outbound NAT for private instances |
| **Cloud VPN** | Site-to-site VPN connections |
| **Cloud Interconnect** | Dedicated private connections |
| **Private Google Access** | Private access to Google APIs |

### Storage Services

| Service | Type | Use Case |
|---------|------|----------|
| **Cloud Storage** | Object storage | Unstructured data, backups |
| **Persistent Disk** | Block storage | VM boot/data disks |
| **Filestore** | NFS file storage | Shared file systems |
| **Cloud Storage Archive** | Cold storage | Long-term archival |

### Database Services

| Service | Engine | Use Case |
|---------|--------|----------|
| **Cloud SQL** | PostgreSQL, MySQL, SQL Server | Managed relational |
| **Cloud Spanner** | Distributed SQL | Global scale OLTP |
| **Firestore** | Document NoSQL | Mobile, web apps |
| **Bigtable** | Wide-column NoSQL | IoT, time-series |
| **Memorystore** | Redis, Memcached | Caching |
| **AlloyDB** | PostgreSQL compatible | High-performance OLTP |

### Data Analytics

| Service | Purpose |
|---------|---------|
| **BigQuery** | Serverless data warehouse |
| **Dataflow** | Stream/batch data processing |
| **Dataproc** | Managed Spark/Hadoop |
| **Pub/Sub** | Messaging and streaming |
| **Data Fusion** | Data integration |
| **Composer** | Managed Apache Airflow |

## Configuration

### Environment Variables

```bash
# Service Account Authentication
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
export GOOGLE_CLOUD_PROJECT="my-project-id"

# Alternative: User credentials (development only)
gcloud auth application-default login
```

### gcloud CLI Configuration

```bash
# Initialize gcloud
gcloud init

# Authenticate
gcloud auth login

# Set project
gcloud config set project my-project-id

# Set compute region/zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# View configuration
gcloud config list
```

### IAM Best Practices

1. **Use service accounts** for applications, not user accounts
2. **Apply least privilege** using predefined roles when possible
3. **Use Workload Identity** for GKE workloads
4. **Implement organization policies** for guardrails
5. **Enable VPC Service Controls** for sensitive data
6. **Audit with Cloud Audit Logs** and Security Command Center

### Resource Labeling Strategy

```yaml
labels:
  environment: production|staging|development
  project: project-name
  team: team-name
  cost-center: cost-center-id
  managed-by: terraform|deployment-manager|manual
```

## Security Configuration

### VPC Firewall Rules

```bash
# Create firewall rule
gcloud compute firewall-rules create allow-https \
  --network=my-vpc \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=web-server \
  --description="Allow HTTPS traffic"

# Create internal-only rule
gcloud compute firewall-rules create allow-internal \
  --network=my-vpc \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/8
```

### Service Account Security

```bash
# Create service account
gcloud iam service-accounts create my-sa \
  --display-name="My Service Account"

# Grant minimal permissions
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:my-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Create key (for external use only)
gcloud iam service-accounts keys create key.json \
  --iam-account=my-sa@my-project.iam.gserviceaccount.com
```

## Monitoring

### Cloud Monitoring Metrics

Key metrics to monitor:

| Service | Metric | Threshold |
|---------|--------|-----------|
| Compute Engine | CPU utilization | > 80% |
| Cloud SQL | Disk utilization | > 80% |
| Cloud Storage | Request count | Monitor trend |
| GKE | Node CPU/memory | > 80% |
| Cloud Functions | Execution time | > timeout |

### Alerting Policies

```bash
# Create notification channel
gcloud beta monitoring channels create \
  --display-name="Email Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@example.com

# Create alert policy (via YAML)
gcloud alpha monitoring policies create --policy-from-file=policy.yaml
```

### Cloud Logging

```bash
# View logs
gcloud logging read "resource.type=gce_instance" --limit=10

# Create log sink
gcloud logging sinks create my-sink \
  storage.googleapis.com/my-log-bucket \
  --log-filter='resource.type="gce_instance"'

# Create log-based metric
gcloud logging metrics create error-count \
  --description="Count of errors" \
  --log-filter='severity>=ERROR'
```
