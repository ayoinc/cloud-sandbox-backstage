# ${{ values.name }}

${{ values.description }}

Terraform configuration of the Cloudflare zone `${{ values.domain }}`: TLS hardening, DNSSEC, DNS records, WAF rulesets, rate limiting and security response headers.

## Quick Start

```bash
# Check the configuration without any account
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

```bash
# Plan against the real zone
export CLOUDFLARE_API_TOKEN=<api token>
export TF_VAR_account_id=<account id>
export AWS_ACCESS_KEY_ID=<r2 access key id> AWS_SECRET_ACCESS_KEY=<r2 secret access key>
export AWS_ENDPOINT_URL_S3="https://$TF_VAR_account_id.r2.cloudflarestorage.com"

terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/prod/terraform.tfstate"
terraform plan -var-file=environments/prod.tfvars
```

## Project Structure

```
.
├── main.tf                 # Zone, TLS settings, DNSSEC and DNS records
├── rulesets.tf             # WAF, rate limiting and response header rules
├── variables.tf            # Input variable declarations
├── outputs.tf              # Name servers, DS record and record names
├── providers.tf            # Cloudflare provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (Cloudflare R2)
├── environments/
│   └── prod.tfvars         # Values of the zone
├── tests/
│   └── zone.tftest.hcl     # Terraform tests against a mocked provider
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Changing the Zone

Edit `environments/prod.tfvars`: add records to `dns_records`, rules to `firewall_rules`, or change the TLS settings. Push to `main`; the pipeline plans and applies the change.

```hcl
dns_records = {
  api = {
    name    = "api.${{ values.domain }}"
    type    = "CNAME"
    content = "${{ values.domain }}"
    proxied = true
  }
}
```

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** once these repository secrets exist: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` and `TF_STATE_BUCKET`

Apply and destroy run in the GitHub environment `prod`; add required reviewers to it to approve changes. Destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the token and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
