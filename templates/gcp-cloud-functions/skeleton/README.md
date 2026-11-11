# ${{ values.name }}

${{ values.description }}

A Cloud Run function (Cloud Functions 2nd gen) with the Terraform configuration that deploys it: dedicated service accounts, private source bucket and ${{ 'an HTTP' if values.triggerType == 'http' else 'a Pub/Sub' }} trigger.

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

Work on the function itself in `function/`:

```bash
cd function
npm ci
npm test
npm start
```

## Project Structure

```
.
├── main.tf                 # Root module calling the cloud-function module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # Cloud Storage backend configuration
├── function/               # Function source, tests and dependencies
├── modules/
│   └── cloud-function/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── tests/
│   └── cloud-function.tftest.hcl
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File | Description |
| --- | --- | --- |
| dev | `environments/dev.tfvars` | Small instances, scales to zero |
| staging | `environments/staging.tfvars` | Production-like |
| prod | `environments/prod.tfvars` | More memory and instances |

## CI/CD

`.github/workflows/terraform.yaml` runs on pushes to `main`:

- **Checks** (no cloud account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, the function's `npm test`, and security scans with Trivy and Checkov
- **Plan and apply** with Workload Identity Federation to Google Cloud, for the `${{ values.envName }}` environment

Plan and apply are skipped until these repository secrets exist: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` and `GCP_TERRAFORM_STATE_BUCKET` (the bucket holding the Terraform state). The [documentation](docs/index.md) explains how to create them.

Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**.

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
