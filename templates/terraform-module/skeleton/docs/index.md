# ${{ values.name }}

${{ values.description }}

## Overview

This Terraform module provides a comprehensive, production-ready infrastructure foundation for **${{ values.provider | capitalize }}** cloud platform. The module follows Terraform best practices with a modular architecture, built-in testing, and CI/CD automation.

### Key Features

- Modular architecture with feature flags for resource enablement
- Multi-environment support (dev, staging, prod)
- Built-in security scanning and compliance checks
- Cost estimation integration
- Comprehensive test coverage using Terraform's native testing framework
- Ready for Terraform Registry publishing

```d2
direction: down

title: {
  label: Terraform Module Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

root: Root Module {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  
  main: main.tf {
    shape: document
    style.fill: "#BBDEFB"
  }
  
  vars: variables.tf {
    shape: document
    style.fill: "#BBDEFB"
  }
  
  outputs: outputs.tf {
    shape: document
    style.fill: "#BBDEFB"
  }
  
  versions: versions.tf {
    shape: document
    style.fill: "#BBDEFB"
  }
}

submodules: Submodules {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  
  {%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
  aws: AWS {
    style.fill: "#C8E6C9"
    compute: Compute
    network: Network
    storage: Storage
    database: Database
    security: Security
    observability: Observability
    kubernetes: Kubernetes
    serverless: Serverless
  }
  {%- endif %}
  
  {%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
  azure: Azure {
    style.fill: "#C8E6C9"
    compute: Compute
    network: Network
    storage: Storage
    database: Database
    kubernetes: Kubernetes
    serverless: Serverless
  }
  {%- endif %}
  
  {%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
  gcp: GCP {
    style.fill: "#C8E6C9"
    compute: Compute
    network: Network
    storage: Storage
    database: Database
    kubernetes: Kubernetes
    serverless: Serverless
  }
  {%- endif %}
}

resources: Cloud Resources {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  
  infra: Infrastructure {
    shape: cloud
    style.fill: "#F8BBD9"
  }
}

tests: Tests {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  
  unit: Unit Tests
  integration: Integration Tests
}

examples: Examples {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  
  {%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
  aws_example: AWS Example
  {%- endif %}
  {%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
  azure_example: Azure Example
  {%- endif %}
  {%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
  gcp_example: GCP Example
  {%- endif %}
}

root -> submodules: calls
submodules -> resources: provisions
tests -> root: validates
examples -> root: demonstrates
```

---

## Configuration Summary

| Setting              | Value                                                                                                       |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| Module Name          | `${{ values.name }}`                                                                                        |
| Cloud Provider       | `${{ values.provider }}`                                                                                    |
| Terraform Version    | `>= ${{ values.terraform_version }}`                                                                        |
| Default Environment  | `dev`                                                                                                       |
| Owner                | `${{ values.owner }}`                                                                                       |

### Feature Flags

Enable or disable resource modules using feature flags in `terraform.tfvars`:

| Flag                   | Default | Description                        |
| ---------------------- | ------- | ---------------------------------- |
| `enable_compute`       | `true`  | Compute resources (VMs, instances) |
| `enable_network`       | `true`  | Network infrastructure (VPC/VNet)  |
| `enable_storage`       | `true`  | Object and file storage            |
| `enable_database`      | `false` | Managed databases                  |
| `enable_security`      | `true`  | Security resources (KMS, secrets)  |
| `enable_observability` | `true`  | Monitoring and logging             |
| `enable_kubernetes`    | `false` | Managed Kubernetes clusters        |
| `enable_serverless`    | `false` | Serverless functions               |

---

## Module Structure

The module follows a hierarchical structure with provider-specific submodules:

```
.
├── main.tf                    # Root module - orchestrates submodules
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── versions.tf                # Provider version constraints
├── providers.tf               # Provider configurations
├── locals.tf                  # Local value computations
├── terraform.tfvars.example   # Example variable values
├── catalog-info.yaml          # Backstage service catalog metadata
│
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
├── aws/                       # AWS-specific submodules
│   ├── compute/               # EC2 instances, Auto Scaling Groups
│   ├── network/               # VPC, Subnets, NAT Gateways, Route Tables
│   ├── storage/               # S3 buckets, EFS file systems
│   ├── database/              # RDS instances, ElastiCache clusters
│   ├── security/              # KMS keys, Secrets Manager, IAM
│   ├── observability/         # CloudWatch alarms, dashboards, logs
│   ├── kubernetes/            # EKS cluster and node groups
│   └── serverless/            # Lambda functions, API Gateway
│
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
├── azure/                     # Azure-specific submodules
│   ├── compute/               # Virtual Machines, Scale Sets
│   ├── network/               # VNet, Subnets, NSGs, Load Balancers
│   ├── storage/               # Storage Accounts, Blob containers
│   ├── database/              # Azure SQL, Redis Cache
│   ├── security/              # Key Vault, Managed Identities
│   ├── observability/         # Log Analytics, Application Insights
│   ├── kubernetes/            # AKS cluster
│   └── serverless/            # Azure Functions, Logic Apps
│
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
├── gcp/                       # GCP-specific submodules
│   ├── compute/               # Compute Engine VMs, Instance Groups
│   ├── network/               # VPC, Subnets, Cloud NAT, Firewall rules
│   ├── storage/               # Cloud Storage buckets
│   ├── database/              # Cloud SQL, Memorystore
│   ├── security/              # KMS, Secret Manager, IAM
│   ├── observability/         # Cloud Monitoring, Cloud Logging
│   ├── kubernetes/            # GKE cluster
│   └── serverless/            # Cloud Functions, Cloud Run
│
{%- endif %}
├── examples/                  # Usage examples for each provider
│   {%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
│   ├── aws/                   # AWS deployment example
│   {%- endif %}
│   {%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
│   ├── azure/                 # Azure deployment example
│   {%- endif %}
│   {%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
│   └── gcp/                   # GCP deployment example
│   {%- endif %}
│
├── tests/                     # Terraform native tests
│   ├── unit/                  # Unit tests (plan-only validation)
│   │   └── module.tftest.hcl
│   └── integration/           # Integration tests (with real resources)
│       └── full_stack.tftest.hcl
│
├── docs/                      # Documentation
│   └── index.md               # This file
│
└── .github/
    └── workflows/
        └── terraform.yaml     # CI/CD pipeline configuration
```

### Submodule Naming Convention

Each submodule follows a consistent structure:

```
<provider>/<resource-type>/
├── main.tf                    # Resource definitions
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
└── <resource>.auto.tfvars.example  # Example configuration
```

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with multi-stage validation and deployment:

### Pipeline Features

- **Validation**: Format checking, linting, Terraform validation
- **Security Scanning**: tfsec, Checkov for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Native Testing**: Terraform test framework integration

### Pipeline Workflow

```d2
direction: right

title: {
  label: CI/CD Pipeline Flow
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "PR / Push / Manual"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  
  fmt: Format Check
  init: Init
  validate_tf: Validate
}

test: Test {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  
  unit: Unit Tests
  integration: Integration Tests
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  
  tfsec: tfsec
  checkov: Checkov
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  
  plan_tf: Generate Plan
  cost: Cost Estimate
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual Approval"
}

apply: Apply {
  style.fill: "#C8E6C9"
  style.stroke: "#2E7D32"
  label: "Deploy Infrastructure"
}

trigger -> validate
validate -> test
validate -> security
test -> plan
security -> plan
plan -> review
review -> apply
```

### Pipeline Stages

| Stage         | Trigger                | Actions                                          |
| ------------- | ---------------------- | ------------------------------------------------ |
| Validate      | All pushes/PRs         | Format check, init, validate                     |
| Security Scan | After validation       | tfsec, Checkov security analysis                 |
| Test          | PRs only               | Run Terraform native tests                       |
| Cost Estimate | PRs only               | Infracost breakdown and comparison               |
| Plan          | PRs and manual trigger | Generate execution plan                          |
| Apply         | Manual trigger only    | Deploy infrastructure (requires approval)        |
| Destroy       | Manual trigger only    | Tear down infrastructure (requires confirmation) |

---

## Prerequisites

### 1. Terraform Installation

Install Terraform version `${{ values.terraform_version }}` or later:

```bash
# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

### 2. Cloud Provider Credentials

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

#### AWS Credentials

```bash
# Option 1: AWS CLI configuration
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS SSO (recommended)
aws sso login --profile your-profile
export AWS_PROFILE=your-profile
```

For CI/CD, configure OIDC authentication:

```bash
# Create OIDC provider (one-time setup)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

#### Azure Credentials

```bash
# Azure CLI login
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Service Principal for automation
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" \
  --scopes="/subscriptions/your-subscription-id"

# Environment variables
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

#### GCP Credentials

```bash
# Google Cloud SDK login
gcloud auth application-default login

# Set project
gcloud config set project your-project-id

# Service Account for automation
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

gcloud projects add-iam-policy-binding your-project-id \
  --member="serviceAccount:terraform-sa@your-project-id.iam.gserviceaccount.com" \
  --role="roles/editor"

# Download key file
gcloud iam service-accounts keys create ~/terraform-sa-key.json \
  --iam-account=terraform-sa@your-project-id.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-sa-key.json
```
{%- endif %}

### 3. Terraform State Backend

Configure remote state storage for team collaboration:

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

#### AWS S3 Backend

```bash
# Create S3 bucket
aws s3 mb s3://${{ values.name }}-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${{ values.name }}-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${{ values.name }}-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name ${{ values.name }}-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

#### Azure Blob Backend

```bash
# Create resource group
az group create --name terraform-state-rg --location eastus

# Create storage account
az storage account create \
  --name ${{ values.name | replace('-', '') }}tfstate \
  --resource-group terraform-state-rg \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name ${{ values.name | replace('-', '') }}tfstate
```
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

#### GCP Cloud Storage Backend

```bash
# Create bucket
gsutil mb -l us-central1 gs://${{ values.name }}-terraform-state

# Enable versioning
gsutil versioning set on gs://${{ values.name }}-terraform-state
```
{%- endif %}

### 4. GitHub Repository Setup

Configure secrets in **Settings > Secrets and variables > Actions**:

| Secret                         | Description                          | Required |
| ------------------------------ | ------------------------------------ | -------- |
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
| `AWS_ROLE_ARN`                 | IAM role ARN for OIDC authentication | Yes      |
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
| `AZURE_CLIENT_ID`              | Azure AD application client ID       | Yes      |
| `AZURE_TENANT_ID`              | Azure AD tenant ID                   | Yes      |
| `AZURE_SUBSCRIPTION_ID`        | Azure subscription ID                | Yes      |
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | GCP Workload Identity provider     | Yes      |
| `GCP_SERVICE_ACCOUNT`          | GCP service account email            | Yes      |
{%- endif %}
| `INFRACOST_API_KEY`            | Infracost API key (cost estimation)  | Optional |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables for your environment
# vim terraform.tfvars

# Initialize Terraform
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Preview changes
terraform plan -var="environment=dev"

# Apply changes
terraform apply -var="environment=dev"

# View outputs
terraform output

# Destroy resources (when done)
terraform destroy -var="environment=dev"
```

### Testing with Terraform Test

This module includes native Terraform tests for validation:

```bash
# Run all tests
terraform test

# Run specific test file
terraform test -filter=tests/unit/module.tftest.hcl

# Run with verbose output
terraform test -verbose

# Run integration tests (creates real resources)
terraform test -filter=tests/integration/full_stack.tftest.hcl
```

#### Test Structure

| Test Type   | Location                            | Purpose                                |
| ----------- | ----------------------------------- | -------------------------------------- |
| Unit        | `tests/unit/module.tftest.hcl`      | Validate configuration without deploy  |
| Integration | `tests/integration/full_stack.tftest.hcl` | End-to-end testing with real resources |

### Using Examples

Each provider has a standalone example configuration:

```bash
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
# AWS Example
cd examples/aws
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
# Azure Example
cd examples/azure
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
# GCP Example
cd examples/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
{%- endif %}
```

### Running the CI/CD Pipeline

#### Automatic Triggers

| Trigger      | Actions                                      |
| ------------ | -------------------------------------------- |
| Pull Request | Validate, Security Scan, Test, Plan, Cost    |
| Push to main | Validate, Security Scan                      |

#### Manual Deployment

1. Navigate to **Actions** tab in GitHub
2. Select **Terraform CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **environment**: `dev`, `staging`, or `prod`
   - **action**: `plan`, `apply`, or `destroy`
5. Click **Run workflow**

For `staging` and `prod` environments, approval from designated reviewers is required.

---

## Publishing to Terraform Registry

### Public Registry

To publish to the [Terraform Registry](https://registry.terraform.io/):

1. **Repository Requirements**:
   - Must be public on GitHub
   - Named `terraform-<PROVIDER>-<NAME>` (e.g., `terraform-aws-${{ values.name }}`)
   - Contains `main.tf`, `variables.tf`, `outputs.tf` at root

2. **Create a Release**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Register Module**:
   - Go to [registry.terraform.io](https://registry.terraform.io)
   - Sign in with GitHub
   - Click "Publish" > "Module"
   - Select your repository

### Private Registry (Terraform Cloud)

```hcl
# Configure in terraform.tf
terraform {
  cloud {
    organization = "your-org"
    
    workspaces {
      name = "${{ values.name }}-dev"
    }
  }
}
```

### Referencing Published Modules

```hcl
# From public registry
module "${{ values.name }}" {
  source  = "your-org/${{ values.name }}/${{ values.provider }}"
  version = "~> 1.0"
  
  environment  = "prod"
  project_name = "my-project"
}

# From private registry
module "${{ values.name }}" {
  source  = "app.terraform.io/your-org/${{ values.name }}/${{ values.provider }}"
  version = "~> 1.0"
}
```

---

## Inputs

### Common Variables

| Name           | Description                              | Type          | Default              | Required |
| -------------- | ---------------------------------------- | ------------- | -------------------- | -------- |
| `environment`  | Environment name (dev, staging, prod)    | `string`      | `"dev"`              | No       |
| `project_name` | Project name for resource naming         | `string`      | `"${{ values.name }}"` | No       |
| `tags`         | Additional tags for all resources        | `map(string)` | `{}`                 | No       |

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

### AWS Variables

| Name                     | Description                    | Type           | Default                                    | Required |
| ------------------------ | ------------------------------ | -------------- | ------------------------------------------ | -------- |
| `aws_region`             | AWS region                     | `string`       | `"us-east-1"`                              | No       |
| `aws_vpc_cidr`           | CIDR block for VPC             | `string`       | `"10.0.0.0/16"`                            | No       |
| `aws_availability_zones` | List of availability zones     | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | No       |
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

### Azure Variables

| Name                        | Description                  | Type     | Default        | Required |
| --------------------------- | ---------------------------- | -------- | -------------- | -------- |
| `azure_location`            | Azure region                 | `string` | `"eastus"`     | No       |
| `azure_resource_group_name` | Resource group name          | `string` | `""`           | No       |
| `azure_vnet_cidr`           | CIDR block for VNet          | `string` | `"10.1.0.0/16"` | No       |
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

### GCP Variables

| Name               | Description               | Type     | Default          | Required |
| ------------------ | ------------------------- | -------- | ---------------- | -------- |
| `gcp_project_id`   | GCP project ID            | `string` | -                | Yes      |
| `gcp_region`       | GCP region                | `string` | `"us-central1"`  | No       |
| `gcp_zone`         | GCP zone for zonal resources | `string` | `"us-central1-a"` | No       |
| `gcp_network_cidr` | CIDR block for VPC        | `string` | `"10.2.0.0/16"`  | No       |
{%- endif %}

### Feature Flags

| Name                   | Description                  | Type   | Default | Required |
| ---------------------- | ---------------------------- | ------ | ------- | -------- |
| `enable_compute`       | Enable compute resources     | `bool` | `true`  | No       |
| `enable_network`       | Enable network resources     | `bool` | `true`  | No       |
| `enable_storage`       | Enable storage resources     | `bool` | `true`  | No       |
| `enable_database`      | Enable database resources    | `bool` | `false` | No       |
| `enable_security`      | Enable security resources    | `bool` | `true`  | No       |
| `enable_observability` | Enable observability         | `bool` | `true`  | No       |
| `enable_kubernetes`    | Enable Kubernetes resources  | `bool` | `false` | No       |
| `enable_serverless`    | Enable serverless resources  | `bool` | `false` | No       |

---

## Outputs

### Common Outputs

| Name           | Description              |
| -------------- | ------------------------ |
| `environment`  | Current environment name |
| `project_name` | Project name             |

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

### AWS Outputs

| Name                     | Description                 |
| ------------------------ | --------------------------- |
| `aws_region`             | AWS region                  |
| `aws_vpc_id`             | VPC identifier              |
| `aws_public_subnet_ids`  | List of public subnet IDs   |
| `aws_private_subnet_ids` | List of private subnet IDs  |
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

### Azure Outputs

| Name                        | Description              |
| --------------------------- | ------------------------ |
| `azure_location`            | Azure region             |
| `azure_resource_group_name` | Resource group name      |
| `azure_vnet_id`             | Virtual network ID       |
| `azure_subnet_ids`          | Map of subnet IDs        |
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

### GCP Outputs

| Name               | Description           |
| ------------------ | --------------------- |
| `gcp_project_id`   | GCP project ID        |
| `gcp_region`       | GCP region            |
| `gcp_network_name` | VPC network name      |
| `gcp_subnet_names` | List of subnet names  |
{%- endif %}

Access outputs via:

```bash
# Single output
terraform output environment

# JSON format (useful for scripting)
terraform output -json

# Specific output as raw value
terraform output -raw aws_vpc_id
```

---

## Troubleshooting

### Initialization Errors

**Error: Failed to install provider**

```
Error: Failed to install provider
Could not retrieve the list of available versions
```

**Resolution:**
1. Check internet connectivity
2. Verify provider source in `versions.tf`
3. Clear cache and retry:
   ```bash
   rm -rf .terraform
   terraform init -upgrade
   ```

### Authentication Errors

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

**AWS: No valid credential sources found**

```
Error: configuring Terraform AWS Provider: no valid credential sources
```

**Resolution:**
1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check environment variables are set
3. Ensure IAM role has required permissions
4. For OIDC, verify trust policy includes your repository
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

**Azure: Authorization failed**

```
Error: Authorization failed for subscription
```

**Resolution:**
1. Verify Azure login: `az account show`
2. Check service principal permissions
3. Ensure correct subscription is selected
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

**GCP: Could not find default credentials**

```
Error: could not find default credentials
```

**Resolution:**
1. Run `gcloud auth application-default login`
2. Verify project: `gcloud config get-value project`
3. Check service account permissions
{%- endif %}

### State Lock Issues

**Error: Error acquiring state lock**

```
Error: Error acquiring the state lock
Lock Info: ...
```

**Resolution:**
1. Wait for other operations to complete
2. If stuck, force unlock (use with caution):
   ```bash
   terraform force-unlock LOCK_ID
   ```

### Validation Failures

**Error: Invalid variable value**

```
Error: Invalid value for variable
```

**Resolution:**
1. Check `terraform.tfvars` values match variable constraints
2. Review variable validation rules in `variables.tf`
3. Ensure environment is one of: `dev`, `staging`, `prod`

### Security Scan Failures

**tfsec/Checkov reporting issues**

| Finding                       | Resolution                                           |
| ----------------------------- | ---------------------------------------------------- |
| Missing encryption            | Enable encryption on storage/database resources      |
| Open security group rules     | Restrict CIDR ranges in security group definitions   |
| Missing logging               | Enable logging on applicable resources               |
| Public access enabled         | Review and restrict public access where not needed   |

To allow warnings without blocking:

```yaml
# In .github/workflows/terraform.yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

---

## Related Templates

| Template                                                           | Description                              |
| ------------------------------------------------------------------ | ---------------------------------------- |
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
| [aws-vpc](/docs/default/template/aws-vpc)                          | AWS VPC networking                       |
| [aws-eks](/docs/default/template/aws-eks)                          | Amazon EKS Kubernetes cluster            |
| [aws-rds](/docs/default/template/aws-rds)                          | Amazon RDS database                      |
| [aws-lambda](/docs/default/template/aws-lambda)                    | AWS Lambda serverless function           |
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
| [azure-vnet](/docs/default/template/azure-vnet)                    | Azure Virtual Network                    |
| [azure-aks](/docs/default/template/azure-aks)                      | Azure Kubernetes Service                 |
| [azure-sql](/docs/default/template/azure-sql)                      | Azure SQL Database                       |
| [azure-functions](/docs/default/template/azure-functions)          | Azure Functions                          |
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
| [gcp-vpc](/docs/default/template/gcp-vpc)                          | Google Cloud VPC                         |
| [gcp-gke](/docs/default/template/gcp-gke)                          | Google Kubernetes Engine                 |
| [gcp-cloudsql](/docs/default/template/gcp-cloudsql)                | Cloud SQL database                       |
| [gcp-cloud-functions](/docs/default/template/gcp-cloud-functions)  | Google Cloud Functions                   |
{%- endif %}
| [terraform-module](/docs/default/template/terraform-module)        | Generic Terraform module (this template) |

---

## References

### Terraform Documentation

- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform CLI Commands](https://developer.hashicorp.com/terraform/cli/commands)
- [Terraform Testing Framework](https://developer.hashicorp.com/terraform/language/tests)
- [Module Development Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Publishing Modules to Registry](https://developer.hashicorp.com/terraform/registry/modules/publish)

### Provider Documentation

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs)
- [GitHub Actions OIDC with GCP](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
{%- endif %}

### Security & Compliance

- [tfsec - Terraform Security Scanner](https://aquasecurity.github.io/tfsec/)
- [Checkov - Policy as Code](https://www.checkov.io/1.Welcome/What%20is%20Checkov.html)
- [Infracost - Cloud Cost Estimates](https://www.infracost.io/docs/)

### Best Practices

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Google Cloud Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform)
- [AWS Terraform Best Practices](https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/)
