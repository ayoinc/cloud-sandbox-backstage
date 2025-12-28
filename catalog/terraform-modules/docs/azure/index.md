# Azure Modules

Azure-specific Terraform modules following Azure CAF naming conventions and best practices.

## Available Modules

### Core Modules

| Module                              | Path                                  | Description                              |
| ----------------------------------- | ------------------------------------- | ---------------------------------------- |
| [Resource Group](resource-group.md) | `azure/resources/core/resource-group` | Resource group with lifecycle management |

### Resource Modules

| Module                              | Path                                            | Description              |
| ----------------------------------- | ----------------------------------------------- | ------------------------ |
| [Virtual Network](networking.md)    | `azure/resources/network/virtual-network`       | VNet, subnets, NSGs      |
| [AKS](kubernetes.md)                | `azure/resources/kubernetes/aks`                | Azure Kubernetes Service |
| [Storage Account](storage.md)       | `azure/resources/storage/storage-account`       | Blob, File, Queue, Table |
| [Key Vault](security.md)            | `azure/resources/security/key-vault`            | Secrets management       |
| [SQL Database](database.md)         | `azure/resources/database/sql-database`         | Azure SQL                |
| [Container Registry](kubernetes.md) | `azure/resources/containers/container-registry` | ACR                      |
| [Log Analytics](monitoring.md)      | `azure/resources/monitoring/log-analytics`      | Monitoring workspace     |

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}
```

## Environment Sizing

All modules support environment-specific configurations:

| Setting             | Dev          | Staging         | Prod            |
| ------------------- | ------------ | --------------- | --------------- |
| VM Size             | Standard_B2s | Standard_D2s_v3 | Standard_D4s_v3 |
| AKS Nodes           | 1-3          | 2-5             | 3-10            |
| Storage Replication | LRS          | ZRS             | GRS             |
| SQL SKU             | Basic        | S1              | P1              |
| Log Retention       | 30 days      | 60 days         | 90 days         |
