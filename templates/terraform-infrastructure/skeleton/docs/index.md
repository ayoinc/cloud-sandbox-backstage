# ${{ values.name }}

Terraform infrastructure for **${{ values.infrastructure_type }}** workloads on **${{ values.cloud_provider }}**, owned by **${{ values.owner }}**.

## Overview

This infrastructure stack provides a production-ready, multi-environment foundation with:

- Custom networking (VPC/VNet) with public and private subnets
{% if values.enable_kubernetes %}
- Managed Kubernetes cluster (${{ values.kubernetes_version }}) with autoscaling
{% endif %}
{% if values.enable_database %}
- Managed database service (${{ values.database_type }}) with automated backups
{% endif %}
{% if values.enable_storage %}
- Object storage with versioning and lifecycle policies
{% endif %}
{% if values.enable_monitoring %}
- Monitoring and alerting via ${{ values.monitoring_solution }}
{% endif %}
{% if values.enable_secrets_manager %}
- Secrets management for secure credential storage
{% endif %}
{% if values.compliance_framework != 'none' %}
- ${{ values.compliance_framework | upper }} compliance controls
{% endif %}

```d2
direction: down

title: {
  label: ${{ values.name }} Infrastructure
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

root: Terraform Root Module {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  
  main: main.tf {
    style.fill: "#BBDEFB"
  }
  vars: variables.tf {
    style.fill: "#BBDEFB"
  }
  outputs: outputs.tf {
    style.fill: "#BBDEFB"
  }
  providers: providers.tf {
    style.fill: "#BBDEFB"
  }
}

modules: Modules {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  
  common: common/ {
    label: "Common\n(shared resources)"
    style.fill: "#C8E6C9"
  }
  
  {% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
  aws: aws/ {
    label: "AWS\n(VPC, EKS, RDS, S3)"
    style.fill: "#C8E6C9"
  }
  {% endif %}
  
  {% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
  azure: azure/ {
    label: "Azure\n(VNet, AKS, SQL)"
    style.fill: "#C8E6C9"
  }
  {% endif %}
  
  {% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
  gcp: gcp/ {
    label: "GCP\n(VPC, GKE, Cloud SQL)"
    style.fill: "#C8E6C9"
  }
  {% endif %}
  
  monitoring: monitoring/ {
    label: "Monitoring\n(Prometheus, Grafana)"
    style.fill: "#C8E6C9"
  }
}

environments: Environments {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  
  dev: dev.tfvars {
    style.fill: "#FFE0B2"
  }
  staging: staging.tfvars {
    style.fill: "#FFE0B2"
  }
  prod: prod.tfvars {
    style.fill: "#FFE0B2"
  }
}

tests: Tests {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  
  infra: infrastructure.tftest.hcl {
    style.fill: "#F8BBD9"
  }
}

cicd: CI/CD Pipeline {
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  
  workflow: terraform.yaml {
    style.fill: "#CE93D8"
  }
}

root -> modules: calls
root -> environments: uses
modules -> tests: validated by
cicd -> root: executes
```

---

## Configuration Summary

| Setting              | Value                                    |
| -------------------- | ---------------------------------------- |
| Infrastructure Name  | `${{ values.name }}`                     |
| Description          | ${{ values.description }}                |
| Cloud Provider       | `${{ values.cloud_provider }}`           |
| Infrastructure Type  | `${{ values.infrastructure_type }}`      |
| Owner                | `${{ values.owner }}`                    |
| Terraform Version    | `${{ values.terraform_version }}`        |
| Compliance Framework | `${{ values.compliance_framework }}`     |

### Feature Toggles

| Feature              | Enabled                                      |
| -------------------- | -------------------------------------------- |
| Networking           | ${{ values.enable_networking }}              |
| Kubernetes           | ${{ values.enable_kubernetes }}              |
| Database             | ${{ values.enable_database }}                |
| Storage              | ${{ values.enable_storage }}                 |
| CDN                  | ${{ values.enable_cdn }}                     |
| Monitoring           | ${{ values.enable_monitoring }}              |
| Alerting             | ${{ values.enable_alerting }}                |
| KMS Encryption       | ${{ values.enable_kms }}                     |
| Secrets Manager      | ${{ values.enable_secrets_manager }}         |
| WAF                  | ${{ values.enable_waf }}                     |
| Backup               | ${{ values.enable_backup }}                  |
| Disaster Recovery    | ${{ values.enable_disaster_recovery }}       |
| Cost Optimization    | ${{ values.enable_cost_optimization }}       |

{% if values.enable_kubernetes %}
### Kubernetes Configuration

| Setting          | Value                            |
| ---------------- | -------------------------------- |
| Version          | `${{ values.kubernetes_version }}`|
| Node Type        | `${{ values.node_instance_type }}`|
| Autoscaling      | ${{ values.enable_autoscaling }} |
| Min Nodes        | ${{ values.min_nodes }}          |
| Max Nodes        | ${{ values.max_nodes }}          |
{% endif %}

{% if values.enable_database %}
### Database Configuration

| Setting       | Value                        |
| ------------- | ---------------------------- |
| Database Type | `${{ values.database_type }}`|
{% endif %}

{% if values.enable_monitoring %}
### Monitoring Configuration

| Setting            | Value                            |
| ------------------ | -------------------------------- |
| Solution           | `${{ values.monitoring_solution }}`|
| Alerting Enabled   | ${{ values.enable_alerting }}    |
| Log Retention      | ${{ values.log_retention_days }} days |
{% endif %}

---

## Module Structure

This infrastructure follows a modular architecture for maintainability and reusability:

```
.
├── main.tf                    # Root module - orchestrates all child modules
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── providers.tf               # Provider configurations
├── versions.tf                # Terraform and provider version constraints
├── modules/
│   ├── common/                # Shared resources across all providers
│   │   ├── main.tf            # Random passwords, unique IDs
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── aws/                   # AWS-specific infrastructure
│   │   ├── main.tf            # VPC, EKS, RDS, S3, IAM
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── azure/                 # Azure-specific infrastructure
│   │   ├── main.tf            # VNet, AKS, Azure SQL, Blob Storage
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── gcp/                   # GCP-specific infrastructure
│   │   ├── main.tf            # VPC, GKE, Cloud SQL, GCS
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── monitoring/            # Monitoring stack (Prometheus/Grafana)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── environments/              # Environment-specific variable files
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── tests/                     # Terraform native tests
│   └── infrastructure.tftest.hcl
├── .github/
│   └── workflows/
│       └── terraform.yaml     # CI/CD pipeline
├── docs/                      # Documentation
│   ├── index.md
│   ├── architecture.md
│   └── operations.md
├── catalog-info.yaml          # Backstage catalog definition
├── mkdocs.yml                 # MkDocs configuration
└── README.md
```

### Module Descriptions

| Module       | Purpose                                                       |
| ------------ | ------------------------------------------------------------- |
| `common`     | Shared resources like random passwords, unique suffixes, tags |
| `aws`        | AWS resources: VPC, EKS, RDS, S3, IAM roles, security groups  |
| `azure`      | Azure resources: VNet, AKS, Azure SQL, Storage Account        |
| `gcp`        | GCP resources: VPC, GKE, Cloud SQL, GCS buckets               |
| `monitoring` | Prometheus, Grafana, Alertmanager Helm deployments            |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Testing**: Native Terraform tests (`terraform test`)
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations

### Pipeline Workflow

```d2
direction: right

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "PR / Push /\nManual"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate"
}

test: Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "terraform test\nUnit Tests"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Plan (dev)\nPlan (staging)\nPlan (prod)"
}

cost: Cost {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Infracost\nEstimate"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

apply: Apply {
  style.fill: "#C8E6C9"
  style.stroke: "#2E7D32"
  label: "Deploy\nInfrastructure"
}

trigger -> validate -> test -> security -> plan
plan -> cost: PR only
plan -> review: manual dispatch
review -> apply
```

### Pipeline Jobs

| Job          | Trigger              | Purpose                                 |
| ------------ | -------------------- | --------------------------------------- |
| `validate`   | All                  | Format check, TFLint                    |
| `terraform-test` | All              | Run `terraform test` suite              |
| `security`   | All                  | tfsec, Checkov, Trivy scanning          |
| `plan-dev`   | All                  | Generate plan for dev environment       |
| `plan-staging` | main branch        | Generate plan for staging environment   |
| `plan-prod`  | main branch          | Generate plan for production environment|
| `cost`       | Pull requests        | Infracost cost estimation               |
| `apply`      | Manual dispatch      | Apply infrastructure changes            |
| `destroy`    | Manual dispatch      | Destroy infrastructure (with approval)  |

### Automatic Triggers

| Event         | Actions                                          |
| ------------- | ------------------------------------------------ |
| Pull Request  | Validate, Test, Security Scan, Plan (dev), Cost  |
| Push to main  | Validate, Test, Security Scan, Plan (all envs)   |

---

## Prerequisites

### 1. Required Tools

Install these tools on your local machine:

| Tool        | Version    | Purpose                        | Installation                                      |
| ----------- | ---------- | ------------------------------ | ------------------------------------------------- |
| Terraform   | >= ${{ values.terraform_version }} | Infrastructure as Code | [terraform.io/downloads](https://www.terraform.io/downloads) |
| TFLint      | >= 0.50.0  | Terraform linter               | `brew install tflint`                             |
{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
| AWS CLI     | >= 2.0     | AWS credential management      | `brew install awscli`                             |
{% endif %}
{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
| Azure CLI   | >= 2.50    | Azure credential management    | `brew install azure-cli`                          |
{% endif %}
{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
| gcloud CLI  | >= 450     | GCP credential management      | [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install) |
{% endif %}
{% if values.enable_kubernetes %}
| kubectl     | >= 1.28    | Kubernetes CLI                 | `brew install kubectl`                            |
| Helm        | >= 3.12    | Kubernetes package manager     | `brew install helm`                               |
{% endif %}

### 2. Cloud Provider Setup

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
#### AWS Configuration

##### Create OIDC Identity Provider

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with AWS.

```bash
# Create the OIDC provider (one-time setup per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

##### Create IAM Role for GitHub Actions

Create a role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/${{ values.name }}:*"
        }
      }
    }
  ]
}
```

##### Required IAM Permissions

Attach a policy with permissions for:

- **EC2**: VPC, Subnets, Security Groups, NAT Gateways
{% if values.enable_kubernetes %}
- **EKS**: Cluster management, Node groups, OIDC providers
{% endif %}
{% if values.enable_database %}
- **RDS**: Instance management, Subnet groups, Parameter groups
{% endif %}
{% if values.enable_storage %}
- **S3**: Bucket management, Object operations
{% endif %}
{% if values.enable_kms %}
- **KMS**: Key management, Encryption operations
{% endif %}
{% if values.enable_secrets_manager %}
- **Secrets Manager**: Secret management
{% endif %}
- **IAM**: Role creation for service accounts
- **CloudWatch**: Log groups, Metrics
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
#### Azure Configuration

##### Create Service Principal

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-${{ values.name }}" \
  --role Contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID \
  --sdk-auth
```

##### Configure Federated Credentials (Recommended)

For OIDC authentication without secrets:

```bash
# Create federated credential for GitHub Actions
az ad app federated-credential create \
  --id APPLICATION_OBJECT_ID \
  --parameters '{
    "name": "github-actions-${{ values.name }}",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/${{ values.name }}:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
#### GCP Configuration

##### Create Service Account

```bash
# Create service account
gcloud iam service-accounts create github-actions-${{ values.name }} \
  --display-name="GitHub Actions for ${{ values.name }}"

# Grant required roles
gcloud projects add-iam-policy-binding ${{ values.gcp_project_id }} \
  --member="serviceAccount:github-actions-${{ values.name }}@${{ values.gcp_project_id }}.iam.gserviceaccount.com" \
  --role="roles/editor"
```

##### Configure Workload Identity Federation (Recommended)

```bash
# Create workload identity pool
gcloud iam workload-identity-pools create github-actions \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create provider
gcloud iam workload-identity-pools providers create-oidc github \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository"
```
{% endif %}

### 3. Terraform State Backend

#### Create State Storage

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-${{ values.name }} --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-${{ values.name }} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket terraform-state-${{ values.name }} \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks-${{ values.name }} \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
```bash
# Create resource group
az group create --name rg-terraform-state --location eastus

# Create storage account
az storage account create \
  --name tfstate${{ values.name | replace('-', '') }} \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstate${{ values.name | replace('-', '') }}
```
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
```bash
# Create GCS bucket for state
gsutil mb -l us-central1 gs://terraform-state-${{ values.name }}

# Enable versioning
gsutil versioning set on gs://terraform-state-${{ values.name }}
```
{% endif %}

### 4. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                | Description                                   | Required |
| --------------------- | --------------------------------------------- | -------- |
{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
| `AWS_ROLE_ARN`        | IAM role ARN for OIDC authentication          | Yes      |
{% endif %}
{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
| `AZURE_CLIENT_ID`     | Azure AD application client ID                | Yes      |
| `AZURE_TENANT_ID`     | Azure AD tenant ID                            | Yes      |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID                       | Yes      |
{% endif %}
{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
| `GCP_PROJECT_ID`      | GCP project ID                                | Yes      |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider path    | Yes      |
| `GCP_SERVICE_ACCOUNT` | Service account email                         | Yes      |
{% endif %}
| `TF_STATE_BUCKET`     | State storage bucket name                     | Yes      |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for locking (AWS only)         | No       |
| `INFRACOST_API_KEY`   | API key for cost estimation                   | No       |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default                |
| ------------ | ------------------ | ---------------------- |
{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
| `AWS_REGION` | Default AWS region | `us-west-2`            |
{% endif %}
{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
| `AZURE_LOCATION` | Default Azure region | `eastus`          |
{% endif %}
{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
| `GCP_REGION` | Default GCP region | `us-central1`          |
{% endif %}

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Initialize Terraform (without backend for local testing)
terraform init -backend=false

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Initialize with backend for real deployment
terraform init \
  -backend-config="bucket=terraform-state-${{ values.name }}" \
  -backend-config="key=${{ values.name }}/dev/terraform.tfstate" \
  -backend-config="region=us-west-2"

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Running the Pipeline

#### Manual Deployment

1. Navigate to **Actions** tab in GitHub
2. Select **Terraform Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

#### Pull Request Workflow

1. Create a feature branch
2. Make infrastructure changes
3. Open a pull request
4. Pipeline automatically runs:
   - Validation and formatting checks
   - Terraform tests
   - Security scanning (tfsec, Checkov, Trivy)
   - Plan for dev environment
   - Cost estimation (if Infracost configured)
5. Review the plan output in PR comments
6. After approval and merge, manually trigger apply

---

## Environment Management

### Environment Files

Each environment has its own variable file in `environments/`:

| File            | Purpose                                        |
| --------------- | ---------------------------------------------- |
| `dev.tfvars`    | Development - minimal resources, lower costs   |
| `staging.tfvars`| Pre-production - mirrors prod at smaller scale |
| `prod.tfvars`   | Production - full resources, high availability |

### Example Environment Configuration

```hcl
# environments/dev.tfvars
environment = "development"

# Minimal resources for development
{% if values.enable_kubernetes %}
min_nodes = 2
max_nodes = 3
{% endif %}

# Lower retention for cost savings
log_retention_days = 7

# Disable expensive features
enable_backup           = false
enable_disaster_recovery = false
enable_waf              = false
```

```hcl
# environments/prod.tfvars
environment = "production"

# Production-grade resources
{% if values.enable_kubernetes %}
min_nodes = 5
max_nodes = 20
{% endif %}

# Extended retention for compliance
log_retention_days = 365

# Enable all security features
enable_backup           = true
enable_disaster_recovery = true
enable_waf              = true
```

### Workspace Management

Terraform workspaces are used to isolate state per environment:

```bash
# List workspaces
terraform workspace list

# Select workspace
terraform workspace select staging

# Create new workspace
terraform workspace new qa
```

---

## State Management

### State Backend Configuration

State is stored remotely with locking to prevent concurrent modifications:

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
```hcl
# AWS S3 Backend
backend "s3" {
  bucket         = "terraform-state-${{ values.name }}"
  key            = "${{ values.name }}/terraform.tfstate"
  region         = "us-west-2"
  encrypt        = true
  dynamodb_table = "terraform-locks-${{ values.name }}"
}
```
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
```hcl
# Azure Blob Backend
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "tfstate${{ values.name | replace('-', '') }}"
  container_name       = "tfstate"
  key                  = "${{ values.name }}.tfstate"
}
```
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
```hcl
# GCP GCS Backend
backend "gcs" {
  bucket = "terraform-state-${{ values.name }}"
  prefix = "${{ values.name }}"
}
```
{% endif %}

### State Operations

```bash
# View current state
terraform state list

# Show specific resource
terraform state show module.aws_infrastructure[0].aws_vpc.main

# Import existing resource
terraform import aws_vpc.main vpc-12345678

# Remove resource from state (without destroying)
terraform state rm aws_s3_bucket.old_bucket

# Move resource in state
terraform state mv aws_s3_bucket.old aws_s3_bucket.new
```

### State Locking

State locking prevents concurrent operations:

| Provider | Locking Mechanism     |
| -------- | --------------------- |
| AWS      | DynamoDB table        |
| Azure    | Azure Blob lease      |
| GCP      | GCS object versioning |

If a lock is stuck, you can force-unlock (use with caution):

```bash
terraform force-unlock LOCK_ID
```

---

## Outputs

After deployment, these outputs are available:

### General Outputs

| Output                 | Description                     |
| ---------------------- | ------------------------------- |
| `infrastructure_name`  | Name of the infrastructure      |
| `environment`          | Current environment             |
| `cloud_provider`       | Active cloud provider           |
| `compliance_framework` | Applied compliance framework    |
| `resource_summary`     | Summary of created resources    |

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
### AWS Outputs

| Output                 | Description                |
| ---------------------- | -------------------------- |
| `aws_vpc_id`           | VPC identifier             |
| `aws_vpc_cidr`         | VPC CIDR block             |
| `aws_private_subnet_ids` | List of private subnet IDs |
| `aws_public_subnet_ids`  | List of public subnet IDs  |
{% if values.enable_kubernetes %}
| `eks_cluster_name`     | EKS cluster name           |
| `eks_cluster_endpoint` | EKS API endpoint           |
| `eks_cluster_version`  | Kubernetes version         |
{% endif %}
{% if values.enable_database %}
| `rds_endpoint`         | RDS instance endpoint      |
| `rds_port`             | RDS instance port          |
{% endif %}
{% if values.enable_storage %}
| `s3_bucket_name`       | S3 bucket name             |
| `s3_bucket_arn`        | S3 bucket ARN              |
{% endif %}
{% endif %}

{% if values.enable_monitoring %}
### Monitoring Outputs

| Output                | Description                  |
| --------------------- | ---------------------------- |
| `monitoring_namespace`| Kubernetes namespace         |
{% if values.monitoring_solution == 'prometheus-grafana' %}
| `prometheus_endpoint` | Prometheus server URL        |
| `grafana_endpoint`    | Grafana dashboard URL        |
| `grafana_admin_password` | Grafana admin credentials (sensitive) |
{% endif %}
{% endif %}

### Accessing Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output infrastructure_name

# View output as JSON
terraform output -json resource_summary

# View sensitive output
terraform output -raw grafana_admin_password

{% if values.enable_kubernetes %}
# Configure kubectl
eval $(terraform output -raw kubectl_config_command)
{% endif %}
```

---

## Troubleshooting

### Authentication Issues

**Error: No valid credential sources found**

```
Error: configuring Terraform AWS Provider: no valid credential sources found.
```

**Resolution:**

1. Verify cloud credentials are configured correctly
2. Check OIDC provider is set up in cloud console
3. Ensure trust policy includes your repository
4. Verify the IAM role/service principal has required permissions

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
```bash
# Test AWS credentials
aws sts get-caller-identity
```
{% endif %}

### State Lock Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      terraform-state-${{ values.name }}/terraform.tfstate
  Operation: OperationTypeApply
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually remove the lock:

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
```bash
aws dynamodb delete-item \
  --table-name terraform-locks-${{ values.name }} \
  --key '{"LockID":{"S":"terraform-state-${{ values.name }}/${{ values.name }}/terraform.tfstate"}}'
```
{% endif %}

3. Or use force-unlock:

```bash
terraform force-unlock LOCK_ID
```

### Permission Issues

**Error: Access Denied / UnauthorizedOperation**

**Resolution:**

1. Review IAM role/service principal permissions
2. Ensure all required policies are attached
3. Check for Service Control Policies (SCPs) or Azure Policies that may restrict actions
4. Verify resource quotas haven't been exceeded

### Plan Shows Unexpected Changes

**Issue: Resources showing changes that weren't made**

**Resolution:**

1. Check for external modifications (console changes, other processes)
2. Run `terraform refresh` to sync state
3. Review for default value changes in provider versions
4. Check for resources modified by auto-update features

### Security Scan Failures

**Issue: tfsec/Checkov blocking pipeline**

**Resolution:**

Set `soft_fail: true` temporarily to allow warnings:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

Or add inline ignores for false positives:

```hcl
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "example" {
  # ...
}
```

### Terraform Test Failures

**Issue: `terraform test` failing**

**Resolution:**

1. Review test output for specific assertions that failed
2. Check if mock data matches expected module behavior
3. Verify test file syntax in `tests/*.tftest.hcl`

```bash
# Run tests with verbose output
terraform test -verbose
```

---

## Security Scanning

The pipeline includes multiple security scanning tools:

| Tool        | Purpose                                    | Documentation                        |
| ----------- | ------------------------------------------ | ------------------------------------ |
| **tfsec**   | Terraform security misconfigurations       | [tfsec.dev](https://tfsec.dev)       |
| **Checkov** | Policy-as-code for IaC security            | [checkov.io](https://www.checkov.io) |
| **Trivy**   | Comprehensive IaC vulnerability scanner    | [trivy.dev](https://trivy.dev)       |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Related Templates

| Template                                                            | Description                        |
| ------------------------------------------------------------------- | ---------------------------------- |
{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
| [aws-vpc](/docs/default/template/aws-vpc)                           | AWS VPC networking                 |
| [aws-eks](/docs/default/template/aws-eks)                           | Amazon EKS Kubernetes cluster      |
| [aws-rds](/docs/default/template/aws-rds)                           | Amazon RDS database                |
| [aws-lambda](/docs/default/template/aws-lambda)                     | AWS Lambda serverless function     |
{% endif %}
{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
| [azure-vnet](/docs/default/template/azure-vnet)                     | Azure Virtual Network              |
| [azure-aks](/docs/default/template/azure-aks)                       | Azure Kubernetes Service           |
| [azure-sql](/docs/default/template/azure-sql)                       | Azure SQL Database                 |
{% endif %}
{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
| [gcp-vpc](/docs/default/template/gcp-vpc)                           | Google Cloud VPC                   |
| [gcp-gke](/docs/default/template/gcp-gke)                           | Google Kubernetes Engine           |
| [gcp-cloudsql](/docs/default/template/gcp-cloudsql)                 | Google Cloud SQL                   |
{% endif %}
| [kubernetes-app](/docs/default/template/kubernetes-app)             | Kubernetes application deployment  |
| [docker-service](/docs/default/template/docker-service)             | Containerized microservice         |

---

## References

### Terraform Documentation

- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)

### Provider Documentation

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
{% if values.enable_kubernetes %}
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/)
{% endif %}
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure VNet Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
{% if values.enable_kubernetes %}
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
{% endif %}
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
- [Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP VPC Documentation](https://cloud.google.com/vpc/docs)
{% if values.enable_kubernetes %}
- [Google GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
{% endif %}
{% endif %}

### CI/CD Documentation

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [GitHub Actions OIDC with GCP](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
- [Infracost Documentation](https://www.infracost.io/docs/)

### Security Tools

- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

---

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review the related documentation files:
   - [Architecture Documentation](./architecture.md)
   - [Operations Guide](./operations.md)
3. Contact the platform team via Slack: `#platform-support`
4. File a ticket in the internal support system

**Owner:** ${{ values.owner }}
