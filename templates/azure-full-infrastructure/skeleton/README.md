# ${{ values.name }}

${{ values.description }}

Complete Azure infrastructure stack managed with Terraform. Modules are switched on or off with `enable_*` variables.

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

## Modules

| Module | Creates | In this stack |
| ------ | ------- | ------------- |
| Networking | Virtual network, five subnets with a network security group each; optional NAT gateway, Bastion host and DDoS protection plan | {% if values.enableNetworking %}Enabled{% else %}Disabled{% endif %} |
| Compute | Linux virtual machines with private addresses, SSH keys and an optional daily shutdown | {% if values.enableCompute %}Enabled{% else %}Disabled{% endif %} |
| Containers | AKS cluster with a system and an autoscaling user node pool, and a container registry | {% if values.enableContainers %}Enabled{% else %}Disabled{% endif %} |
| Storage | Storage account with blob versioning and soft delete | {% if values.enableStorage %}Enabled{% else %}Disabled{% endif %} |
| Database | PostgreSQL flexible server with one database | {% if values.enableDatabase %}Enabled{% else %}Disabled{% endif %} |
| Security | Key Vault with Azure RBAC authorization and purge protection | {% if values.enableSecurity %}Enabled{% else %}Disabled{% endif %} |
| Identity | User-assigned managed identity for workloads | {% if values.enableIdentity %}Enabled{% else %}Disabled{% endif %} |
| Monitoring | Log Analytics workspace and Application Insights | {% if values.enableMonitoring %}Enabled{% else %}Disabled{% endif %} |
| Integration | Service Bus namespace and Event Grid topic | {% if values.enableIntegration %}Enabled{% else %}Disabled{% endif %} |
| Governance | Monthly budget with alerts and tag policies in audit mode | {% if values.enableGovernance %}Enabled{% else %}Disabled{% endif %} |

Change the selection in `environments/*.tfvars`.

## Project Structure

```
.
├── main.tf                 # Wires the enabled modules together
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Azure provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # Azure Storage backend configuration
├── modules/
│   ├── resource-group/     # Resource group with optional delete lock
│   ├── networking/         # Virtual network, subnets, NSGs, NAT gateway, Bastion
│   ├── compute/            # Linux virtual machines
│   ├── containers/         # AKS cluster and container registry
│   ├── storage/            # Storage account
│   ├── database/           # PostgreSQL flexible server
│   ├── security/           # Key Vault
│   ├── identity/           # User-assigned managed identity
│   ├── monitoring/         # Log Analytics and Application Insights
│   ├── integration/        # Service Bus and Event Grid
│   └── governance/         # Budget and tag policies
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── infrastructure.tftest.hcl  # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                             |
| ----------- | ----------------------------- | ------------------------------------------------------- |
| dev         | `environments/dev.tfvars`     | Smallest sizes, single zone, virtual machines shut down |
| staging     | `environments/staging.tfvars` | Production-like sizes, zone redundant                   |
| prod        | `environments/prod.tfvars`    | Zone redundant, geo-redundant, delete locks             |

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
