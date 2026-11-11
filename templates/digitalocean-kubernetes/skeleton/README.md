# ${{ values.name }}

${{ values.description }}

Terraform configuration of a DigitalOcean Kubernetes (DOKS) cluster in its own VPC, with an autoscaling node pool, automatic patch upgrades and container registry integration.

## Quick Start

```bash
# Check the configuration without any account
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

```bash
# Plan and apply from a workstation
export DIGITALOCEAN_TOKEN=<api token>
export AWS_ACCESS_KEY_ID=<spaces access key> AWS_SECRET_ACCESS_KEY=<spaces secret key>
export AWS_ENDPOINT_URL_S3=https://${{ values.region }}.digitaloceanspaces.com

terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/${{ values.envName }}/terraform.tfstate"
terraform plan -var-file=environments/${{ values.envName }}.tfvars
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

```bash
# Configure kubectl with short-lived credentials
doctl kubernetes cluster kubeconfig save ${{ values.name }}-${{ values.envName }}
```

## Project Structure

```
.
├── main.tf                 # VPC, cluster, node pools, registry and project
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # DigitalOcean provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (DigitalOcean Spaces)
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── doks.tftest.hcl     # Terraform tests against a mocked provider
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                      |
| ----------- | ----------------------------- | ------------------------------------------------ |
| dev         | `environments/dev.tfvars`     | Small node pool, single control plane node       |
| staging     | `environments/staging.tfvars` | Production-like sizes, single control plane node |
| prod        | `environments/prod.tfvars`    | Highly available control plane, three nodes up   |

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** for the `${{ values.envName }}` environment once these repository secrets exist: `DIGITALOCEAN_TOKEN`, `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY` and `TF_STATE_BUCKET`

Apply and destroy run in the GitHub environments `dev`, `staging` and `prod`; add required reviewers to them to approve changes. Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the credentials and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
