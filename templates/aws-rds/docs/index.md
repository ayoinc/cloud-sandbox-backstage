# AWS RDS Database Template

This template creates an Amazon RDS database instance with production-ready configurations.

## Features

- **Multi-AZ deployment** - High availability option
- **Automated backups** - Configurable retention
- **Encryption** - At-rest and in-transit encryption
- **Parameter groups** - Optimized settings
- **Security groups** - Network access control

## Prerequisites

- AWS Account
- Terraform >= 1.5
- VPC with private subnets

## Supported Engines

- PostgreSQL
- MySQL
- MariaDB
- Oracle
- SQL Server

## Quick Start

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `identifier` | DB instance identifier | - |
| `engine` | Database engine | `postgres` |
| `engine_version` | Engine version | `15.4` |
| `instance_class` | Instance type | `db.t3.micro` |
| `allocated_storage` | Storage in GB | `20` |
| `multi_az` | Enable Multi-AZ | `false` |

## Outputs

- `endpoint` - Database endpoint
- `port` - Database port
- `database_name` - Database name

## Support

Contact the Platform Team for assistance.
