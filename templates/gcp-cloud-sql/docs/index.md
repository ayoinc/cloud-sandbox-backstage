# GCP Cloud SQL Template

This template creates a managed Cloud SQL database instance on Google Cloud Platform with Terraform.

## Overview

Cloud SQL is a fully managed relational database service that supports MySQL, PostgreSQL, and SQL Server. This template provisions:

- Cloud SQL instance with configurable resources
- Database and user with secure password
- Automated backups with point-in-time recovery
- Private networking (optional)
- High availability with regional failover
- Query Insights for performance monitoring

## Features

### Managed Database Service

- Fully managed infrastructure
- Automatic security patching
- Built-in replication and failover
- Integrated backup and recovery

### Supported Databases

| Database   | Version | Features                       |
| ---------- | ------- | ------------------------------ |
| PostgreSQL | 15      | PITR, Query Insights, pgVector |
| MySQL      | 8.0     | Read replicas, Binary logging  |
| SQL Server | 2019    | AD integration, Windows auth   |

### Configuration Options

| Parameter           | Description                 | Default     |
| ------------------- | --------------------------- | ----------- |
| `database_version`  | Database engine and version | POSTGRES_15 |
| `tier`              | Machine type                | db-f1-micro |
| `disk_size`         | Storage size in GB          | 10          |
| `availability_type` | ZONAL or REGIONAL (HA)      | ZONAL       |
| `enable_backups`    | Automated backups           | true        |
| `backup_retention`  | Days to retain backups      | 7           |
| `enable_private_ip` | Private networking          | false       |

### Security

- SSL/TLS encryption in transit
- Encryption at rest (Google-managed keys)
- IAM database authentication
- VPC private connectivity
- Password stored in Secret Manager

## Getting Started

### Prerequisites

- GCP project with billing enabled
- Cloud SQL Admin API enabled
- Terraform >= 1.5
- Service Networking API (for private IP)

### Deployment

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Review the plan**

   ```bash
   terraform plan -var-file=environments/dev.tfvars
   ```

3. **Apply the configuration**

   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

### Connecting to the Database

Using Cloud SQL Proxy:

```bash
# Get connection name
CONNECTION=$(terraform output -raw connection_name)

# Start proxy
cloud-sql-proxy $CONNECTION --port=5432

# Connect
psql -h localhost -p 5432 -U app_user -d mydb
```

## Architecture

```d2
direction: right

title: Cloud SQL Architecture {
  near: top-center
}

# External clients
clients: Application Clients {
  shape: cloud
  style.fill: "#e3f2fd"
}

# Cloud SQL Proxy
proxy: Cloud SQL Proxy {
  shape: hexagon
  style.fill: "#fff3e0"
}

# Cloud SQL Instance
cloud_sql: Cloud SQL Instance {
  style.fill: "#c8e6c9"

  primary: Primary Instance {
    style.fill: "#a5d6a7"
  }

  standby: Standby (HA) {
    style.fill: "#81c784"
    style.stroke-dash: 3
  }
}

# Storage
storage: Persistent Disk {
  shape: cylinder
  style.fill: "#e1bee7"

  data: Database Data
  logs: Transaction Logs
}

# Backups
backups: Automated Backups {
  shape: cylinder
  style.fill: "#b3e5fc"
}

# Secret Manager
secrets: Secret Manager {
  shape: document
  style.fill: "#ffccbc"
  label: "Credentials"
}

# VPC
vpc: VPC Network {
  shape: rectangle
  style.fill: "#fff9c4"
  style.stroke-dash: 3
}

# Connections
clients -> proxy: "Encrypted"
proxy -> cloud_sql.primary: "Private/Public IP"
cloud_sql.primary -> cloud_sql.standby: "Sync Replication"
cloud_sql.primary -> storage
cloud_sql.primary -> backups: "Daily"
cloud_sql -> secrets: "Store Password"
cloud_sql -> vpc: "Private Service Connection"
```

## High Availability

With `availability_type = "REGIONAL"`:

```d2
direction: down

zone_a: Zone A (Primary) {
  style.fill: "#c8e6c9"
  primary: Primary Instance
  disk_a: Persistent Disk
  primary -> disk_a
}

zone_b: Zone B (Standby) {
  style.fill: "#fff3e0"
  standby: Standby Instance
  disk_b: Persistent Disk
  standby -> disk_b
}

zone_a.primary -> zone_b.standby: "Synchronous Replication" {
  style.stroke: "#4caf50"
  style.stroke-width: 2
}

failover: Automatic Failover {
  shape: diamond
  style.fill: "#ffcdd2"
}

zone_a -> failover: "On failure"
failover -> zone_b: "Promote standby"
```

## Backup and Recovery

The template configures:

- **Automated Backups**: Daily backups during maintenance window
- **Point-in-Time Recovery**: Restore to any second (PostgreSQL)
- **On-Demand Backups**: Manual backups for critical changes
- **Cross-Region Backups**: Optional for disaster recovery

```d2
direction: right

instance: Cloud SQL Instance {
  style.fill: "#c8e6c9"
}

daily: Daily Backup {
  shape: cylinder
  style.fill: "#b3e5fc"
}

pitr: Transaction Logs {
  shape: document
  style.fill: "#fff3e0"
}

restore: Restored Instance {
  shape: rectangle
  style.fill: "#c5cae9"
  style.stroke-dash: 3
}

instance -> daily: "Daily at 03:00 UTC"
instance -> pitr: "Continuous"
daily -> restore: "Full restore"
pitr -> restore: "Point-in-time"
```

## Cost Optimization

- Use `db-f1-micro` or `db-g1-small` for development
- Enable `activation_policy = "ON_DEMAND"` for infrequent use
- Use `ZONAL` availability for non-production
- Right-size based on actual usage metrics

## Monitoring

The template enables:

- Cloud Monitoring metrics
- Query Insights for slow query analysis
- Cloud Logging for audit logs
- Alerting on connection failures

## Related Templates

- [GCP Cloud Run](../gcp-cloud-run) - Serverless application to connect to Cloud SQL
- [GCP VPC Network](../gcp-vpc) - Custom networking for private connectivity
- [GCP GKE Cluster](../gcp-gke) - Kubernetes workloads with Cloud SQL
