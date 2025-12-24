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

# Configure kubectl
gcloud container clusters get-credentials ${{ values.name }} --region ${{ values.region }} --project ${{ values.gcpProject }}
```

## Project Structure

```
.
├── main.tf                 # Root module calling the GKE module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Google provider configuration
├── backend.tf              # GCS backend configuration
├── modules/
│   └── gke/                # Reusable GKE module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── gke.tftest.hcl      # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                          |
| ----------- | ----------------------------- | ------------------------------------ |
| dev         | `environments/dev.tfvars`     | Development - Autopilot, preemptible |
| staging     | `environments/staging.tfvars` | Staging - Standard mode              |
| prod        | `environments/prod.tfvars`    | Production - private endpoint, HA    |

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
