# ${{ values.name }}

${{ values.description }}

## Quick Start

```bash
# Initialize Terraform
terraform init

# Select workspace (environment)
terraform workspace select ${{ values.environment }} || terraform workspace new ${{ values.environment }}

# Review the plan
terraform plan -var-file=environments/${{ values.environment }}.tfvars

# Apply the configuration
terraform apply -var-file=environments/${{ values.environment }}.tfvars
```

## Project Structure

```
.
├── main.tf                 # Root module calling the RDS module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # AWS provider configuration
├── backend.tf              # S3 backend configuration
├── modules/
│   └── rds/                # Reusable RDS module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── rds.tftest.hcl      # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                |
| ----------- | ----------------------------- | ------------------------------------------ |
| dev         | `environments/dev.tfvars`     | Development - small instance, no Multi-AZ  |
| staging     | `environments/staging.tfvars` | Staging - production-like config           |
| prod        | `environments/prod.tfvars`    | Production - Multi-AZ, enhanced monitoring |

## CI/CD

This project includes a GitHub Actions workflow with OIDC authentication that:

- Runs on pull requests and pushes to main
- Performs linting with TFLint
- Runs security scanning with tfsec and Checkov
- Plans and applies Terraform changes
- Runs Terraform native tests

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to Backstage TechDocs.

## Owner

**${{ values.owner }}**
