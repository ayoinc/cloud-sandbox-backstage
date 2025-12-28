# GCP Cloud SQL Module

Creates a production-ready Cloud SQL instance with high availability, automated backups, encryption, and security hardening following Google Cloud best practices.

## Features

- PostgreSQL, MySQL, and SQL Server support
- Regional high availability
- Automated backups with point-in-time recovery
- Query Insights for performance monitoring
- Private IP connectivity
- SSL/TLS enforcement
- Disk autoresize
- Maintenance windows
- Database and user management
- Custom database flags

## Usage

### Basic Usage

```hcl
module "cloud_sql" {
  source = "../../../gcp/resources/database/cloud-sql"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"

  network = module.vpc.network_self_link
}
```

### Production PostgreSQL

```hcl
module "cloud_sql" {
  source = "../../../gcp/resources/database/cloud-sql"

  project_id  = "my-project"
  name        = "myapp"
  environment = "prod"
  region      = "us-central1"

  database_version = "POSTGRES_15"
  tier             = "db-custom-4-16384"  # 4 vCPU, 16GB RAM

  disk_size           = 100
  disk_type           = "PD_SSD"
  disk_autoresize     = true

  # High Availability
  availability_type = "REGIONAL"

  # Network
  network           = module.vpc.network_self_link
  enable_public_ip  = false
  require_ssl       = true

  # Backups
  backup_enabled                 = true
  backup_start_time              = "03:00"
  backup_location                = "us"
  point_in_time_recovery_enabled = true
  retained_backups               = 30
  transaction_log_retention_days = 7

  # Maintenance
  maintenance_window_day    = 7  # Sunday
  maintenance_window_hour   = 3  # 3 AM
  maintenance_window_update_track = "stable"

  # Performance
  insights_config = {
    query_insights_enabled  = true
    query_string_length     = 4096
    record_application_tags = true
    record_client_address   = true
  }

  # Database flags
  database_flags = [
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "log_connections"
      value = "on"
    }
  ]

  # Create databases and users
  databases = [
    { name = "myapp", charset = "UTF8", collation = "en_US.UTF8" }
  ]

  users = [
    { name = "app_user" },
    { name = "readonly_user" }
  ]

  deletion_protection = true

  labels = {
    data_classification = "confidential"
  }
}
```

### Development MySQL

```hcl
module "cloud_sql" {
  source = "../../../gcp/resources/database/cloud-sql"

  project_id  = "my-dev-project"
  name        = "myapp"
  environment = "dev"
  region      = "us-central1"

  database_version = "MYSQL_8_0"
  tier             = "db-f1-micro"

  disk_size = 10
  disk_type = "PD_HDD"

  availability_type = "ZONAL"  # No HA for dev

  enable_public_ip = true
  require_ssl      = true

  authorized_networks = [
    { name = "office", value = "203.0.113.0/24" }
  ]

  backup_enabled    = true
  retained_backups  = 3

  deletion_protection = false

  databases = [
    { name = "myapp" }
  ]

  users = [
    { name = "app_user" }
  ]
}
```

## Variables

| Name                             | Description                      | Type           | Default         | Required |
| -------------------------------- | -------------------------------- | -------------- | --------------- | -------- |
| `project_id`                     | GCP Project ID                   | `string`       | -               | Yes      |
| `name`                           | Instance name prefix             | `string`       | -               | Yes      |
| `environment`                    | Environment (dev, staging, prod) | `string`       | -               | Yes      |
| `region`                         | GCP region                       | `string`       | `"us-central1"` | No       |
| `database_version`               | Database version                 | `string`       | `"POSTGRES_15"` | No       |
| `tier`                           | Machine type tier                | `string`       | `"db-f1-micro"` | No       |
| `disk_size`                      | Disk size in GB                  | `number`       | `10`            | No       |
| `disk_type`                      | Disk type                        | `string`       | `"PD_SSD"`      | No       |
| `disk_autoresize`                | Enable autoresize                | `bool`         | `true`          | No       |
| `availability_type`              | HA type (REGIONAL/ZONAL)         | `string`       | `"REGIONAL"`    | No       |
| `network`                        | VPC network for private IP       | `string`       | `null`          | No       |
| `enable_public_ip`               | Assign public IP                 | `bool`         | `false`         | No       |
| `require_ssl`                    | Require SSL connections          | `bool`         | `true`          | No       |
| `backup_enabled`                 | Enable backups                   | `bool`         | `true`          | No       |
| `point_in_time_recovery_enabled` | Enable PITR                      | `bool`         | `true`          | No       |
| `deletion_protection`            | Enable deletion protection       | `bool`         | `true`          | No       |
| `databases`                      | Databases to create              | `list(object)` | `[]`            | No       |
| `users`                          | Users to create                  | `list(object)` | `[]`            | No       |
| `labels`                         | Labels to apply                  | `map(string)`  | `{}`            | No       |

### Database Configuration

```hcl
databases = [
  {
    name      = "myapp"
    charset   = "UTF8"
    collation = "en_US.UTF8"  # PostgreSQL only
  }
]
```

### User Configuration

```hcl
users = [
  {
    name     = "app_user"
    password = null      # Auto-generated if null
    host     = "%"       # MySQL only
  }
]
```

## Outputs

| Name                       | Description                         |
| -------------------------- | ----------------------------------- |
| `instance_name`            | Instance name                       |
| `instance_connection_name` | Connection name for Cloud SQL Proxy |
| `instance_self_link`       | Instance self link                  |
| `private_ip_address`       | Private IP address                  |
| `public_ip_address`        | Public IP address                   |
| `database_names`           | Created database names              |
| `user_names`               | Created user names                  |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Cloud SQL (REGIONAL)                     │
│                                                             │
│   Primary Zone (us-central1-a)    Standby (us-central1-b)  │
│  ┌─────────────────────┐       ┌─────────────────────┐     │
│  │   Primary Instance  │       │  Standby Instance   │     │
│  │                     │◄─────►│   (Sync Replication)│     │
│  │  ┌──────────────┐  │       │  ┌──────────────┐   │     │
│  │  │   PD_SSD     │  │       │  │   PD_SSD     │   │     │
│  │  │   Storage    │  │       │  │   Storage    │   │     │
│  │  └──────────────┘  │       │  └──────────────┘   │     │
│  └─────────────────────┘       └─────────────────────┘     │
│            │                                                │
│            ▼                                                │
│  ┌─────────────────────┐                                   │
│  │   Automated Backups │──────► Cloud Storage              │
│  │  + Point-in-Time    │                                   │
│  └─────────────────────┘                                   │
│                                                             │
│  ┌─────────────────────┐                                   │
│  │   Private Service   │◄────── VPC Network                │
│  │      Access         │                                   │
│  └─────────────────────┘                                   │
└────────────────────────────────────────────────────────────┘
```

## Connecting to Cloud SQL

### From GKE with Workload Identity

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: app-sa
  containers:
    - name: app
      env:
        - name: DB_HOST
          value: '10.x.x.x' # Private IP
        - name: DB_NAME
          value: 'myapp'
```

### Using Cloud SQL Proxy

```bash
# Install proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.0.0/cloud-sql-proxy.linux.amd64

# Connect
./cloud-sql-proxy my-project:us-central1:myapp-prod-xxxx

# Connect via localhost
psql -h localhost -U app_user -d myapp
```

## Security Features

### Private IP Only

```hcl
network          = module.vpc.network_self_link
enable_public_ip = false
```

### SSL/TLS Enforcement

```hcl
require_ssl = true
```

### Authorized Networks (if public IP needed)

```hcl
enable_public_ip = true
authorized_networks = [
  { name = "office", value = "203.0.113.0/24" }
]
```

## Supported Versions

### PostgreSQL

- POSTGRES_15, POSTGRES_14, POSTGRES_13, POSTGRES_12

### MySQL

- MYSQL_8_0, MYSQL_5_7

### SQL Server

- SQLSERVER_2019_STANDARD, SQLSERVER_2017_STANDARD

## Machine Types

| Tier          | vCPUs  | Memory | Use Case        |
| ------------- | ------ | ------ | --------------- |
| db-f1-micro   | Shared | 0.6 GB | Development     |
| db-g1-small   | Shared | 1.7 GB | Small workloads |
| db-custom-N-M | N      | M MB   | Production      |

Custom format: `db-custom-{vCPU}-{memory_MB}`

## Cost Considerations

| Component | Cost Factor                     |
| --------- | ------------------------------- |
| Instance  | Per vCPU/hour + per GB RAM/hour |
| Storage   | Per GB/month (SSD vs HDD)       |
| HA        | 2x instance cost                |
| Backups   | Storage costs                   |
| Network   | Egress charges                  |

**Tips:**

- Use shared-core (f1-micro, g1-small) for development
- Custom machine types for right-sizing production
- Consider ZONAL for non-critical workloads
- Use committed use discounts for production
