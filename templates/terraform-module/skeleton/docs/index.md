# ${{ values.name }}

${{ values.description }}

## Overview

This Terraform module provides infrastructure resources for **{{ values.provider | capitalize }}** cloud platform.

## Quick Start

### Prerequisites

- Terraform >= {{ values.terraform_version }}
  {%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
- AWS CLI configured with appropriate credentials
  {%- endif %}
  {%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
- Azure CLI configured with appropriate credentials
  {%- endif %}
  {%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
- Google Cloud SDK configured with appropriate credentials
  {%- endif %}

### Usage

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Update the values for your environment
4. Run:

```bash
terraform init
terraform plan
terraform apply
```

## Module Structure

```
.
├── main.tf              # Main module configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider version constraints
├── providers.tf         # Provider configurations
├── locals.tf            # Local values
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
├── aws/                 # AWS-specific modules
│   ├── compute/         # EC2, Auto Scaling
│   ├── network/         # VPC, Subnets, NAT
│   ├── storage/         # S3, EFS
│   ├── database/        # RDS, ElastiCache
│   ├── security/        # KMS, Secrets Manager
│   ├── observability/   # CloudWatch
│   ├── kubernetes/      # EKS
│   └── serverless/      # Lambda, API Gateway
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
├── azure/               # Azure-specific modules
│   ├── compute/         # VMs, Scale Sets
│   ├── network/         # VNet, Subnets
│   ├── storage/         # Storage Accounts
│   ├── database/        # Azure SQL, Redis
│   ├── security/        # Key Vault
│   ├── observability/   # Log Analytics
│   ├── kubernetes/      # AKS
│   └── serverless/      # Functions
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
├── gcp/                 # GCP-specific modules
│   ├── compute/         # Compute Engine
│   ├── network/         # VPC, Subnets
│   ├── storage/         # Cloud Storage
│   ├── database/        # Cloud SQL, Memorystore
│   ├── security/        # KMS, Secret Manager
│   ├── observability/   # Cloud Monitoring
│   ├── kubernetes/      # GKE
│   └── serverless/      # Cloud Functions
{%- endif %}
├── examples/            # Example configurations
└── tests/               # Terraform tests
```

## Feature Flags

Enable or disable resource modules using feature flags in `terraform.tfvars`:

| Flag                   | Default | Description                        |
| ---------------------- | ------- | ---------------------------------- |
| `enable_compute`       | `true`  | Compute resources (VMs, instances) |
| `enable_network`       | `true`  | Network infrastructure (VPC/VNet)  |
| `enable_storage`       | `true`  | Object and file storage            |
| `enable_database`      | `false` | Managed databases                  |
| `enable_security`      | `true`  | Security resources (KMS, secrets)  |
| `enable_observability` | `true`  | Monitoring and logging             |
| `enable_kubernetes`    | `false` | Managed Kubernetes clusters        |
| `enable_serverless`    | `false` | Serverless functions               |

## Inputs

See [variables.tf](../variables.tf) for all available input variables.

## Outputs

See [outputs.tf](../outputs.tf) for all available outputs.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` and `terraform validate`
4. Submit a pull request

## License

This module is maintained by the Platform Team.
