# ${{ values.name }}

${{ values.description }}

Terraform configuration of DigitalOcean Droplets in their own VPC, behind a cloud firewall that is closed by default, hardened on first boot with cloud-init.

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
# Sign in (needs an SSH source range in ssh_allowed_cidrs)
ssh ops@<address from `terraform output public_ipv4_addresses`>
```

## Project Structure

```
.
├── main.tf                 # VPC, Droplets, firewall, reserved IPs and project
├── cloud-init.yaml.tftpl   # First-boot configuration of the Droplets
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
│   └── droplet.tftest.hcl  # Terraform tests against a mocked provider
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                    |
| ----------- | ----------------------------- | ---------------------------------------------- |
| dev         | `environments/dev.tfvars`     | One small Droplet, no backups                  |
| staging     | `environments/staging.tfvars` | Production-like size, no backups               |
| prod        | `environments/prod.tfvars`    | Two Droplets, weekly backups and reserved IPs  |

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** for the `${{ values.envName }}` environment once these repository secrets exist: `DIGITALOCEAN_TOKEN`, `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY` and `TF_STATE_BUCKET`

Apply and destroy run in the GitHub environments `dev`, `staging` and `prod`; add required reviewers to them to approve changes. Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the credentials and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
