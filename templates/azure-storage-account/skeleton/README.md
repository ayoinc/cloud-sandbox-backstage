# ${{ values.name }}

${{ values.description }}

Terraform configuration of an Azure Storage account that is reachable only with Entra ID and through the network paths you allow.

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
├── main.tf                 # Root module calling the storage-account module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # Azure Storage backend configuration
├── modules/
│   └── storage-account/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── tests/
│   └── storage-account.tftest.hcl
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File | Description |
| --- | --- | --- |
| dev | `environments/dev.tfvars` | Locally redundant, short retention |
| staging | `environments/staging.tfvars` | Zone redundant, production-like |
| prod | `environments/prod.tfvars` | Geo-zone redundant, long retention |

## CI/CD

`.github/workflows/terraform.yaml` runs on pushes to `main`:

- **Checks** (no cloud account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, and security scans with Trivy and Checkov
- **Plan and apply** with OIDC authentication to Azure, for the `${{ values.envName }}` environment

Plan and apply are skipped until these repository secrets exist: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` and `AZURE_STORAGE_ACCOUNT` (the storage account holding the Terraform state). The [documentation](docs/index.md) explains how to create them.

Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**.

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
