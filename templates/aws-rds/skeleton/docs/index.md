# ${{ values.name }}

${{ values.description }}

## Overview

This RDS database is managed by Terraform and provides a managed **${{ values.engine }}** database for the **${{ values.environment }}** environment.

## Configuration

| Setting | Value |
|---------|-------|
| Engine | ${{ values.engine }} ${{ values.engineVersion }} |
| Instance Class | ${{ values.instanceClass }} |
| Storage | ${{ values.allocatedStorage }} GB |
| Multi-AZ | ${{ values.multiAz }} |
| Region | ${{ values.region }} |
| Environment | ${{ values.environment }} |

## Connection

### Retrieve Credentials

Credentials are stored in AWS Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id ${{ values.name }}-${{ values.environment }}-db-credentials \
  --query SecretString --output text | jq .
```

### Connection String

```bash
# PostgreSQL
postgresql://dbadmin:<password>@<endpoint>:5432/app

# MySQL
mysql://dbadmin:<password>@<endpoint>:3306/app
```

## Security

- Database is in private subnets only
- Encrypted at rest with AWS-managed keys
- Credentials stored in Secrets Manager
- Security group restricts access to VPC CIDR only

## Backups

- Automated backups enabled
- Retention: ${{ values.environment == "production" ? "30 days" : "7 days" }}
- Backup window: 03:00-04:00 UTC

## Owner

This resource is owned by **${{ values.owner }}**.
