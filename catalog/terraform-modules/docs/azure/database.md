# Azure Database

## SQL Database Module

Creates Azure SQL Server and databases with security features.

### Usage

```hcl
module "sql" {
  source = "path/to/azure/resources/database/sql-database"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"
  
  administrator_login    = "sqladmin"
  administrator_password = var.sql_password  # Or use managed password
  
  sql_version     = "12.0"
  minimum_tls_version = "1.2"
  
  # Azure AD Admin
  azuread_administrator = {
    login_username              = "admin@company.com"
    object_id                   = "00000000-0000-0000-0000-000000000000"
    azuread_authentication_only = true
  }
  
  # Databases
  databases = {
    app = {
      sku_name       = "S1"
      max_size_gb    = 50
      zone_redundant = true
      
      short_term_retention_days   = 7
      long_term_retention_weekly  = "P4W"
      long_term_retention_monthly = "P12M"
    }
    analytics = {
      sku_name    = "S2"
      max_size_gb = 100
    }
  }
  
  # Network Security
  public_network_access_enabled = false
  allow_azure_services          = true
  
  firewall_rules = {
    office = {
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  }
  
  virtual_network_rules = {
    app-subnet = {
      subnet_id = module.vnet.subnet_ids["app"]
    }
  }
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.vnet.subnet_ids["private-endpoints"]
  
  tags = module.tags.azure_tags
}
```

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `administrator_login` | string | required | SQL admin username |
| `administrator_password` | string | null | SQL admin password |
| `sql_version` | string | "12.0" | SQL Server version |
| `databases` | map(object) | {} | Database configurations |
| `multi_az` | bool | true | Multi-AZ deployment |
| `backup_retention_period` | number | 7 | Backup retention days |

### Outputs

| Output | Description |
|--------|-------------|
| `server_id` | SQL Server ID |
| `server_fqdn` | SQL Server FQDN |
| `database_ids` | Map of database IDs |
| `connection_strings` | Connection strings (sensitive) |

### SKU Options

| SKU | vCores | Memory | Use Case |
|-----|--------|--------|----------|
| Basic | - | 2 GB | Dev/Test |
| S0-S12 | - | 250 GB max | Standard workloads |
| P1-P15 | - | 4 TB max | Premium |
| GP_Gen5_2 | 2 | 10.4 GB | General Purpose |
| BC_Gen5_2 | 2 | 10.4 GB | Business Critical |
| HS_Gen5_2 | 2 | 10.4 GB | Hyperscale |

### Serverless Configuration

```hcl
databases = {
  serverless-db = {
    sku_name                    = "GP_S_Gen5_2"
    auto_pause_delay_in_minutes = 60
    min_capacity                = 0.5
    max_size_gb                 = 32
  }
}
```
