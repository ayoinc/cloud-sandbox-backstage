# ${{ values.name }}

${{ values.description }}

## Overview

This Cloud SQL instance provides a fully-managed relational database on Google Cloud Platform with:

- **${{ values.database_version }}** database engine with automatic updates
- High availability with regional failover (configurable per environment)
- Automated backups with point-in-time recovery
- Private networking via VPC peering for secure access
- Cloud SQL Proxy support for secure connections
- Query Insights for performance monitoring
- Secret Manager integration for credential storage

```d2
direction: right

title: {
  label: GCP Cloud SQL Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

gke: GKE / Compute Engine {
  shape: hexagon
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  
  app: Application {
    style.fill: "#BBDEFB"
  }
  
  proxy: Cloud SQL Proxy {
    shape: hexagon
    style.fill: "#90CAF9"
  }
  
  app -> proxy: "localhost:5432"
}

vpc: VPC Network {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  
  peering: Private Service\nConnection {
    shape: parallelogram
    style.fill: "#E1BEE7"
  }
}

cloudsql: Cloud SQL {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  
  primary: ${{ values.name }}-${{ values.environment }} {
    style.fill: "#C8E6C9"
    
    db: ${{ values.database_version }} {
      shape: cylinder
      style.fill: "#A5D6A7"
    }
  }
  
  replica: Read Replica {
    style.fill: "#DCEDC8"
    style.stroke: "#689F38"
    style.stroke-dash: 3
    
    db_replica: Replica DB {
      shape: cylinder
      style.fill: "#C5E1A5"
    }
  }
  
  primary -> replica: "Async\nReplication" {
    style.stroke-dash: 3
  }
}

storage: Persistent Storage {
  style.fill: "#FFF3E0"
  style.stroke: "#F57C00"
  
  disk: ${{ values.disk_type }} {
    shape: cylinder
    style.fill: "#FFE0B2"
  }
  
  backups: Automated Backups {
    shape: cylinder
    style.fill: "#FFCC80"
  }
}

secrets: Secret Manager {
  shape: document
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

monitoring: Cloud Monitoring {
  shape: oval
  style.fill: "#E0F2F1"
  style.stroke: "#00796B"
}

gke.proxy -> vpc.peering: "Private IP"
vpc.peering -> cloudsql.primary
cloudsql.primary -> storage.disk
cloudsql.primary -> storage.backups: "Daily"
cloudsql.primary -> secrets: "Credentials"
cloudsql.primary -> monitoring: "Metrics"
```

## Configuration Summary

| Setting              | Value                                                     |
| -------------------- | --------------------------------------------------------- |
| **Instance Name**    | `${{ values.name }}-${{ values.environment }}`            |
| **Database Version** | `${{ values.database_version }}`                          |
| **Region**           | `${{ values.region }}`                                    |
| **GCP Project**      | `${{ values.gcpProject }}`                                |
| **Machine Tier**     | `${{ values.tier }}`                                      |
| **Availability**     | `${{ values.availability_type }}`                         |
| **Disk Size**        | `${{ values.disk_size }} GB`                              |
| **Disk Type**        | `${{ values.disk_type }}`                                 |
| **Private IP**       | `${{ values.enable_private_ip }}`                         |
| **Backups Enabled**  | `${{ values.enable_backups }}`                            |
| **Backup Retention** | `${{ values.backup_retention_days }} days`                |
| **Owner**            | `${{ values.owner }}`                                     |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Security Scanning**: tfsec, Checkov for vulnerability detection
- **Terraform Tests**: Native Terraform test framework
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: Scheduled checks for configuration drift

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov"
}

test: Test {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Terraform\nTests"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nReview Changes"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

apply: Apply {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Deploy\nInfrastructure"
}

pr -> validate -> security -> test -> plan -> review -> apply
```

### Environment Deployment Strategy

| Environment | Trigger                    | Approval Required | Protection Rules          |
| ----------- | -------------------------- | ----------------- | ------------------------- |
| `dev`       | Push to `main`, Manual     | No                | None                      |
| `staging`   | Manual workflow dispatch   | Optional          | Reviewers (optional)      |
| `prod`      | Manual workflow dispatch   | Yes               | Reviewers, Branch: `main` |

---

## Prerequisites

### 1. GCP Project Setup

#### Enable Required APIs

```bash
# Enable Cloud SQL Admin API
gcloud services enable sqladmin.googleapis.com --project=${{ values.gcpProject }}

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com --project=${{ values.gcpProject }}

# Enable Service Networking API (for private IP)
gcloud services enable servicenetworking.googleapis.com --project=${{ values.gcpProject }}

# Enable Compute Engine API
gcloud services enable compute.googleapis.com --project=${{ values.gcpProject }}

# Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com --project=${{ values.gcpProject }}
```

#### Create Workload Identity Pool for GitHub Actions

GitHub Actions uses Workload Identity Federation for secure, keyless authentication with GCP.

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

#### Create Service Account for Terraform

```bash
# Create service account
gcloud iam service-accounts create terraform-cloud-sql \
  --project="${{ values.gcpProject }}" \
  --display-name="Terraform Cloud SQL Service Account"

# Get the Workload Identity Pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe github-pool \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --format="value(name)")

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com \
  --project="${{ values.gcpProject }}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/YOUR_ORG/YOUR_REPO"
```

#### Required IAM Permissions

Grant the service account these roles:

```bash
# Cloud SQL Admin
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"

# Secret Manager Admin
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

# Compute Network Admin (for private IP)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

# Service Networking Admin (for private service connection)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/servicenetworking.networksAdmin"

# Storage Admin (for Terraform state)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

#### Create Terraform State Bucket

```bash
# Create GCS bucket for Terraform state
gcloud storage buckets create gs://your-terraform-state-bucket \
  --project=${{ values.gcpProject }} \
  --location=${{ values.region }} \
  --uniform-bucket-level-access

# Enable versioning
gcloud storage buckets update gs://your-terraform-state-bucket \
  --versioning
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                             | Description                                               | Example                                                                                                    |
| ---------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER`   | Full identifier of the Workload Identity Provider         | `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`          |
| `GCP_SERVICE_ACCOUNT`              | Service account email for Terraform                       | `terraform-cloud-sql@${{ values.gcpProject }}.iam.gserviceaccount.com`                                     |
| `GCP_PROJECT_ID`                   | GCP Project ID                                            | `${{ values.gcpProject }}`                                                                                 |
| `GCP_TERRAFORM_STATE_BUCKET`       | GCS bucket name for Terraform state                       | `your-terraform-state-bucket`                                                                              |
| `INFRACOST_API_KEY`                | API key for cost estimation (optional)                    | `ico-xxxxxxxx`                                                                                             |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment   | Protection Rules                                     | Reviewers                |
| ------------- | ---------------------------------------------------- | ------------------------ |
| `dev`         | None                                                 | -                        |
| `dev-plan`    | None                                                 | -                        |
| `staging`     | Required reviewers (optional)                        | Team leads               |
| `prod`        | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |
| `*-destroy`   | Required reviewers                                   | Infrastructure team      |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Authenticate with GCP
gcloud auth application-default login

# Set project
gcloud config set project ${{ values.gcpProject }}

# Initialize Terraform
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="prefix=${{ values.name }}/dev"

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars
```

### Connecting to the Database

#### Using Cloud SQL Proxy (Recommended)

The Cloud SQL Proxy provides secure access without exposing the database to the public internet.

```bash
# Install Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.arm64
chmod +x cloud-sql-proxy

# Get connection name from Terraform output
CONNECTION_NAME=$(terraform output -raw connection_name)

# Start proxy (PostgreSQL default port)
./cloud-sql-proxy $CONNECTION_NAME --port=5432

# In another terminal, connect using psql
psql -h localhost -p 5432 -U app_user -d ${{ values.name | replace("-", "_") }}
```

#### Using Private IP (From GKE/GCE)

If your application runs in the same VPC:

```bash
# Get private IP from Terraform output
PRIVATE_IP=$(terraform output -raw private_ip_address)

# Connect directly (PostgreSQL)
psql -h $PRIVATE_IP -U app_user -d ${{ values.name | replace("-", "_") }}
```

#### Getting Database Credentials

```bash
# From Secret Manager (recommended)
gcloud secrets versions access latest \
  --secret="${{ values.name }}-${{ values.environment }}-db-password" \
  --project=${{ values.gcpProject }}

# From Terraform output (local development only)
terraform output -raw user_password
```

### Running the Pipeline

#### Automatic Triggers

| Trigger                     | Actions                                          |
| --------------------------- | ------------------------------------------------ |
| Pull Request to `main`      | Validate, Security Scan, Test, Plan              |
| Push to `main`              | Validate, Security Scan, Test, Plan, Apply (dev) |
| Push to `develop`           | Validate, Security Scan, Test, Plan              |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **Terraform CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## High Availability Configuration

### Availability Types

| Type       | Description                                  | Use Case              | SLA      |
| ---------- | -------------------------------------------- | --------------------- | -------- |
| `ZONAL`    | Single zone deployment                       | Development, Testing  | 99.95%   |
| `REGIONAL` | Automatic failover to standby in another AZ  | Production, Staging   | 99.99%   |

### Enabling High Availability

High availability is controlled by the `availability_type` variable in your tfvars:

```hcl
# environments/prod.tfvars
availability_type = "REGIONAL"  # Enables automatic failover
```

### Failover Architecture

```d2
direction: right

region: ${{ values.region }} {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  
  zone_a: Zone A {
    style.fill: "#E8F5E9"
    
    primary: Primary Instance {
      style.fill: "#C8E6C9"
      style.stroke: "#388E3C"
    }
  }
  
  zone_b: Zone B {
    style.fill: "#FFF3E0"
    
    standby: Standby Instance {
      style.fill: "#FFE0B2"
      style.stroke: "#F57C00"
      style.stroke-dash: 3
    }
  }
  
  zone_a.primary -> zone_b.standby: "Synchronous\nReplication" {
    style.stroke: "#1976D2"
  }
}

failover: Automatic Failover {
  shape: diamond
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

region.zone_a.primary -> failover: "Health Check\nFailure" {
  style.stroke-dash: 3
}
failover -> region.zone_b.standby: "Promote to\nPrimary" {
  style.stroke-dash: 3
}
```

### Manual Failover

```bash
# Trigger manual failover (for testing)
gcloud sql instances failover ${{ values.name }}-${{ values.environment }} \
  --project=${{ values.gcpProject }}
```

---

## Backup and Recovery

### Automated Backup Configuration

| Setting                       | Dev       | Staging   | Production |
| ----------------------------- | --------- | --------- | ---------- |
| **Backups Enabled**           | Yes       | Yes       | Yes        |
| **Backup Window**             | 03:00 UTC | 03:00 UTC | 02:00 UTC  |
| **Retention Period**          | 3 days    | 7 days    | 30 days    |
| **Point-in-Time Recovery**    | No        | Yes       | Yes        |
| **Transaction Log Retention** | 1 day     | 3 days    | 7 days     |

### Point-in-Time Recovery (PITR)

PITR allows you to restore your database to any point within the transaction log retention period.

```bash
# Clone to a specific point in time
gcloud sql instances clone ${{ values.name }}-${{ values.environment }} \
  ${{ values.name }}-restored \
  --point-in-time="2024-01-15T10:30:00Z" \
  --project=${{ values.gcpProject }}
```

### Manual Backup Operations

```bash
# Create on-demand backup
gcloud sql backups create \
  --instance=${{ values.name }}-${{ values.environment }} \
  --project=${{ values.gcpProject }} \
  --description="Pre-migration backup"

# List available backups
gcloud sql backups list \
  --instance=${{ values.name }}-${{ values.environment }} \
  --project=${{ values.gcpProject }}

# Restore from a specific backup
gcloud sql backups restore BACKUP_ID \
  --restore-instance=${{ values.name }}-${{ values.environment }} \
  --project=${{ values.gcpProject }}
```

### Disaster Recovery Procedures

#### Scenario: Database Corruption

```bash
# 1. Identify the point before corruption
gcloud sql operations list \
  --instance=${{ values.name }}-${{ values.environment }} \
  --project=${{ values.gcpProject }}

# 2. Clone to point before corruption
gcloud sql instances clone ${{ values.name }}-${{ values.environment }} \
  ${{ values.name }}-recovered \
  --point-in-time="2024-01-15T09:00:00Z" \
  --project=${{ values.gcpProject }}

# 3. Verify recovered data
# 4. Update application to use recovered instance
# 5. Delete corrupted instance after verification
```

#### Scenario: Accidental Deletion

If deletion protection is disabled and the instance is accidentally deleted:

```bash
# Restore from backup to new instance
gcloud sql instances create ${{ values.name }}-${{ values.environment }}-new \
  --database-version=${{ values.database_version }} \
  --tier=${{ values.tier }} \
  --region=${{ values.region }} \
  --project=${{ values.gcpProject }}

# Restore data from backup
gcloud sql backups restore BACKUP_ID \
  --restore-instance=${{ values.name }}-${{ values.environment }}-new \
  --project=${{ values.gcpProject }}
```

---

## Outputs

After deployment, these outputs are available:

| Output                      | Description                                        |
| --------------------------- | -------------------------------------------------- |
| `instance_name`             | Name of the Cloud SQL instance                     |
| `instance_id`               | Full resource ID of the instance                   |
| `connection_name`           | Connection name for Cloud SQL Proxy                |
| `public_ip_address`         | Public IP (if enabled)                             |
| `private_ip_address`        | Private IP (if enabled)                            |
| `database_name`             | Name of the created database                       |
| `user_name`                 | Database user name                                 |
| `user_password`             | Database user password (sensitive)                 |
| `password_secret_id`        | Secret Manager secret ID                           |
| `password_secret_name`      | Secret Manager secret name                         |
| `connection_string_postgres`| PostgreSQL connection string (without password)    |
| `connection_string_mysql`   | MySQL connection string (without password)         |
| `cloud_sql_proxy_command`   | Ready-to-use Cloud SQL Proxy command               |
| `cloud_sql_info`            | Summary object with all instance details           |

### Accessing Outputs

```bash
# Get single output
terraform output connection_name

# Get sensitive output
terraform output -raw user_password

# Get all outputs as JSON
terraform output -json

# Get connection string
terraform output -raw connection_string_postgres
```

### Using Outputs in Applications

```bash
# Export as environment variables
export DATABASE_HOST=$(terraform output -raw private_ip_address)
export DATABASE_NAME=$(terraform output -raw database_name)
export DATABASE_USER=$(terraform output -raw user_name)
export DATABASE_PASSWORD=$(terraform output -raw user_password)

# Or fetch password from Secret Manager
export DATABASE_PASSWORD=$(gcloud secrets versions access latest \
  --secret="$(terraform output -raw password_secret_id)")
```

---

## Monitoring and Observability

### Cloud Console Links

- [Cloud SQL Dashboard](https://console.cloud.google.com/sql/instances/${{ values.name }}-${{ values.environment }}?project=${{ values.gcpProject }})
- [Query Insights](https://console.cloud.google.com/sql/instances/${{ values.name }}-${{ values.environment }}/query-insights?project=${{ values.gcpProject }})
- [Metrics Explorer](https://console.cloud.google.com/monitoring/metrics-explorer?project=${{ values.gcpProject }})
- [Logs Explorer](https://console.cloud.google.com/logs/query?project=${{ values.gcpProject }})

### Key Metrics to Monitor

| Metric                           | Description                        | Alert Threshold         |
| -------------------------------- | ---------------------------------- | ----------------------- |
| `database/cpu/utilization`       | CPU usage percentage               | > 80% for 5 min         |
| `database/memory/utilization`    | Memory usage percentage            | > 85% for 5 min         |
| `database/disk/utilization`      | Disk usage percentage              | > 80%                   |
| `database/network/connections`   | Active connections                 | > 80% of max            |
| `database/replication/lag`       | Replication lag (seconds)          | > 10 seconds            |

### Creating Alerts

```bash
# Create alert policy for high CPU
gcloud alpha monitoring policies create \
  --notification-channels=YOUR_CHANNEL_ID \
  --display-name="Cloud SQL High CPU" \
  --condition-display-name="CPU > 80%" \
  --condition-filter='resource.type="cloudsql_database" AND metric.type="cloudsql.googleapis.com/database/cpu/utilization"' \
  --condition-threshold-value=0.8 \
  --condition-threshold-comparison=COMPARISON_GT \
  --condition-threshold-duration=300s
```

---

## Troubleshooting

### Connection Issues

#### Error: Connection refused

```
psql: error: could not connect to server: Connection refused
```

**Resolution:**

1. Verify the instance is running:
   ```bash
   gcloud sql instances describe ${{ values.name }}-${{ values.environment }} \
     --format="value(state)"
   ```

2. Check if using correct IP (private vs public):
   ```bash
   terraform output private_ip_address
   terraform output public_ip_address
   ```

3. For public IP, verify your IP is in authorized networks
4. For private IP, ensure you're connecting from within the VPC

#### Error: SSL connection required

```
FATAL: connection requires a valid client certificate
```

**Resolution:**

```bash
# Connect with SSL using Cloud SQL Proxy (recommended)
./cloud-sql-proxy $CONNECTION_NAME --port=5432

# Or download certificates and connect directly
gcloud sql ssl client-certs create client-cert client-key.pem \
  --instance=${{ values.name }}-${{ values.environment }}
```

### Authentication Issues

#### Error: Workload Identity authentication failed

```
Error: google: could not find default credentials
```

**Resolution:**

1. Verify Workload Identity Provider is configured correctly
2. Check service account has `roles/iam.workloadIdentityUser`
3. Verify repository name in the attribute mapping:
   ```bash
   gcloud iam workload-identity-pools providers describe github-provider \
     --location=global \
     --workload-identity-pool=github-pool \
     --project=${{ values.gcpProject }}
   ```

### State Backend Issues

#### Error: Failed to get existing state

```
Error: Failed to get existing workspaces: storage: bucket doesn't exist
```

**Resolution:**

1. Verify GCS bucket exists:
   ```bash
   gcloud storage buckets describe gs://your-terraform-state-bucket
   ```

2. Check service account has storage permissions
3. Verify bucket name in GitHub secrets

### Instance Issues

#### Error: Quota exceeded

```
Error: Error creating DatabaseInstance: googleapi: Error 403: Quota 'CPUS' exceeded
```

**Resolution:**

1. Check current quota usage:
   ```bash
   gcloud compute regions describe ${{ values.region }} \
     --format="table(quotas.metric,quotas.usage,quotas.limit)"
   ```

2. Request quota increase via Cloud Console

#### Error: Private IP allocation failed

```
Error: Error creating service networking connection: googleapi: Error 400: Cannot allocate the provided CIDR range
```

**Resolution:**

1. Check existing private service connections:
   ```bash
   gcloud services vpc-peerings list --network=VPC_NAME
   ```

2. Use a different CIDR range or delete unused allocations

### Pipeline Failures

#### Security scan blocking deployment

Set `soft_fail: true` in the workflow for warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

#### Terraform test failures

```bash
# Run tests locally to debug
terraform init -backend=false
terraform test -verbose
```

---

## Security Best Practices

### Network Security

- **Enable Private IP**: Use private networking for production workloads
- **Disable Public IP**: Avoid exposing databases to the internet
- **Use Cloud SQL Proxy**: Encrypts connections automatically
- **Restrict Authorized Networks**: Limit IP ranges that can connect

### Credential Management

- **Secret Manager**: Always store passwords in Secret Manager
- **Rotate Credentials**: Implement regular password rotation
- **Least Privilege**: Grant minimum required permissions
- **Avoid Hardcoding**: Never commit credentials to repositories

### Instance Security

- **Enable SSL**: Require SSL for all connections
- **Deletion Protection**: Enable for production instances
- **Audit Logging**: Enable Cloud Audit Logs for compliance

---

## Related Templates

| Template                                                          | Description                           |
| ----------------------------------------------------------------- | ------------------------------------- |
| [gcp-vpc](/docs/default/template/gcp-vpc)                         | Google Cloud VPC network              |
| [gcp-gke](/docs/default/template/gcp-gke)                         | Google Kubernetes Engine cluster      |
| [gcp-cloud-run](/docs/default/template/gcp-cloud-run)             | Google Cloud Run service              |
| [gcp-cloud-functions](/docs/default/template/gcp-cloud-functions) | Google Cloud Functions                |
| [gcp-memorystore](/docs/default/template/gcp-memorystore)         | Google Cloud Memorystore (Redis)      |
| [aws-rds](/docs/default/template/aws-rds)                         | AWS RDS (equivalent)                  |
| [azure-sql](/docs/default/template/azure-sql)                     | Azure SQL Database (equivalent)       |

---

## References

- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
- [Cloud SQL Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Google Cloud SQL Module](https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/latest)
- [Cloud SQL High Availability](https://cloud.google.com/sql/docs/postgres/high-availability)
- [Cloud SQL Backup and Recovery](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups)
- [Query Insights](https://cloud.google.com/sql/docs/postgres/using-query-insights)

---

## Support

For issues with this infrastructure, contact: **${{ values.owner }}**

### Quick Links

- **Instance Console**: [Cloud SQL Instances](https://console.cloud.google.com/sql/instances?project=${{ values.gcpProject }})
- **Monitoring**: [Cloud Monitoring](https://console.cloud.google.com/monitoring?project=${{ values.gcpProject }})
- **Logs**: [Cloud Logging](https://console.cloud.google.com/logs?project=${{ values.gcpProject }})
- **Secrets**: [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=${{ values.gcpProject }})
