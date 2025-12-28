# Terraform Modules Library

Welcome to the centralized Terraform modules library. This library provides reusable, production-ready modules for **Azure**, **AWS**, and **GCP**.

## Overview

```
terraform-modules/
├── shared/           # Cross-provider shared modules
│   ├── naming/       # Industry-standard naming conventions
│   ├── tagging/      # Standardized tagging/labeling
│   └── validation/   # Input validation framework
├── azure/            # Azure-specific modules
│   └── resources/    # VNet, AKS, Storage, Key Vault, SQL, etc.
├── aws/              # AWS-specific modules
│   └── resources/    # VPC, EKS, S3, RDS, etc.
└── gcp/              # GCP-specific modules
    └── resources/    # VPC, GKE, Cloud Storage, Cloud SQL, etc.
```

## Quick Start

### Using Shared Modules

```hcl
module "naming" {
  source = "path/to/shared/naming"

  provider      = "azure"
  project       = "myapp"
  environment   = "prod"
  resource_type = "virtual_network"
  region        = "eastus"
}

module "tags" {
  source = "path/to/shared/tagging"

  project     = "myapp"
  environment = "prod"
  owner       = "platform-team"
}
```

### Using Provider Modules

```hcl
# Azure VNet
module "vnet" {
  source = "path/to/azure/resources/network/virtual-network"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"
  vnet_address_space  = ["10.0.0.0/16"]
  tags                = module.tags.azure_tags
}

# AWS VPC
module "vpc" {
  source = "path/to/aws/resources/network/vpc"

  name        = "myapp"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
  tags        = module.tags.aws_tags
}

# GCP VPC
module "vpc" {
  source = "path/to/gcp/resources/network/vpc"

  project_id  = "my-gcp-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"
  labels      = module.tags.gcp_labels
}
```

## Module Standards

All modules follow these standards:

| Standard | Description |
|----------|-------------|
| **Terraform >= 1.5** | Required Terraform version |
| **Provider Versions** | Azure >= 3.70, AWS >= 5.0, GCP >= 5.0 |
| **Native Testing** | Uses `terraform test` with `.tftest.hcl` |
| **Naming** | Follows Azure CAF, AWS Well-Architected, GCP best practices |
| **Tagging** | Environment isolation, compliance, cost management |

## Available Modules

### Shared
- [Naming](shared/naming.md) - Industry-standard resource naming
- [Tagging](shared/tagging.md) - Standardized tags/labels
- [Validation](shared/validation.md) - Input validation framework

### Azure
- [Virtual Network](azure/networking.md) - VNet, subnets, NSGs
- [AKS](azure/kubernetes.md) - Kubernetes cluster
- [Storage Account](azure/storage.md) - Blob, File, Queue, Table
- [Key Vault](azure/security.md) - Secrets management
- [SQL Database](azure/database.md) - Azure SQL
- [Log Analytics](azure/monitoring.md) - Monitoring workspace

### AWS
- [VPC](aws/networking.md) - VPC, subnets, NAT Gateway
- [EKS](aws/kubernetes.md) - Kubernetes cluster
- [S3](aws/storage.md) - Object storage
- [RDS](aws/database.md) - Relational database

### GCP
- [VPC](gcp/networking.md) - VPC, subnets, Cloud NAT
- [GKE](gcp/kubernetes.md) - Kubernetes cluster
- [Cloud Storage](gcp/storage.md) - Object storage
- [Cloud SQL](gcp/database.md) - Managed database
