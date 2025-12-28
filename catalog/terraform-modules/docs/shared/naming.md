# Naming Module

Industry-standard naming conventions for Azure, AWS, and GCP resources.

## Features

- **Azure CAF** compliant naming
- **AWS Well-Architected** naming patterns
- **GCP best practices** naming
- Automatic length truncation per provider limits
- Unique name generation with hash suffix

## Usage

```hcl
module "naming" {
  source = "path/to/shared/naming"

  provider      = "azure"           # azure, aws, or gcp
  project       = "myapp"
  environment   = "prod"            # dev, staging, prod, sandbox, test, uat
  component     = "api"             # optional
  resource_type = "virtual_network" # see resource types below
  region        = "eastus"
  instance      = 1                 # optional, for multiple resources
  layer         = "network"         # platform, application, data, network, security, monitoring
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `name` | Standard name with hyphens |
| `name_no_hyphens` | Name without hyphens (for storage accounts) |
| `name_no_special` | Alphanumeric only |
| `unique_name` | Name with unique hash suffix |
| `prefix` | Resource type prefix used |
| `environment_short` | Abbreviated environment (d, s, p) |
| `region_short` | Abbreviated region |

## Resource Type Prefixes

### Azure
| Resource | Prefix |
|----------|--------|
| virtual_machine | vm |
| virtual_network | vnet |
| subnet | snet |
| storage_account | st |
| key_vault | kv |
| kubernetes_cluster | aks |
| container_registry | acr |
| sql_server | sql |
| log_analytics | log |

### AWS
| Resource | Prefix |
|----------|--------|
| ec2_instance | ec2 |
| vpc | vpc |
| subnet | sn |
| s3_bucket | s3 |
| eks_cluster | eks |
| rds_instance | rds |
| lambda_function | lambda |

### GCP
| Resource | Prefix |
|----------|--------|
| compute_instance | vm |
| vpc | vpc |
| subnet | sn |
| cloud_storage | gcs |
| gke_cluster | gke |
| cloud_sql | sql |

## Examples

```hcl
# Azure Storage Account
module "storage_name" {
  source        = "path/to/shared/naming"
  provider      = "azure"
  project       = "myapp"
  environment   = "prod"
  resource_type = "storage_account"
  region        = "eastus"
}
# Output: stmyapppeus (truncated to 24 chars)

# AWS S3 Bucket
module "bucket_name" {
  source        = "path/to/shared/naming"
  provider      = "aws"
  project       = "myapp"
  environment   = "dev"
  resource_type = "s3_bucket"
  region        = "us-east-1"
}
# Output: s3-myapp-d-use1

# GCP GKE Cluster
module "gke_name" {
  source        = "path/to/shared/naming"
  provider      = "gcp"
  project       = "myapp"
  environment   = "staging"
  resource_type = "gke_cluster"
  region        = "us-central1"
}
# Output: gke-myapp-s-usc1
```
