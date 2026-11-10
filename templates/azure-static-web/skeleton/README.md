# ${{ values.name }}

${{ values.description }}

## Quick Start

```bash
# Check the configuration without touching Azure
terraform init -backend=false
terraform validate
terraform test

# Initialize against the state backend
az login
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=<storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}/${{ values.envName }}/terraform.tfstate"

# Review the plan
terraform plan -var-file=environments/${{ values.envName }}.tfvars

# Apply the configuration
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

## Project Structure

```
.
├── main.tf                 # Root module calling the Static Web module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Azure provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # Azure Storage backend configuration
├── modules/
│   └── static-web/         # Reusable Static Web Apps module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── static-web.tftest.hcl  # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                              |
| ----------- | ----------------------------- | ---------------------------------------- |
| dev         | `environments/dev.tfvars`     | Development - Free tier                  |
| staging     | `environments/staging.tfvars` | Staging - Standard tier                  |
| prod        | `environments/prod.tfvars`    | Production - Standard with custom domain |

## CI/CD

`.github/workflows/terraform.yaml` runs on pull requests and pushes to `main`:

- **Checks** (no cloud account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, and security scans with Trivy and Checkov
- **Plan and apply** with OIDC authentication to Azure, for the `${{ values.envName }}` environment

Plan and apply are skipped until these repository secrets exist: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` and `AZURE_STORAGE_ACCOUNT` (the storage account holding the Terraform state). Add `INFRACOST_API_KEY` for cost estimates on pull requests. The [documentation](docs/index.md) explains how to create them.

Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**.

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to Backstage TechDocs.

## Owner

**${{ values.owner }}**
