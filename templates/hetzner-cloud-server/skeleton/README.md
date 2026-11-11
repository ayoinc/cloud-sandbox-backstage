# ${{ values.name }}

${{ values.description }}

Terraform configuration of Hetzner Cloud servers on a private network, behind a firewall that is closed by default, hardened on first boot with cloud-init and optionally fronted by a load balancer.

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
export HCLOUD_TOKEN=<api token>
export AWS_ACCESS_KEY_ID=<object storage access key> AWS_SECRET_ACCESS_KEY=<object storage secret key>
export AWS_ENDPOINT_URL_S3=https://fsn1.your-objectstorage.com

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
├── main.tf                 # Network, firewall, servers and load balancer
├── cloud-init.yaml.tftpl   # First-boot configuration of the servers
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Hetzner Cloud provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (Hetzner Object Storage)
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── server.tftest.hcl   # Terraform tests against a mocked provider
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                                   |
| ----------- | ----------------------------- | ------------------------------------------------------------- |
| dev         | `environments/dev.tfvars`     | One server, no backups                                        |
| staging     | `environments/staging.tfvars` | Mirrors production at a smaller scale                         |
| prod        | `environments/prod.tfvars`    | Two servers, load balancer, daily backups, deletion protection |

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** for the `${{ values.envName }}` environment once these repository secrets exist: `HCLOUD_TOKEN`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` and `TF_STATE_BUCKET`

Apply and destroy run in the GitHub environments `dev`, `staging` and `prod`; add required reviewers to them to approve changes. Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the credentials and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
