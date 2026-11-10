# ${{ values.name }}

${{ values.description }}

## Overview

This Cloud Run service provides a fully-managed serverless container platform for the **${{ values.environment }}** environment in **${{ values.region }}**.

Key capabilities:

- Auto-scaling from 0 to ${{ values.maxInstances }} instances based on traffic
- Automatic TLS termination and HTTPS endpoints
- Integrated health checks with startup and liveness probes
- Private container registry via Artifact Registry
- Secret Manager integration for secure credential management
- VPC Connector support for private network access
- Cloud Monitoring alerts for latency and error rate thresholds

```d2
direction: right

title: {
  label: GCP Cloud Run Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

gcp: Google Cloud Platform {
  style.fill: "#E8F0FE"
  style.stroke: "#4285F4"

  lb: Cloud Load Balancer {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#34A853"
    label: "HTTPS\nLoad Balancer"
  }

  cloudrun: Cloud Run Service {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    container: Container {
      shape: package
      style.fill: "#BBDEFB"
      style.stroke: "#1565C0"
      label: "${{ values.name }}\n${{ values.cpu }} CPU\n${{ values.memory }}"
    }

    scaling: Auto-scaling {
      shape: cylinder
      style.fill: "#E1F5FE"
      style.stroke: "#0288D1"
      label: "0 - ${{ values.maxInstances }}\ninstances"
    }
  }

  secrets: Secret Manager {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "API Keys\nCredentials"
  }

  registry: Artifact Registry {
    shape: cylinder
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
    label: "Container\nImages"
  }

  vpc: VPC Connector {
    shape: parallelogram
    style.fill: "#FFF8E1"
    style.stroke: "#FF8F00"
    label: "Private\nNetwork"
  }

  cloudsql: Cloud SQL {
    shape: cylinder
    style.fill: "#FFEBEE"
    style.stroke: "#D32F2F"
    label: "Database\n(optional)"
  }

  monitoring: Cloud Monitoring {
    shape: document
    style.fill: "#E0F2F1"
    style.stroke: "#00897B"
    label: "Alerts\nMetrics"
  }

  lb -> cloudrun
  cloudrun.container -> secrets: reads
  registry -> cloudrun.container: deploys
  cloudrun -> vpc
  vpc -> cloudsql: connects
  cloudrun -> monitoring: metrics
}

internet -> gcp.lb: HTTPS
```

---

## Configuration Summary

| Setting             | Value                              |
| ------------------- | ---------------------------------- |
| Service Name        | `${{ values.name }}`               |
| GCP Project         | `${{ values.gcpProject }}`         |
| Region              | `${{ values.region }}`             |
| Environment         | `${{ values.environment }}`        |
| CPU                 | `${{ values.cpu }}`                |
| Memory              | `${{ values.memory }}`             |
| Min Instances       | `0`                                |
| Max Instances       | `${{ values.maxInstances }}`       |
| Public Access       | `${{ values.allowUnauthenticated }}` |
| Container Port      | `8080`                             |
| Health Check Path   | `/health`                          |

---

## CI/CD Pipeline

The `Terraform` workflow (`.github/workflows/terraform.yaml`) runs on every
push and pull request to `main`.

| Job                       | Needs credentials   | What it does                                                                   |
| ------------------------- | ------------------- | ------------------------------------------------------------------------------ |
| Validate                  | No                  | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`  |
| TFLint                    | No                  | Lints the configuration and module with the Google ruleset                     |
| Terraform tests           | No                  | `terraform test` against mocked providers                                      |
| Security scan (Trivy)     | No                  | Fails on critical, high and medium misconfigurations                           |
| Security scan (Checkov)   | No                  | Policy checks for the Terraform code                                           |
| Cost estimation           | `INFRACOST_API_KEY` | Comments the cost estimate on pull requests                                    |
| Plan                      | GCP secrets         | Plans the selected environment and comments the plan on pull requests          |
| Apply                     | GCP secrets         | Applies the plan on pushes to `main`                                           |
| Destroy / Drift detection | GCP secrets         | Started manually from the Actions tab                                          |

Jobs that need credentials are skipped until the repository secrets exist, so
a new repository is green before any cloud access is configured. Pushes and
pull requests target the environment selected when the repository was created
(`${{ values.environment }}`); a manual run can target `dev`, `staging` or `prod`.

---

## Prerequisites

### 1. GCP Project Setup

#### Enable Required APIs

```bash
# Enable required GCP APIs
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com \
  monitoring.googleapis.com \
  cloudtrace.googleapis.com \
  logging.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  --project=${{ values.gcpProject }}
```

#### Create Workload Identity Federation Pool

GitHub Actions uses Workload Identity Federation (OIDC) for secure, keyless authentication with GCP.

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-actions" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc "github" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --display-name="GitHub OIDC Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

#### Create Service Account for GitHub Actions

```bash
# Create service account
gcloud iam service-accounts create github-actions-terraform \
  --project="${{ values.gcpProject }}" \
  --display-name="GitHub Actions Terraform"

# Get the service account email
SA_EMAIL="github-actions-terraform@${{ values.gcpProject }}.iam.gserviceaccount.com"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${{ values.gcpProject }}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository/YOUR_ORG/YOUR_REPO"
```

#### Required IAM Permissions

Grant the service account these roles:

```bash
SA_EMAIL="github-actions-terraform@${{ values.gcpProject }}.iam.gserviceaccount.com"

# Cloud Run permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin"

# Artifact Registry permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.admin"

# Secret Manager permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.admin"

# IAM permissions (for service account creation)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# VPC Access Connector permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/vpcaccess.admin"

# Monitoring permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/monitoring.admin"

# Storage permissions (for Terraform state)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"
```

#### Create Terraform State Backend

```bash
# Create GCS bucket for Terraform state
gcloud storage buckets create gs://${{ values.gcpProject }}-terraform-state \
  --project=${{ values.gcpProject }} \
  --location=${{ values.region }} \
  --uniform-bucket-level-access

# Enable versioning for state recovery
gcloud storage buckets update gs://${{ values.gcpProject }}-terraform-state \
  --versioning
```

### 2. GitHub Repository Setup

#### Secrets

Configure these in **Settings > Secrets and variables > Actions**. Plan and
apply are skipped until the first three exist.

| Secret                           | Description                              | Example                                                                               |
| -------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full provider resource name              | `projects/123/locations/global/workloadIdentityPools/github-actions/providers/github` |
| `GCP_SERVICE_ACCOUNT`            | Service account email for authentication | `github-actions-terraform@project.iam.gserviceaccount.com`                            |
| `GCP_TERRAFORM_STATE_BUCKET`     | GCS bucket name for Terraform state      | `${{ values.gcpProject }}-terraform-state`                                            |
| `INFRACOST_API_KEY`              | API key for cost estimation (optional)   | `ico-xxxxxxxx`                                                                        |

#### GitHub Environments

The apply and destroy jobs run in the GitHub environment named after the
target (`dev`, `staging` or `prod`); GitHub creates it on first use. To require
an approval, add required reviewers to the environment in
**Settings > Environments**.

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Build container locally
docker build -t ${{ values.name }}:latest .

# Run locally
docker run -p 8080:8080 \
  -e PORT=8080 \
  -e ENVIRONMENT=local \
  ${{ values.name }}:latest

# Test health endpoint
curl http://localhost:8080/health

# Test application
curl http://localhost:8080/
```

### Terraform Local Development

```bash
# Initialize Terraform (without backend for local testing)
terraform init -backend=false

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars
```

### gcloud CLI Deployment

#### Configure Docker Authentication

```bash
# Configure Docker for Artifact Registry
gcloud auth configure-docker ${{ values.region }}-docker.pkg.dev
```

#### Build and Push Container

```bash
# Build container
docker build -t ${{ values.name }}:latest .

# Tag for Artifact Registry
docker tag ${{ values.name }}:latest \
  ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest

# Push to Artifact Registry
docker push ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest
```

#### Deploy via gcloud

```bash
# Deploy to Cloud Run
gcloud run deploy ${{ values.name }}-${{ values.environment }} \
  --image ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/${{ values.name }}:latest \
  --region ${{ values.region }} \
  --project ${{ values.gcpProject }} \
  --platform managed \
  --memory ${{ values.memory }} \
  --cpu ${{ values.cpu }} \
  --max-instances ${{ values.maxInstances }} \
  --port 8080
```

### Running the Pipeline

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **Terraform** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy action)
5. Click **Run workflow**

Apply and destroy wait for approval if the target GitHub environment has required reviewers.

---

## Environment Variables

Configure environment variables in `main.tf` or via `environments/*.tfvars`:

### Static Environment Variables

```hcl
environment_variables = {
  "LOG_LEVEL"   = "info"
  "ENVIRONMENT" = "production"
  "APP_NAME"    = "${{ values.name }}"
}
```

### Secret Environment Variables (from Secret Manager)

```hcl
secret_environment_variables = {
  "DATABASE_URL" = {
    secret_name = "database-url"
    version     = "latest"
  }
  "API_KEY" = {
    secret_name = "api-key"
    version     = "1"
  }
}
```

### Creating Secrets

```bash
# Create a secret
echo -n "your-secret-value" | gcloud secrets create database-url \
  --project=${{ values.gcpProject }} \
  --data-file=-

# Grant access to Cloud Run service account
gcloud secrets add-iam-policy-binding database-url \
  --project=${{ values.gcpProject }} \
  --member="serviceAccount:${{ values.name }}-${{ values.environment }}@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## Security Scanning

| Tool        | Purpose                                                    | Documentation                        |
| ----------- | ---------------------------------------------------------- | ------------------------------------ |
| **Trivy**   | Misconfiguration scan; fails on critical, high and medium  | [trivy.dev](https://trivy.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance  | [checkov.io](https://www.checkov.io) |

Both scans block the pipeline. Fix a finding in the Terraform code where
possible. Where a finding is a deliberate choice, suppress that single rule
on the resource with a reason:

```hcl
resource "google_storage_bucket" "example" {
  # checkov:skip=CKV_GCP_62:Reason for the exception
}

# trivy:ignore:AVD-GCP-0001
resource "google_storage_bucket" "other" {}
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource                    | Monthly Cost (USD)       |
| --------------------------- | ------------------------ |
| Cloud Run (per vCPU-second) | ~$0.000024              |
| Cloud Run (per GB-second)   | ~$0.0000025             |
| Cloud Run (per request)     | ~$0.40 per million      |
| Artifact Registry           | ~$0.10 per GB           |
| Secret Manager              | ~$0.03 per 10k accesses |
| VPC Connector (if enabled)  | ~$6.85/month            |
| **Estimated Base Cost**     | ~$5-50/month            |

*Actual costs depend on traffic volume and instance utilization.*

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                  | Description                                   |
| ----------------------- | --------------------------------------------- |
| `service_id`            | Cloud Run service unique identifier           |
| `service_name`          | Cloud Run service name                        |
| `service_url`           | HTTPS URL for the Cloud Run service           |
| `service_location`      | GCP region where service is deployed          |
| `latest_revision`       | Name of the latest ready revision             |
| `service_account_email` | Service account email for the Cloud Run service |
| `service_account_name`  | Service account display name                  |
| `artifact_registry_id`  | Artifact Registry repository ID               |
| `artifact_registry_url` | URL for docker push/pull operations           |
| `vpc_connector_id`      | VPC Access Connector ID (if created)          |
| `vpc_connector_name`    | VPC Access Connector name (if created)        |
| `docker_push_command`   | Ready-to-use docker push command              |
| `gcloud_deploy_command` | Ready-to-use gcloud deploy command            |

Access outputs via:

```bash
# Get single output
terraform output service_url

# Get all outputs as JSON
terraform output -json

# Get deployment commands
terraform output docker_push_command
terraform output gcloud_deploy_command
```

---

## Troubleshooting

### Authentication Issues

**Error: Unable to authenticate to Google Cloud**

```
Error: Error creating service account: googleapi: Error 403: Permission denied on resource project
```

**Resolution:**

1. Verify Workload Identity Federation is configured correctly
2. Check service account has required IAM roles
3. Verify GitHub secret `GCP_WORKLOAD_IDENTITY_PROVIDER` format:
   ```
   projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
   ```
4. Ensure repository is allowed in the Workload Identity Pool

### Container Deployment Issues

**Error: Container failed to start**

```
ERROR: (gcloud.run.deploy) Revision failed to become ready
```

**Resolution:**

1. Check container logs:
   ```bash
   gcloud run revisions logs ${{ values.name }}-${{ values.environment }} \
     --project=${{ values.gcpProject }} \
     --region=${{ values.region }}
   ```
2. Verify container exposes correct port (8080)
3. Ensure `/health` endpoint returns 200 OK
4. Check memory limits are sufficient

### Secret Access Issues

**Error: Secret not accessible**

```
Error: secret version not found or access denied
```

**Resolution:**

1. Verify secret exists:
   ```bash
   gcloud secrets describe SECRET_NAME --project=${{ values.gcpProject }}
   ```
2. Check service account has `roles/secretmanager.secretAccessor`:
   ```bash
   gcloud secrets add-iam-policy-binding SECRET_NAME \
     --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
     --role="roles/secretmanager.secretAccessor"
   ```

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error locking state: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually break the lock:
   ```bash
   terraform force-unlock LOCK_ID
   ```

### VPC Connector Issues

**Error: VPC Connector creation failed**

```
Error: Error creating Connector: googleapi: Error 400: Invalid connector
```

**Resolution:**

1. Ensure VPC network exists
2. Check CIDR range doesn't overlap with existing subnets
3. Verify Serverless VPC Access API is enabled

### Pipeline Failures

**Security scan blocking deployment**

Open the failed Trivy or Checkov job to see the rule and the resource. Fix the
Terraform code, or suppress that single rule on the resource with a reason
(`# checkov:skip=<ID>:<reason>` or `# trivy:ignore:<ID>`).

---

## Related Templates

| Template                                                       | Description                            |
| -------------------------------------------------------------- | -------------------------------------- |
| [gcp-vpc](/docs/default/template/gcp-vpc)                      | Google Cloud VPC network               |
| [gcp-cloud-sql](/docs/default/template/gcp-cloud-sql)          | Google Cloud SQL database              |
| [gcp-gke](/docs/default/template/gcp-gke)                      | Google Kubernetes Engine cluster       |
| [gcp-cloud-function](/docs/default/template/gcp-cloud-function)| Google Cloud Functions (serverless)    |
| [gcp-pubsub](/docs/default/template/gcp-pubsub)                | Google Cloud Pub/Sub messaging         |
| [aws-ecs-fargate](/docs/default/template/aws-ecs-fargate)      | AWS ECS Fargate (equivalent)           |
| [azure-container-apps](/docs/default/template/azure-container-apps) | Azure Container Apps (equivalent) |

---

## References

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider - Cloud Run](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC with GCP](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)
- [Cloud Run Security Best Practices](https://cloud.google.com/run/docs/securing/security-best-practices)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.
