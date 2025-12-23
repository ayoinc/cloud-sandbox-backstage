# Terraform Modules

Welcome to the Terraform Modules documentation. This library contains reusable, production-ready Terraform modules for provisioning cloud infrastructure across AWS, Azure, and GCP.

## Overview

Our comprehensive library of Terraform modules provides infrastructure-as-code solutions designed for enterprise-scale deployments. These modules enable organizations to provision, manage, and scale cloud infrastructure consistently and securely across multiple cloud providers.

### Why Infrastructure-as-Code (IaC) is Critical

Infrastructure-as-Code transforms infrastructure management by treating infrastructure definitions as versioned, testable, and reusable code:

**Consistency & Standardization**: Eliminate configuration drift and ensure consistent environments across development, staging, and production. All infrastructure changes are codified, reviewed, and version-controlled.

**Speed & Efficiency**: Deploy entire infrastructure stacks in minutes rather than days or weeks. Automated provisioning reduces manual errors and accelerates delivery cycles.

**Scalability**: Seamlessly scale infrastructure horizontally and vertically to meet changing business demands without manual intervention.

**Cost Optimization**: Track infrastructure costs through code, implement automated scaling policies, and easily identify underutilized resources for optimization.

**Disaster Recovery**: Infrastructure definitions serve as living documentation and enable rapid recovery by redeploying entire environments with a single command.

**Audit & Compliance**: Every change is tracked in version control, providing complete audit trails and enabling compliance with regulatory requirements like SOC 2, ISO 27001, and HIPAA.

### Benefits of Our Modules

**Enterprise-Grade Security**: Built-in security controls including encryption at rest and in transit, security groups, network ACLs, private networking, and IAM best practices.

**Compliance-Ready**: Pre-configured to meet common compliance frameworks with audit logging, encryption, and access controls enabled by default.

**Multi-Cloud Support**: Unified experience across AWS, Azure, and GCP with consistent patterns and naming conventions.

**Production-Proven**: Battle-tested in enterprise environments with high availability, failover capabilities, and disaster recovery patterns.

**Cost-Optimized**: Right-sized defaults with cost-conscious configurations and built-in cost allocation tags.

**Extensible Design**: Easy to customize and extend while maintaining upgrade paths for new module versions.

## Features

### Core Modularity

- **Single Responsibility**: Each module manages one logical component (VPC, compute, storage, etc.)
- **Composable Design**: Modules can be combined to build complex architectures
- **Input Validation**: Comprehensive variable validation to prevent misconfigurations
- **Output Transparency**: Clear outputs for easy integration with other modules
- **Minimal Resource Exposure**: Only expose necessary resources and configurations

### Security & Compliance

- **Encryption by Default**: All data encrypted at rest and in transit
- **Secure Network Design**: Private subnets, security groups, network ACLs with least privilege
- **Identity & Access Management**: IAM roles, policies, and service accounts following principle of least privilege
- **Secrets Management**: Integration with vault solutions and secure parameter storage
- **Audit Logging**: Comprehensive logging and monitoring configurations
- **Compliance Frameworks**: Built-in support for SOC 2, ISO 27001, HIPAA, PCI DSS, and GDPR

### Enterprise Features

- **High Availability**: Multi-AZ/region deployments with automatic failover
- **Disaster Recovery**: Backup, replication, and recovery procedures
- **Monitoring & Alerting**: Integrated CloudWatch, Azure Monitor, Stackdriver
- **Cost Management**: Resource tagging, budget alerts, and cost allocation
- **Governance**: Policy-as-code integration with Sentinel, OPA, or similar
- **Scalability**: Auto-scaling groups, load balancers, and elastic infrastructure
- **Observability**: Centralized logging, metrics, and distributed tracing

## Prerequisites

### Terraform Version Requirements

- **Terraform**: >= 1.3 (推荐使用 1.5+ 以获取最新特性)
- **Required Features**: `experiments = [module_variable_optional_attrs]`
- **State Management**: Configured backend (S3, Azure Blob, GCS, or Terraform Cloud)

### Cloud Provider Setup

#### AWS Requirements
```bash
# AWS CLI configuration
aws configure
aws configure set region us-west-2

# Required IAM permissions
- AmazonVPCFullAccess
- AmazonEC2FullAccess
- IAMFullAccess (for IAM-related modules)
```

#### Azure Requirements
```bash
# Azure CLI configuration
az login
az account set --subscription "your-subscription-id"

# Required RBAC roles
- Contributor
- User Access Administrator
```

#### GCP Requirements
```bash
# GCP CLI configuration
gcloud auth login
gcloud config set project your-project-id

# Required IAM roles
- Editor
- Service Account Admin
- Service Account User
```

### Authentication Setup

#### AWS Authentication Methods
```hcl
# Method 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"

# Method 2: AWS credentials file (~/.aws/credentials)
# Method 3: IAM role (EC2/ECS/EKS)
# Method 4: AWS SSO
```

#### Azure Authentication Methods
```hcl
# Method 1: Azure CLI (recommended for development)
# Method 2: Service Principal
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# Method 3: Managed Identity
```

#### GCP Authentication Methods
```hcl
# Method 1: Application Default Credentials (ADC)
gcloud auth application-default login

# Method 2: Service Account Key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Method 3: Workload Identity (GKE)
```

### Development Environment

- **tfenv** or **tfswitch**: For Terraform version management
- **pre-commit**: With hooks for terraform-docs, terraform fmt, tflint
- **Editor Plugins**: Terraform extension for VSCode or IntelliJ
- **Terragrunt**: Optional but recommended for complex deployments

## Available Modules

### Network & Connectivity

#### AWS VPC Module (modules/aws-vpc.md)

Comprehensive VPC solution with public, private, and isolated subnets across multiple availability zones.

**Key Features:**
- Multi-AZ public and private subnet architecture
- NAT Gateway for outbound internet access from private subnets
- VPC Endpoints for secure AWS service access
- Flow Logs for network monitoring
- Transit Gateway integration
- Network ACLs and security groups

**Use Cases:**
- Enterprise multi-tier applications
- Secure environments with private-only resources
- Hybrid cloud connectivity via Direct Connect/VPN
- Multi-account networking with Transit Gateway

**Example Configuration:**
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v2.1.0"

  name                  = "production-vpc"
  cidr_block           = "10.0.0.0/16"
  environment          = "production"
  enable_dns_hostnames = true
  enable_dns_support   = true

  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  public_subnets = [
    {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-west-2a"
      name             = "public-a"
    },
    {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-west-2b"
      name             = "public-b"
    }
  ]

  private_subnets = [
    {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-west-2a"
      name             = "private-a"
    },
    {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-west-2b"
      name             = "private-b"
    }
  ]

  tags = {
    Project     = "enterprise-platform"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
  }
}
```

#### Azure VNet Module (modules/azure-vnet.md)

Enterprise Azure Virtual Network with subnet configuration, NSGs, and peering.

**Key Features:**
- Hub-and-spoke network architecture
- Network Security Groups with comprehensive rules
- Private Link and Private Endpoint integration
- VPN and ExpressRoute gateway support
- Azure Bastion for secure RDP/SSH access
- DDoS Protection Standard

**Use Cases:**
- Azure enterprise landing zones
- Secure hybrid connectivity with on-premises
- PCI DSS compliant network segmentation
- Multi-region disaster recovery

#### GCP VPC Module (modules/gcp-vpc.md)

Google Cloud VPC with global routing, firewall rules, and shared VPC support.

**Key Features:**
- Global VPC with regional subnets
- Firewall rules with comprehensive examples
- Private Google Access without internet
- Cloud NAT for outbound connectivity
- Shared VPC for multi-project scenarios
- VPC Service Controls for sensitive data

**Use Cases:**
- Multi-regional applications
- Serverless VPC Access for Cloud Functions/Run
- Data analytics platforms with BigQuery
- GKE cluster networking

## Quick Start

### AWS Complete Example

```hcl
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "prod/network/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project     = "enterprise-platform"
    }
  }
}

module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v2.1.0"

  name        = "production-vpc"
  cidr_block  = "10.0.0.0/16"
  environment = "production"

  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnets = [
    {
      cidr_block = "10.0.1.0/24"
      az         = "us-west-2a"
      name       = "public-a"
    },
    {
      cidr_block = "10.0.2.0/24"
      az         = "us-west-2b"
      name       = "public-b"
    },
    {
      cidr_block = "10.0.3.0/24"
      az         = "us-west-2c"
      name       = "public-c"
    }
  ]

  private_subnets = [
    {
      cidr_block = "10.0.10.0/24"
      az         = "us-west-2a"
      name       = "private-app-a"
    },
    {
      cidr_block = "10.0.11.0/24"
      az         = "us-west-2b"
      name       = "private-app-b"
    },
    {
      cidr_block = "10.0.12.0/24"
      az         = "us-west-2c"
      name       = "private-app-c"
    }
  ]

  database_subnets = [
    {
      cidr_block = "10.0.20.0/24"
      az         = "us-west-2a"
      name       = "db-a"
    },
    {
      cidr_block = "10.0.21.0/24"
      az         = "us-west-2b"
      name       = "db-b"
    }
  ]

  enable_flow_logs = true
  flow_log_destination = "cloud-watch-logs"
  flow_log_retention   = 90

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ssm_endpoint      = true

  tags = {
    CostCenter  = "engineering"
    Compliance  = "pci-dss"
  }
}
```

### Azure Complete Example

```hcl
terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatesa"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "network" {
  name     = "production-network-rg"
  location = "East US"

  tags = {
    Environment = "Production"
    CostCenter  = "IT-Operations"
  }
}

module "hub_vnet" {
  source = "git::https://github.com/company/terraform-modules.git//azure/vnet?ref=v1.8.0"

  name                = "production-hub-vnet"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    gateway = {
      address_prefixes = ["10.0.1.0/26"]
    }
    azure_firewall = {
      address_prefixes = ["10.0.2.0/26"]
    }
    shared_services = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }

  enable_ddos_protection = true
}
```

### GCP Complete Example

```hcl
terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-state-bucket"
    prefix = "prod/network"
  }
}

provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//gcp/vpc?ref=v1.5.0"

  project_id   = "your-project-id"
  network_name = "production-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "us-central1-subnet"
      subnet_ip     = "10.0.1.0/24"
      subnet_region = "us-central1"
      description   = "Central US subnet"
    },
    {
      subnet_name   = "us-east1-subnet"
      subnet_ip     = "10.0.2.0/24"
      subnet_region = "us-east1"
      description   = "East US subnet"
    },
    {
      subnet_name   = "europe-west1-subnet"
      subnet_ip     = "10.0.3.0/24"
      subnet_region = "europe-west1"
      description   = "Europe West subnet"
    }
  ]

  firewall_rules = [
    {
      name        = "allow-ssh-bastion"
      direction   = "INGRESS"
      description = "Allow SSH from bastion host"
      ranges      = ["10.0.1.0/24"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
    {
      name        = "allow-internal"
      direction   = "INGRESS"
      description = "Allow all internal traffic"
      ranges      = ["10.0.0.0/8"]
      allow = [{
        protocol = "all"
      }]
    }
  ]

  enable_private_google_access = true
  enable_cloud_natable = true
}
```

## Module Versioning

### Semantic Versioning

We follow Semantic Versioning 2.0.0 for all modules:

- **MAJOR** (X.y.z): Breaking changes that require migration steps
- **MINOR** (x.Y.z): New features added in backward-compatible manner
- **PATCH** (x.y.Z): Bug fixes and security patches

### Version Pinning Strategies

#### 1. Exact Version (Production Recommended)
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v2.1.0"
}
```

#### 2. Flexible Version Pinning (Development)
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v2.1.x"
}
```

#### 3. Commit SHA for Pre-release Testing
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=abc123def456"
}
```

### Upgrade Paths

#### Minor Version Upgrades (v2.1.0 → v2.2.0)
Minor upgrades are typically backward compatible:

```bash
cd your-terraform-configuration
terraform init -upgrade
terraform plan
terraform apply
```

#### Major Version Upgrades (v1.x → v2.x)
Major upgrades require careful planning:

1. Review CHANGELOG.md: Understand breaking changes
2. Test in non-production: Validate in staging environment
3. Backup state: `terraform state pull > backup.tfstate`
4. Plan upgrade: `terraform plan` and review all changes
5. Execute upgrade: `terraform apply`
6. Verify: Test all functionality

#### Upgrade Checklist

- [ ] Read the migration guide for target version
- [ ] Review module input/output changes
- [ ] Update dependent modules if needed
- [ ] Run `terraform validate` to check syntax
- [ ] Test in isolated environment first
- [ ] Have rollback plan ready
- [ ] Schedule maintenance window for production
- [ ] Monitor application health post-upgrade

## Requirements

### Terraform Requirements

```hcl
terraform {
  required_version = ">= 1.3"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
```

### Provider Configuration

#### AWS Provider Configuration
```hcl
provider "aws" {
  region = "us-west-2"
  
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "production"
      CostCenter  = "engineering"
      Project     = "enterprise-platform"
      Compliance  = "soc2"
    }
  }
}
```

#### Azure Provider Configuration
```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
```

#### GCP Provider Configuration
```hcl
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
```

### State Management Requirements

#### S3 Backend Configuration (AWS)
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "prod/network/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### Azure Blob Backend Configuration
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatesa"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

#### Terraform Cloud Configuration
```hcl
terraform {
  cloud {
    organization = "your-organization"
    
    workspaces {
      tags = ["network", "production", "aws"]
    }
  }
}
```

## Support & Contributing

### Getting Help

#### 1. Documentation
- Start with the module-specific README files
- Check the examples/ directory for working configurations
- Review our troubleshooting guide

#### 2. Community Support
- Slack: #terraform-modules channel
- GitHub Discussions: Create a discussion in our repository
- Office Hours: Every Tuesday and Thursday, 2 PM - 3 PM EST

#### 3. Professional Support
- Email: terraform-modules-support@company.com
- Response Time: P1 (Critical) - 1 hour, P2 (High) - 4 hours, P3 (Normal) - 1 business day
- Enterprise Support: Available 24/7 for enterprise customers

### Reporting Issues

#### Bug Reports

1. Check existing issues: Search GitHub issues before creating new ones
2. Use template: Fill out the bug report template completely
3. Provide reproduction case: Include minimal configuration that reproduces the issue
4. Add environment details

#### Security Issues

**DO NOT** create GitHub issues for security vulnerabilities. Instead:

1. Email security@company.com with details
2. Include steps to reproduce
3. Allow 72 hours for initial response
4. Follow responsible disclosure practices

### Contributing Modules

#### Development Setup

1. Prerequisites:
   ```bash
   brew install terraform-docs tflint pre-commit
   git clone https://github.com/company/terraform-modules.git
   cd terraform-modules
   pre-commit install
   ```

2. Module Structure
3. Testing with terratest
4. Documentation with terraform-docs
5. Pull request process

## Architecture

### Module Design Principles

- **Single Responsibility**: Each module manages one logical component
- **Composability**: Modules designed to work together
- **Security First**: Security controls enabled by default
- **Idempotency**: Modules can be applied multiple times safely
- **DRY**: Avoid code duplication through reusable modules

### Testing Strategy

- **Unit Tests**: Individual resource validation
- **Integration Tests**: Multi-module interactions
- **Security Tests**: Compliance and vulnerability scanning
- **Performance Tests**: Scale and load testing

### CI/CD Pipeline

1. Pre-commit hooks for code quality
2. Automated testing on pull requests
3. Security scanning with Checkov and tfsec
4. Automated documentation generation
5. Version tagging and releases

## Related Resources

### Getting Started

- [Terraform Getting Started Guide](https://learn.hashicorp.com/terraform)
- [Best Practices](best-practices.md)
- [Getting Started](getting-started.md)
- [Example Repository](https://github.com/company/terraform-examples)

### Best Practices

- [Terraform Best Practices](best-practices.md#terraform-best-practices)
- [Security Guidelines](best-practices.md#security)
- [Cost Optimization](best-practices.md#cost-optimization)
- [Performance Tuning](best-practices.md#performance-tuning)

### Examples

- [AWS Examples](https://github.com/company/terraform-examples/tree/main/aws)
- [Azure Examples](https://github.com/company/terraform-examples/tree/main/azure)
- [GCP Examples](https://github.com/company/terraform-examples/tree/main/gcp)
- [Multi-Cloud Examples](https://github.com/company/terraform-examples/tree/main/multi-cloud)

### External Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

*For more detailed information about specific modules, see the module-specific documentation in the modules/ directory.*