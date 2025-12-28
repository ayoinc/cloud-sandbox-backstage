# Azure Storage

## Storage Account Module

Creates Azure Storage Account with blob containers, file shares, queues, and tables.

### Usage

```hcl
module "storage" {
  source = "path/to/azure/resources/storage/storage-account"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"

  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Security
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  # Versioning & Soft Delete
  enable_versioning          = true
  enable_soft_delete         = true
  soft_delete_retention_days = 30

  # Containers
  containers = {
    data = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }

  # File Shares
  file_shares = {
    shared = {
      quota = 100
      tier  = "TransactionOptimized"
    }
  }

  # Network Rules
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [module.vnet.subnet_ids["private"]]
  }

  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.vnet.subnet_ids["private-endpoints"]

  tags = module.tags.azure_tags
}
```

### Variables

| Variable                   | Type         | Default     | Description                  |
| -------------------------- | ------------ | ----------- | ---------------------------- |
| `account_tier`             | string       | "Standard"  | Standard or Premium          |
| `account_replication_type` | string       | "LRS"       | LRS, GRS, RAGRS, ZRS, GZRS   |
| `account_kind`             | string       | "StorageV2" | BlobStorage, StorageV2, etc. |
| `is_hns_enabled`           | bool         | false       | Data Lake Gen2               |
| `enable_versioning`        | bool         | true        | Blob versioning              |
| `containers`               | map(object)  | {}          | Blob containers              |
| `file_shares`              | map(object)  | {}          | File shares                  |
| `queues`                   | list(string) | []          | Queue names                  |
| `tables`                   | list(string) | []          | Table names                  |

### Outputs

| Output                      | Description                   |
| --------------------------- | ----------------------------- |
| `storage_account_id`        | Storage account ID            |
| `storage_account_name`      | Storage account name          |
| `primary_blob_endpoint`     | Blob endpoint URL             |
| `primary_access_key`        | Access key (sensitive)        |
| `primary_connection_string` | Connection string (sensitive) |
| `container_ids`             | Map of container IDs          |

### Data Lake Gen2

For Data Lake Storage Gen2:

```hcl
module "datalake" {
  source = "path/to/azure/resources/storage/storage-account"

  # ... common settings ...

  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true  # Enable hierarchical namespace

  containers = {
    raw     = { access_type = "private" }
    curated = { access_type = "private" }
    analytics = { access_type = "private" }
  }
}
```
