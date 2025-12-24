# ${{ values.name }}

${{ values.description }}

## Instance Details

| Property             | Value                                          |
| -------------------- | ---------------------------------------------- |
| **Instance Name**    | `${{ values.name }}-${{ values.environment }}` |
| **Database Version** | ${{ values.database_version }}                 |
| **Region**           | ${{ values.region }}                           |
| **Project**          | ${{ values.gcpProject }}                       |
| **Owner**            | ${{ values.owner }}                            |

## Quick Start

### Connect using Cloud SQL Proxy

```bash
# Get the connection name
CONNECTION_NAME=$(terraform output -raw connection_name)

# Start Cloud SQL Proxy
cloud-sql-proxy $CONNECTION_NAME --port=5432

# Connect using psql (PostgreSQL)
psql -h localhost -p 5432 -U app_user -d ${{ values.name | replace("-", "_") }}
```

### Get Database Credentials

```bash
# From Secret Manager
gcloud secrets versions access latest --secret="${{ values.name }}-${{ values.environment }}-db-password"

# From Terraform
terraform output -raw user_password
```

## Architecture

```d2
direction: right

app: Application {
  style.fill: "#e3f2fd"
}

proxy: Cloud SQL Proxy {
  shape: hexagon
  style.fill: "#fff3e0"
}

cloudsql: ${{ values.name }}-${{ values.environment }} {
  style.fill: "#c8e6c9"

  db: ${{ values.database_version }}
}

storage: Storage {
  shape: cylinder
  style.fill: "#e1bee7"
}

secrets: Secret Manager {
  shape: document
  style.fill: "#ffccbc"
}

app -> proxy
proxy -> cloudsql
cloudsql -> storage
cloudsql -> secrets: "Credentials"
```

## Configuration

### Instance Settings

- **Tier**: Configured per environment in tfvars
- **Availability**: ZONAL (dev) / REGIONAL (prod)
- **Disk**: SSD with auto-resize enabled

### Backup Configuration

- **Automated Backups**: Enabled
- **Backup Window**: 03:00 UTC
- **Retention**: Environment-specific (3-30 days)
- **Point-in-Time Recovery**: Enabled for PostgreSQL

### Network Configuration

- **Private IP**: Based on template selection
- **SSL Required**: Yes
- **Authorized Networks**: Environment-specific

## Runbooks

### Scaling the Instance

```bash
# Update tier in tfvars
terraform apply -var-file=environments/$ENV.tfvars
```

### Manual Backup

```bash
gcloud sql backups create --instance=${{ values.name }}-${{ values.environment }}
```

### Point-in-Time Recovery

```bash
gcloud sql instances clone ${{ values.name }}-${{ values.environment }} ${{ values.name }}-restored \
  --point-in-time="2024-01-15T10:00:00Z"
```

## Monitoring

View metrics in Cloud Console:

- [Cloud SQL Dashboard](https://console.cloud.google.com/sql/instances)
- [Query Insights](https://console.cloud.google.com/sql/instances/${{ values.name }}-${{ values.environment }}/query-insights)

## Support

For issues, contact: **${{ values.owner }}**
