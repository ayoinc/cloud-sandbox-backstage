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
├── main.tf                 # Root module calling the Functions module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Azure provider configuration
├── backend.tf              # Azure Storage backend configuration
├── modules/
│   └── functions/          # Reusable Azure Functions module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── functions.tftest.hcl  # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                              |
| ----------- | ----------------------------- | ---------------------------------------- |
| dev         | `environments/dev.tfvars`     | Development - Consumption plan           |
| staging     | `environments/staging.tfvars` | Staging - Premium plan                   |
| prod        | `environments/prod.tfvars`    | Production - Full monitoring and scaling |

## Runtime Stacks

| Stack  | Versions | Description     |
| ------ | -------- | --------------- |
| node   | 18, 20   | Node.js runtime |
| python | 3.9-3.11 | Python runtime  |
| dotnet | 6.0, 8.0 | .NET runtime    |
| java   | 11, 17   | Java runtime    |

## Hosting Plans

| Plan        | Use Case                                 | Features                                 |
| ----------- | ---------------------------------------- | ---------------------------------------- |
| Consumption | Low-traffic, sporadic workloads          | Pay-per-execution, auto-scale            |
| Premium     | Production workloads, VNET integration   | Pre-warmed instances, no cold start      |
| Dedicated   | Large-scale or existing App Service plan | Dedicated VMs, full App Service features |

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
