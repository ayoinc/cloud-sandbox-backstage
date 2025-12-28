# AWS RDS Module

Creates a production-ready RDS instance with Multi-AZ, encryption, automated backups, and performance monitoring.

## Features

- Multi-AZ deployment for high availability
- Storage encryption with KMS
- Automated backups with configurable retention
- Performance Insights and Enhanced Monitoring
- Secrets Manager integration for credentials
- Parameter group customization
- Storage autoscaling
- CloudWatch log exports

## Usage

### Basic Usage

```hcl
module "rds" {
  source = "../../../aws/resources/database/rds"

  name        = "myapp"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}
```

### Production PostgreSQL

```hcl
module "rds" {
  source = "../../../aws/resources/database/rds"

  name        = "myapp"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  database_name               = "myapp"
  master_username             = "admin"
  manage_master_user_password = true  # AWS manages password

  multi_az            = true
  publicly_accessible = false

  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection = true
  skip_final_snapshot = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  parameter_group_family = "postgres15"
  parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  tags = {
    DataClassification = "confidential"
  }
}
```

### Development MySQL

```hcl
module "rds" {
  source = "../../../aws/resources/database/rds"

  name        = "myapp"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 0  # Disable autoscaling

  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1

  performance_insights_enabled = false
  monitoring_interval          = 0

  allowed_cidr_blocks = ["10.0.0.0/16"]
}
```

## Variables

| Name                           | Description                      | Type           | Default          | Required |
| ------------------------------ | -------------------------------- | -------------- | ---------------- | -------- |
| `name`                         | Name prefix for resources        | `string`       | -                | Yes      |
| `environment`                  | Environment (dev, staging, prod) | `string`       | -                | Yes      |
| `vpc_id`                       | VPC ID                           | `string`       | -                | Yes      |
| `subnet_ids`                   | Subnet IDs for DB subnet group   | `list(string)` | -                | Yes      |
| `engine`                       | Database engine                  | `string`       | `"postgres"`     | No       |
| `engine_version`               | Engine version                   | `string`       | `"15.4"`         | No       |
| `instance_class`               | Instance class                   | `string`       | `"db.t3.medium"` | No       |
| `allocated_storage`            | Storage in GB                    | `number`       | `20`             | No       |
| `max_allocated_storage`        | Max storage for autoscaling      | `number`       | `100`            | No       |
| `storage_type`                 | Storage type                     | `string`       | `"gp3"`          | No       |
| `storage_encrypted`            | Enable encryption                | `bool`         | `true`           | No       |
| `kms_key_id`                   | KMS key ID                       | `string`       | `null`           | No       |
| `database_name`                | Database name                    | `string`       | `"app"`          | No       |
| `master_username`              | Master username                  | `string`       | `"admin"`        | No       |
| `manage_master_user_password`  | AWS manages password             | `bool`         | `true`           | No       |
| `port`                         | Database port                    | `number`       | `5432`           | No       |
| `multi_az`                     | Enable Multi-AZ                  | `bool`         | `true`           | No       |
| `publicly_accessible`          | Public access                    | `bool`         | `false`          | No       |
| `backup_retention_period`      | Backup retention days            | `number`       | `7`              | No       |
| `deletion_protection`          | Enable deletion protection       | `bool`         | `true`           | No       |
| `performance_insights_enabled` | Enable Performance Insights      | `bool`         | `true`           | No       |
| `monitoring_interval`          | Enhanced monitoring interval     | `number`       | `60`             | No       |
| `allowed_security_group_ids`   | Allowed security groups          | `list(string)` | `[]`             | No       |
| `allowed_cidr_blocks`          | Allowed CIDR blocks              | `list(string)` | `[]`             | No       |
| `tags`                         | Tags to apply                    | `map(string)`  | `{}`             | No       |

## Outputs

| Name                     | Description                      |
| ------------------------ | -------------------------------- |
| `db_instance_id`         | RDS instance ID                  |
| `db_instance_arn`        | RDS instance ARN                 |
| `db_instance_endpoint`   | RDS instance endpoint            |
| `db_instance_address`    | RDS instance address             |
| `db_instance_port`       | RDS instance port                |
| `db_instance_name`       | Database name                    |
| `db_instance_username`   | Master username                  |
| `db_security_group_id`   | Security group ID                |
| `master_user_secret_arn` | Secrets Manager ARN for password |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                        Multi-AZ RDS                         │
│                                                             │
│   Primary AZ (us-east-1a)        Standby AZ (us-east-1b)   │
│  ┌─────────────────────┐       ┌─────────────────────┐     │
│  │   Primary Instance  │       │  Standby Instance   │     │
│  │                     │◄─────►│   (Sync Replication)│     │
│  │  ┌──────────────┐  │       │  ┌──────────────┐   │     │
│  │  │    EBS      │  │       │  │    EBS       │   │     │
│  │  │  (gp3/io1)  │  │       │  │  (gp3/io1)   │   │     │
│  │  └──────────────┘  │       │  └──────────────┘   │     │
│  └─────────────────────┘       └─────────────────────┘     │
│            │                                                │
│            ▼                                                │
│  ┌─────────────────────┐                                   │
│  │   Automated Backups │──────► S3 (Cross-Region)          │
│  │    + Snapshots      │                                   │
│  └─────────────────────┘                                   │
└────────────────────────────────────────────────────────────┘
```

## Security Features

### Encryption

- Storage encryption with KMS (default or CMK)
- SSL/TLS for connections (enforced via parameter group)
- Performance Insights data encryption

### Secrets Management

```hcl
# AWS manages password in Secrets Manager
manage_master_user_password = true

# Retrieve password
data "aws_secretsmanager_secret_version" "db" {
  secret_id = module.rds.master_user_secret_arn
}
```

### Network Security

- Private subnets only (no public access)
- Security group with least-privilege
- No default CIDR access

## Monitoring

### Performance Insights

Analyze database performance:

- Top SQL queries
- Wait events
- Database load

### Enhanced Monitoring

OS-level metrics:

- CPU, memory, disk
- Process information
- File system metrics

### CloudWatch Logs

Export database logs:

- PostgreSQL: `postgresql`, `upgrade`
- MySQL: `audit`, `error`, `general`, `slowquery`

## Supported Engines

| Engine     | Versions   | Default Port |
| ---------- | ---------- | ------------ |
| `postgres` | 13, 14, 15 | 5432         |
| `mysql`    | 5.7, 8.0   | 3306         |
| `mariadb`  | 10.5, 10.6 | 3306         |

## Cost Considerations

| Component            | Cost Factor                    |
| -------------------- | ------------------------------ |
| Instance             | Per hour by class              |
| Storage              | Per GB/month                   |
| I/O                  | Per million requests (io1/io2) |
| Backups              | Free up to DB size             |
| Multi-AZ             | 2x instance cost               |
| Performance Insights | Free (7 days) or paid          |

**Tips:**

- Use Reserved Instances for production
- Use `db.t3` for development
- Consider Aurora for high-throughput workloads
- Enable storage autoscaling to avoid provisioning excess
