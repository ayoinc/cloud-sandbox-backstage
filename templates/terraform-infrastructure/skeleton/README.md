# ${{ values.name }}

${{ values.description }}

## Overview

Multi-cloud infrastructure provisioned via Terraform with production-grade security and monitoring.

| Attribute | Value |
|-----------|-------|
| Cloud Provider | ${{ values.cloud_provider }} |
| Infrastructure Type | ${{ values.infrastructure_type }} |
| Owner | ${{ values.owner }} |
| Terraform Version | ${{ values.terraform_version }} |

## Quick Start

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file=environments/staging.tfvars

# Apply
terraform apply -var-file=environments/staging.tfvars
```

## Structure

```
.
├── main.tf              # Root module (module calls only)
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configurations
├── versions.tf          # Version constraints
├── modules/
│   ├── common/          # Shared resources
│   ├── aws/             # AWS infrastructure
│   ├── azure/           # Azure infrastructure
│   ├── gcp/             # GCP infrastructure
│   └── monitoring/      # Prometheus/Grafana
├── environments/        # Environment-specific configs
├── tests/               # Terraform tests
└── docs/                # TechDocs
```

## Features

- Modular architecture (no resources in root)
- Multi-cloud support (AWS, Azure, GCP)
- Managed Kubernetes clusters
- Database provisioning
- Monitoring with Prometheus/Grafana
- Compliance-ready configurations

## Documentation

View full documentation in Backstage TechDocs or in the `docs/` folder.

## Support

Contact the Platform Team for assistance.
