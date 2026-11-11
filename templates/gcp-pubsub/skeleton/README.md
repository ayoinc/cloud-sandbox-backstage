# ${{ values.name }}

${{ values.description }}

Terraform configuration of a Pub/Sub topic with subscriptions, dead-letter handling and an optional message schema.

## Quick Start

```bash
# Check the configuration without touching Google Cloud
terraform init -backend=false
terraform validate
terraform test

# Initialize against the state backend
gcloud auth application-default login
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="prefix=${{ values.name }}/${{ values.envName }}"

# Review the plan
terraform plan -var-file=environments/${{ values.envName }}.tfvars

# Apply the configuration
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

## Project Structure

```
.
├── main.tf                 # Root module calling the pubsub module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # Cloud Storage backend configuration
├── modules/
│   └── pubsub/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── tests/
│   └── pubsub.tftest.hcl
├── schemas/                # Message schema definitions (Avro, Protocol Buffers)
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File | Description |
| --- | --- | --- |
| dev | `environments/dev.tfvars` | Development |
| staging | `environments/staging.tfvars` | Production-like |
| prod | `environments/prod.tfvars` | Production |

## CI/CD

`.github/workflows/terraform.yaml` runs on pushes to `main`:

- **Checks** (no cloud account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, and security scans with Trivy and Checkov
- **Plan and apply** with Workload Identity Federation to Google Cloud, for the `${{ values.envName }}` environment

Plan and apply are skipped until these repository secrets exist: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` and `GCP_TERRAFORM_STATE_BUCKET` (the bucket holding the Terraform state). The [documentation](docs/index.md) explains how to create them.

Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**.

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
