# {{ name }}

{{ description }}

## Overview

This Terraform infrastructure component manages {{ provider }} resources for the {{ projectName }} project.

### Architecture

```
.
├── infrastructure/          # Main terraform configuration
│   ├── main.tf             # Resource module calls
│   ├── variables.tf        # Input variables
│   ├── terraform.tfvars    # Variable values
│   ├── outputs.tf          # Output values
│   ├── providers.tf        # Provider configurations
│   └── versions.tf         # Provider versions
├── resources/              # Reusable resource modules
│   └── resource-group/     # Example resource module
├── tests/                  # Terraform tests
│   └── main.tftest.hcl     # Test configurations
├── docs/                   # Documentation
└── .github/workflows/      # CI/CD pipelines
    └── terraform.yml       # Terraform workflow
```

## Prerequisites

- Terraform >= 1.0
- Access to {{ provider }} cloud
- Appropriate credentials configured

## Usage

### Local Development

1. Navigate to the infrastructure directory:
```bash
cd infrastructure
```

2. Initialize Terraform:
```bash
terraform init
```

3. Plan the infrastructure:
```bash
terraform plan
```

4. Apply the infrastructure:
```bash
terraform apply
```

### Testing

Run Terraform tests:
```bash
cd tests
terraform init -backend=false
terraform test
```

## Resources Managed

{{#if createResourceGroup}}
- Resource Group
{{/if}}

{{#each resources}}
- {{ this }}
{{/each}}

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Deployment environment | string | {{ environment }} |
| region | Primary region for resources | string | {{ region }} |
| project_name | Project name for resource naming | string | {{ projectName }} |
| resource_group_name | Resource group name | string | {{#if resourceGroupName}}{{ resourceGroupName }}{{else}}null{{/if}} |
| tags | Default tags for all resources | map(string) | {} |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_id | ID of the resource group |
| resource_group_name | Name of the resource group |

## CI/CD Pipeline

The GitHub Actions workflow includes:

- **Terraform Validate**: Format check, initialization, and validation
- **Security Scan**: TFSec and Checkov security scanning
- **Terraform Test**: Automated testing with assertions
- **Terraform Plan**: Plan generation for PRs
- **Cost Estimation**: Infracost cost analysis
- **Documentation**: Auto-generated Terraform docs

## Security

All Terraform configurations are scanned for security issues using:
- TFSec
- Checkov

## Cost Estimation

Monthly cost estimates are automatically generated for each pull request using Infracost.

## Documentation

Documentation is auto-generated using [terraform-docs](https://github.com/terraform-docs/terraform-docs) and updated on each PR.

## License

This project is licensed under the terms specified in the repository LICENSE file.