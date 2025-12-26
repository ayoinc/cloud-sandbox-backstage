# ${{ values.name }} Infrastructure

This documentation covers the Terraform infrastructure provisioned for **${{ values.name }}**.

## Overview

This infrastructure stack provides:

- **Cloud Provider**: ${{ values.cloud_provider }}
- **Infrastructure Type**: ${{ values.infrastructure_type }}
- **Owner**: ${{ values.owner }}

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ${{ values.name }}                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Networking │  │  Compute    │  │  Storage    │         │
│  │  (VPC/VNet) │  │  (K8s/VM)   │  │  (S3/GCS)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Database   │  │  Security   │  │  Monitoring │         │
│  │  (RDS/SQL)  │  │  (KMS/IAM)  │  │  (Prom/Graf)│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Features

{% if values.enable_networking %}
- **Networking**: Custom VPC/VNet with public and private subnets
{% endif %}
{% if values.enable_kubernetes %}
- **Kubernetes**: Managed Kubernetes cluster (${{ values.kubernetes_version }})
{% endif %}
{% if values.enable_database %}
- **Database**: Managed database service (${{ values.database_type }})
{% endif %}
{% if values.enable_storage %}
- **Storage**: Object storage with versioning
{% endif %}
{% if values.enable_monitoring %}
- **Monitoring**: ${{ values.monitoring_solution }}
{% endif %}

## Quick Start

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan -var-file=environments/staging.tfvars
   ```

3. Apply the infrastructure:
   ```bash
   terraform apply -var-file=environments/staging.tfvars
   ```

## Environments

| Environment | Description |
|-------------|-------------|
| development | Development environment with minimal resources |
| staging | Pre-production environment for testing |
| production | Production environment with high availability |

## Module Structure

```
.
├── main.tf              # Root module - module calls only
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configurations
├── versions.tf          # Terraform and provider versions
├── modules/
│   ├── common/          # Shared resources (passwords, IDs)
│   ├── aws/             # AWS-specific resources
│   ├── azure/           # Azure-specific resources
│   ├── gcp/             # GCP-specific resources
│   └── monitoring/      # Monitoring stack
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── tests/               # Terraform tests
```

## Compliance

{% if values.compliance_framework != 'none' %}
This infrastructure follows **${{ values.compliance_framework }}** compliance guidelines.
{% else %}
No specific compliance framework configured.
{% endif %}

## Support

For issues or questions, contact the platform team or file a ticket in the internal support system.
