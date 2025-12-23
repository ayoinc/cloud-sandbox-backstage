# Getting Started with Terraform Modules

This comprehensive guide will walk you through setting up and deploying Terraform modules across AWS, Azure, and GCP. Follow these steps to configure your environment, authenticate with cloud providers, and deploy your first infrastructure.

Our Terraform modules provide reusable, production-ready infrastructure components that you can combine to build complete architectures. Most modules create foundational resources like networks, compute instances, security groups, and storage that work together seamlessly.

```mermaid
graph TD
    A[Terraform Modules Repository] --> B[Network Layer]
    A --> C[Compute Layer]
    A --> D[Security Layer]
    A --> E[Storage Layer]
    
    B --> B1[VPC/Virtual Network]
    B --> B2[Subnets]
    B --> B3[Route Tables
    C --> C1[EC2/VM Instances]
    C --> C2[ECS/AKS/EKS Clusters]
    C --> C3[Lambda/Functions]
    D --> D1[Security Groups/Firewalls]
    D --> D2[IAM/RBAC Roles]
    E --> E1[S3/Blob/Cloud Storage]
    E --> E2[RDS/SQL/Cloud SQL]
    
    B1 --> F[Complete Application Stack]
    B2 --> F
    C1 --> F
    D1 --> F
    E1 --> F
```

The modules create this architecture - foundational networking and security that enable deploying applications and data stores.

## Two Ways to Use These Modules

You can start using our Terraform modules in two ways:

1. **Start with Examples** - Ready-to-deploy complete stacks (`/examples` folder)
2. **Compose Your Own** - Select individual modules (`/modules` folder)

### Explore Examples (`/examples` folder)

Our examples show complete, production-ready stacks with multiple modules composed together:

| Example | Purpose | Modules Used |
|---------|---------|--------------|
| `simple-vpc` | Basic network setup | VPC, subnets, route tables |
| `web-app` | Web application stack | VPC, EC2, ALB, security groups |
| `microservices` | Containerized services | EKS/AKS, VPC, IAM |
| `data-pipeline` | Data processing workflow | S3, Lambda, RDS |
| `multi-region` | Global deployment | VPC, Route53, CloudFront |

```bash
# Start with an example
git clone https://github.com/company/terraform-modules.git
cd terraform-modules/examples/simple-vpc
terraform init
terraform plan
```

### Build from Modules (`/modules` folder)

For custom architectures, pick specific modules from the catalog and compose them:

```bash
# Folder structure
cd modules/
ls -la
# aws-vpc/
# aws-ec2/
# aws-rds/
# aws-security-groups/
# azure-vnet/
# gcp-vpc/
```

Each module is documented with inputs, outputs, and usage examples. See [Generating Documentation](#generating-documentation) below for auto-generated docs.

## Table of contents
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Authentication Setup](#authentication-setup)
- [Backend Configuration](#backend-configuration)
- [Basic Workflow](#basic-workflow)
- [First Module Deployment](#first-module-deployment)
- [Module Composition](#module-composition)
- [Workspaces](#workspaces)
- [Variables Management](#variables-management)
- [Generating Documentation](#generating-documentation)
- [Visualizing Infrastructure](#visualizing-infrastructure)
- [Next Steps](#next-steps)

## Prerequisites

Before starting, ensure you have the following tools installed and configured:

### Terraform Installation

Install Terraform 1.0 or higher:

```bash
# macOS (using Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux (using apt)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Windows (using Chocolatey)
choco install terraform

# Verify installation
terraform version
# Expected output: Terraform v1.x.x
```

### AWS CLI Setup

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-west-2)
# Enter output format (e.g., json)

# Verify configuration
aws sts get-caller-identity
# Expected output shows your AWS account and user details
```

### Azure CLI Setup

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login
# Browser window will open for authentication

# Verify subscription
az account show
# Expected output shows your subscription details

# For service principal creation (if needed)
az ad sp create-for-rbac --name "terraform-sp" --role Contributor --scopes /subscriptions/YOUR-SUBSCRIPTION-ID
```

### GCP CLI Setup

```bash
# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update && sudo apt install google-cloud-cli

# Initialize and authenticate
gcloud init
gcloud auth login
gcloud auth application-default login

# Configure project
gcloud config set project YOUR-PROJECT-ID

# Verify configuration
gcloud info
```

## Installation Methods

### Using Git Source with Authentication

For private repositories, configure Git credentials first:

```bash
# Set up SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Or use Git credential helper
git config --global credential.helper store
```

Reference modules in Terraform:

```hcl
# SSH protocol with private key
module "vpc" {
  source = "git::ssh://git@github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"
  
  name      = "production-vpc"
  cidr      = "10.0.0.0/16"
  azs       = ["us-west-2a", "us-west-2b"]
}

# HTTPS with token (for CI/CD)
module "vpc" {
  source = "git::https://TOKEN@github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"
  
  name      = "production-vpc"
  cidr      = "10.0.0.0/16"
}

# Generic HTTPS (requires manual auth on first use)
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"
}
```

### Using Local Path for Development

Clone the repository for local development:

```bash
# Clone the modules repository
git clone https://github.com/company/terraform-modules.git

# Navigate to your project directory
cd my-terraform-project

# Create a main.tf that references local modules
```

```hcl
module "vpc" {
  source = "../terraform-modules/aws/vpc"
  
  name      = "dev-vpc"
  cidr      = "10.0.0.0/16"
  azs       = ["us-west-2a", "us-west-2b"]
}

# Override variables locally
module "vpc" {
  source = "../terraform-modules/aws/vpc"
  
  name      = try(var.vpc_name, "default-vpc")
  cidr      = var.cidr_block
  azs       = var.availability_zones
}
```

### Using Terraform Registry

For public modules, use Terraform Registry:

```hcl
# AWS VPC from public registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  name      = "vpc"
  cidr      = "10.0.0.0/16"
  azs       = data.aws_availability_zones.available.names
}

# Azure Resource Group
module "resource_group" {
  source  = "Azure/resource-group/azurerm"
  version = "~> 1.0"
  
  resource_group_name = "production-rg"
  location           = "eastus"
}
```

## Authentication Setup

### AWS Authentication Methods

#### Method 1: AWS Credentials File

```bash
# Edit ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
region = us-west-2

[production]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
region = us-east-1
```

```bash
# Use specific profile
export AWS_PROFILE=production
terraform plan

# Or specify in provider block
provider "aws" {
  profile = "production"
  region  = "us-east-1"
}
```

#### Method 2: Environment Variables

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-west-2"
export AWS_SESSION_TOKEN="your-session-token-here"  # For temporary credentials

# Run Terraform
terraform plan
```

#### Method 3: IAM Roles

```hcl
# For EC2 instances with instance profiles
provider "aws" {
  region = "us-west-2"
  # No credentials needed - uses instance metadata
}

# For cross-account role assumption
provider "aws" {
  region = "us-west-2"
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
    session_name = "terraform-session"
    external_id  = "unique-external-id"
  }
}
```

### Azure Authentication Methods

#### Method 1: Azure CLI Login

```bash
# Interactive login (for development)
az login

# Service Principal login (for CI/CD)
az login --service-principal \
  --username APP_ID \
  --password CLIENT_SECRET \
  --tenant TENANT_ID

# Managed Identity (for Azure resources)
az login --identity
```

#### Method 2: Service Principal in Terraform

```hcl
# Main configuration
terraform {
  backend "azurerm" {
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
  }
}

provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# variables.tf
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
  sensitive   = true
}

variable "client_id" {
  type        = string
  description = "Service principal client ID"
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Service principal client secret"
  sensitive   = true
}
```

### GCP Authentication Methods

#### Method 1: Application Default Credentials

```bash
# Login and create default credentials
gcloud auth application-default login

# Point to service account key file
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-file.json"
```

#### Method 2: Service Account in Terraform

```hcl
provider "google" {
  credentials = file(var.service_account_key)
  project     = var.project_id
  region      = var.region
}

# variables.tf
variable "service_account_key" {
  type        = string
  description = "Path to service account key JSON file"
  default     = "~/.config/gcloud/service-account-key.json"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Default region"
  default     = "us-central1"
}
```

## Backend Configuration

### AWS S3 Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "network/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
    
    # Optional: Enable versioning
    acl = "bucket-owner-full-control"
    
    # Optional: Assume role for backend access
    role_arn = "arn:aws:iam::123456789012:role/TerraformBackendRole"
  }
}

# Create the S3 bucket and DynamoDB table
# Run these commands before terraform init
```

```bash
#!/bin/bash
# create-backend.sh

BUCKET="terraform-state-prod"
TABLE="terraform-locks"
REGION="us-west-2"

# Create S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Backend infrastructure created successfully!"
```

### Azure Blob Storage Backend

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateprodsa"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    
    # Optional: Use access key
    # access_key           = "your-access-key"
    
    # Optional: Use SAS token
    # sas_token            = "your-sas-token"
  }
}
```

```bash
#!/bin/bash
# create-azure-backend.sh

RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstateprodsa"
CONTAINER="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create storage account
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query '[0].value' \
  -o tsv)

# Create blob container
az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY"

# Enable soft delete (optional, for added protection)
az storage account blob-service-properties update \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP"

echo "Azure backend created successfully!"
echo "Access Key: $ACCOUNT_KEY"
```

### Google Cloud Storage Backend

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket  = "terraform-state-prod"
    prefix  = "terraform/state"
    
    # Optional: Use specific credentials
    # credentials = "path/to/service-account.json"
    
    # Optional: Enable encryption
    # encryption_key = "your-encryption-key"
  }
}
```

```bash
#!/bin/bash
# create-gcs-backend.sh

PROJECT_ID="your-project-id"
BUCKET="terraform-state-prod"
LOCATION="US"

# Create storage bucket
gsutil mb -p "$PROJECT_ID" -l "$LOCATION" "gs://$BUCKET/"

# Enable versioning
gsutil versioning set on "gs://$BUCKET/"

# Set retention policy (optional)
gsutil retention set 7d "gs://$BUCKET/"

# Enable uniform bucket-level access
gsutil uniformbucketlevelaccess set on "gs://$BUCKET/"

# Remove public access
gsutil iam ch -d allUsers:objectViewer "gs://$BUCKET/"

echo "GCS backend created successfully!"
```

## Basic Workflow

### Step 1: Initialize Terraform

```bash
# Basic initialization
terraform init

# Initialize with backend configuration
terraform init -backend-config="bucket=terraform-state-prod" \
               -backend-config="key=project/terraform.tfstate" \
               -backend-config="region=us-west-2"

# Example output:
# Initializing the backend...
# Successfully configured the backend "s3"! Terraform will automatically
# use this backend unless the backend configuration changes.
#
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 5.0"...
# - Installing hashicorp/aws v5.31.0...
# - Installed hashicorp/aws v5.31.0 (signed by HashiCorp)
#
# Terraform has been successfully initialized!
```

**Troubleshooting init errors:**

- **Backend authentication errors:** Check your credentials and permissions
- **Plugin download failures:** Check network connectivity and proxy settings
- **State file locked:** Use `terraform force-unlock` if you're certain no other process is running

### Step 2: Validate Configuration

```bash
# Validate syntax and configuration
terraform validate

# Format code
terraform fmt -recursive

# Example output:
# Success! The configuration is valid.
```

### Step 3: Plan Changes

```bash
# Basic plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Plan with specific variables file
terraform plan -var-file="production.tfvars" -out=tfplan

# Plan with target resource
terraform plan -target=module.vpc

# Example output:
# Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
#   + create
#
# Terraform will perform the following actions:
#
#   # module.vpc.aws_vpc.this[0] will be created
#   + resource "aws_vpc" "this" {
#       + arn                                  = (known after apply)
#       + cidr_block                           = "10.0.0.0/16"
#       + id                                   = (known after apply)
#       + tags                                 = {
#           + "Name" = "production-vpc"
#         }
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.
```

### Step 4: Apply Configuration

```bash
# Apply saved plan
terraform apply tfplan

# Apply with auto-approval
terraform apply -auto-approve

# Apply specific target
terraform apply -target=module.vpc

# Example output:
# module.vpc.aws_vpc.this[0]: Creating...
# module.vpc.aws_vpc.this[0]: Creation complete after 3s [id=vpc-0abcd1234efgh5678]
#
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Troubleshooting apply errors:**

- **Permission denied:** Check IAM policies and credentials
- **Resource already exists:** Import existing resources or use data sources
- **Rate limiting:** Add `depends_on` or use `-parallelism=1` flag

### Step 5: Show Current State

```bash
# Show current state
terraform show

# Show specific resource
terraform state show module.vpc.aws_vpc.this[0]

# List all resources
terraform state list
```

### Step 6: Destroy Infrastructure

```bash
# Plan destroy
terraform plan -destroy

# Destroy with confirmation
terraform destroy

# Auto-approve destroy
terraform destroy -auto-approve

# Destroy specific target
terraform destroy -target=module.vpc.aws_vpc.this[0]
```

## First Module Deployment

### AWS VPC Deployment

```hcl
# Create main.tf
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"
  
  name      = var.environment == "prod" ? "production-vpc" : "${var.environment}-vpc"
  cidr      = var.vpc_cidr
  azs       = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, var.az_count) :
                      cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, var.az_count) :
                      cidrsubnet(var.vpc_cidr, 8, k + 10)]
  
  enable_nat_gateway    = true
  single_nat_gateway    = false
  enable_vpn_gateway    = false
  enable_dns_hostnames  = true
  enable_dns_support    = true
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create variables.tf
variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones"
  default     = 2
}

# Create outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

# Create terraform.tfvars
environment = "dev"
vpc_cidr    = "10.0.0.0/16"
az_count    = 2
```

```bash
# Deploy AWS VPC
terraform init
terraform plan -out=vpc-plan
terraform apply vpc-plan

# Verify in AWS Console
# Navigate to VPC Dashboard -> Your VPCs
# Expected: VPC "dev-vpc" with subnets created
```

### Azure Resource Group Deployment

```hcl
# main.tf
module "resource_group" {
  source = "git::https://github.com/company/terraform-modules.git//azure/resource-group?ref=v1.0.0"
  
  name     = "${var.environment}-rg"
  location = var.location
  
  tags = {
    Environment     = var.environment
    ManagedBy       = "Terraform"
    CostCenter      = var.cost_center
  }
}

module "vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/virtual-network?ref=v1.0.0"
  
  name                = "${var.environment}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.vnet_cidr]
  
  subnets = {
    web = {
      address_prefixes = [cidrsubnet(var.vnet_cidr, 8, 1)]
      service_endpoints = ["Microsoft.Web"]
    }
    app = {
      address_prefixes = [cidrsubnet(var.vnet_cidr, 8, 2)]
      service_endpoints = ["Microsoft.Sql"]
    }
  }
}

# variables.tf
variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "eastus"
}

variable "vnet_cidr" {
  type        = string
  description = "Virtual network CIDR"
  default     = "10.0.0.0/16"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag"
  default     = "engineering"
}
```

### GCP VPC Deployment

```hcl
# main.tf
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.0.0"
  
  project_id   = var.project_id
  network_name = "${var.environment}-vpc"
  routing_mode = "GLOBAL"
  
  subnets = [
    {
      subnet_name   = "${var.environment}-subnet-1"
      subnet_ip     = "10.0.1.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "${var.environment}-subnet-2"
      subnet_ip     = "10.0.2.0/24"
      subnet_region = "us-east1"
    }
  ]
  
  secondary_ranges = {
    "${var.environment}-subnet-1" = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.1.0.0/16"
      }
    ]
  }
}
```

## Module Composition

### Combining Multiple Modules

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Network module
module "vpc" {
  source = "../modules/aws/vpc"
  
  name = "${var.environment}-vpc"
  cidr = "10.0.0.0/16"
  azs  = data.aws_availability_zones.available.names
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  
  tags = merge(var.common_tags, { Component = "network" })
}

# Security module
module "security_groups" {
  source = "../modules/aws/security-groups"
  
  vpc_id = module.vpc.vpc_id
  
  rules = {
    "allow_http" = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "allow_https" = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# Compute module
module "ec2_instances" {
  source = "../modules/aws/ec2"
  
  instance_count = var.instance_count
  instance_type  = var.instance_type
  subnet_ids     = module.vpc.public_subnets
  security_group_ids = [module.security_groups.web_sg_id]
  
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = var.environment
  }))
  
  tags = var.common_tags
}

# Database module
module "rds" {
  source = "../modules/aws/rds"
  
  identifier = "${var.environment}-database"
  
  subnet_ids = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_groups.database_sg_id]
  
  allocated_storage = var.db_allocated_storage
  instance_class    = var.db_instance_class
  engine            = "postgres"
  engine_version    = "14.7"
  
  backup_retention_period = var.environment == "prod" ? 30 : 7
  
  tags = var.common_tags
}

# Transfer data between modules
locals {
  database_endpoint = module.rds.database_endpoint
  instance_ips     = module.ec2_instances.private_ips
}

# variables.tf
variable "environment" {
  type        = string
  description = "Environment name"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "db_allocated_storage" {
  type        = number
  description = "Database allocated storage in GB"
  default     = 100
}

variable "db_instance_class" {
  type        = string
  description = "Database instance class"
  default     = "db.t3.medium"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}
```

## Workspaces

### Environment Separation

```bash
# Create workspaces
terraform workspace new development
terraform workspace new staging
terraform workspace new production

# List workspaces
terraform workspace list
# Expected output:
# * default
#   development
#   staging
#   production

# Switch between workspaces
terraform workspace select production

# Show current workspace
terraform workspace show
# Expected output: production
```

```hcl
# Use workspace in configuration
locals {
  environment = terraform.workspace
  
  # Set environment-specific values
  environment_suffix = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  
  # Map environments to regions
  region_map = {
    development = "us-west-2"
    staging     = "us-east-1"
    production  = "us-east-1"
  }
  
  region = lookup(local.region_map, terraform.workspace, "us-west-2")
}

# Configure workspace-specific resources
provider "aws" {
  region = local.region
  
  default_tags {
    tags = {
      Environment = local.environment
      ManagedBy   = "Terraform"
      Workspace   = terraform.workspace
    }
  }
}

# Create environment-specific naming
module "vpc" {
  source = "../modules/aws/vpc"
  
  name = "${var.project_name}${local.environment_suffix}-vpc"
  
  # Enable NAT only in non-dev environments
  enable_nat_gateway = terraform.workspace != "development"
}
```

### Workspace Variables

```bash
# Create workspace-specific variable files
echo 'environment = "dev"' > development.tfvars
echo 'environment = "staging"' > staging.tfvars
echo 'environment = "production"' > production.tfvars

# Use variables with workspaces
terraform workspace select development
terraform plan -var-file="development.tfvars"

terraform workspace select production  
terraform plan -var-file="production.tfvars"
```

## Variables Management

### Variable Precedence

Terraform loads variables in the following order (later sources override earlier):

1. Environment variables (`TF_VAR_*`)
2. terraform.tfvars file
3. terraform.tfvars.json file  
4. Any `.auto.tfvars` or `.auto.tfvars.json` files, in lexical order
5. `-var` and `-var-file` command-line options

### Using .tfvars Files

```bash
# Create environment-specific variable files
# production.tfvars
project_name           = "myapp"
environment            = "production"
instance_type          = "m5.large"
desired_capacity       = 10
enable_monitoring      = true
backup_retention_days  = 30

# development.tfvars
project_name           = "myapp"
environment            = "development"
instance_type          = "t3.medium"
desired_capacity       = 2
enable_monitoring      = false
backup_retention_days  = 7
```

```bash
# Use variable files
terraform plan -var-file="production.tfvars"
terraform apply -var-file="production.tfvars"
```

### Using Environment Variables

```bash
# Set variables via environment
export TF_VAR_environment="production"
export TF_VAR_instance_type="m5.large"
export TF_VAR_desired_capacity="10"

# Verify variables are set
env | grep TF_VAR_

# Run Terraform
terraform plan
```

### Variable File Structure Best Practices

```bash
# project/
# ├── main.tf
# ├── variables.tf
# ├── terraform.tfvars          # Common variables
# ├── terraform.tfvars.example  # Example file for new users
# ├── production.tfvars         # Production-specific variables
# ├── staging.tfvars            # Staging-specific variables
# └── development.tfvars        # Development-specific variables
```

```hcl
# variables.tf with sensible defaults
variable "environment" {
  type        = string
  description = "Environment name"
  default     = "development"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring"
  default     = false
}

# Override in production.tfvars
# instance_type = "m5.large"
# enable_monitoring = true
```

## Generating Documentation

We use `terraform-docs` to auto-generate module documentation from variables and outputs.

```bash
# Install terraform-docs
# macOS
brew install terraform-docs

# Linux
curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.17.0/terraform-docs-v0.17.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/

# Generate docs for a module
cd modules/aws-vpc
terraform-docs markdown . > README.md

# Generate docs for all modules
find modules -type d -mindepth 1 -maxdepth 1 -exec sh -c 'cd "$1" && terraform-docs md . > README.md' _ {} \;
```

Each module's `README.md` contains:
- **Usage example** - Copy-paste ready code
- **Requirements** - Terraform and provider versions
- **Inputs** - All variables with types, defaults, and descriptions
- **Outputs** - All outputs with descriptions
- **Resources** - List of resources created
- **Optional modules** - Related or dependent modules

## Visualizing Infrastructure

### Using Terraform Graph

Visualize your infrastructure dependencies:

```bash
# Generate graph for current configuration
terraform graph | dot -Tsvg > infrastructure.svg

# Generate plan graph
terraform plan -out=tfplan
terraform show -json tfplan | terraform-graph | dot -Tsvg > plan-graph.svg

# View graph directly (requires graphviz)
terraform graph | dot -Tpng | display
```

**Note:** Install `graphviz` first (`brew install graphviz` on macOS, `sudo apt install graphviz` on Ubuntu)

### Using Mermaid Diagrams

For documentation, we use Mermaid diagrams. Create visual representations of your architecture:

```bash
# From our examples directory
graph LR
    A[User] --> B[ALB]
    B --> C[EC2 Instance]
    C --> D[RDS Database]
    C --> E[S3 Bucket]
```

## Next Steps

### Where to Start

**For most users, we recommend starting with the VPC module.** Networking is the foundation of all infrastructure, and understanding how to deploy a VPC with proper subnets, routing, and security will serve you well across all cloud providers.

```bash
# Quick start - deploy a VPC
cd terraform-modules/examples/simple-vpc
terraform init
terraform plan -out=vpc.tfplan
terraform apply vpc.tfplan
```

### Learn More

**Official Terraform Documentation:**
- [Terraform Language](https://www.terraform.io/docs/language)
- [Provider Documentation](https://registry.terraform.io/browse/providers)
- [Module Registry](https://registry.terraform.io/)

**Explore Module Catalog:**
- [AWS Modules](modules/aws/) - VPC, EC2, RDS, ECS, EKS, Lambda
- [Azure Modules](modules/azure/) - Virtual Networks, VMs, SQL, AKS
- [GCP Modules](modules/gcp/) - VPC, Compute Engine, Cloud SQL, GKE

**Advanced Examples:**
- [Web Application Stack](examples/web-app/) - Full web app with load balancing
- [Microservices Architecture](examples/microservices/) - Container orchestration
- [Data Pipeline](examples/data-pipeline/) - Serverless data processing
- [Multi-Region Deployment](examples/multi-region/) - Global infrastructure

### Best Practices

Review our best practices guide:
- [Module Composition](best-practices.md#module-composition)
- [State Management](best-practices.md#state-management)
- [Security](best-practices.md#security)
- [Cost Optimization](best-practices.md#cost-optimization)

### CI/CD Integration

Set up automated deployments:
- [GitHub Actions](ci-cd/github-actions.md)
- [GitLab CI/CD](ci-cd/gitlab-ci.md)
- [Jenkins Pipeline](ci-cd/jenkins.md)
- [Atlantis PR Automation](ci-cd/atlantis.md)

### Getting Help

- [Troubleshooting Guide](troubleshooting.md)
- [FAQ](faq.md)
- [GitHub Issues](https://github.com/company/terraform-modules/issues)
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core/27)

---

*Ready to deploy? Start with `examples/simple-vpc` to build your foundation, then add compute, security, and storage modules to create your complete infrastructure stack.*