# ${{ values.name }}

${{ values.description }}

Terraform configuration of an Oracle Cloud Infrastructure compute instance (`${{ values.shape }}`) in its own VCN. Access is controlled by a network security group; the instance is {% if values.assignPublicIp %}public, with SSH limited to the networks you name{% else %}private, behind a NAT gateway{% endif %}.

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
# Uses the DEFAULT profile of ~/.oci/config (create it with `oci setup config`)
export TF_VAR_compartment_ocid=<compartment ocid>

terraform init \
  -backend-config="namespace=<object storage namespace>" \
  -backend-config="region=${{ values.region }}" \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/${{ values.envName }}/terraform.tfstate"
terraform plan -var-file=environments/${{ values.envName }}.tfvars
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

## Project Structure

```
.
├── main.tf                 # Image lookup and the compute instance
├── network.tf              # VCN, gateways, subnet and network security group
├── cloud-init.yaml         # First-boot configuration of the instance
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # OCI provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (OCI Object Storage)
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── compute.tftest.hcl  # Terraform tests against a mocked provider
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                                            |
| ----------- | ----------------------------- | ------------------------------------------------------ |
| dev         | `environments/dev.tfvars`     | 1 OCPU, 6 GB (within the Always Free limits on A1)     |
| staging     | `environments/staging.tfvars` | 2 OCPUs, 12 GB                                         |
| prod        | `environments/prod.tfvars`    | 4 OCPUs, 24 GB, larger boot volume                     |

The environment chosen in the portal (`${{ values.envName }}`) uses the size entered in the form instead.

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** for the `${{ values.envName }}` environment once these repository secrets exist: `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_PRIVATE_KEY`, `OCI_COMPARTMENT_OCID`, `TF_STATE_BUCKET` and `TF_STATE_NAMESPACE`

Apply and destroy run in the GitHub environments `dev`, `staging` and `prod`; add required reviewers to them to approve changes. Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the credentials and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
