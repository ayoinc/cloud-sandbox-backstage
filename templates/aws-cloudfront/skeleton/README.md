# ${{ values.name }}

${{ values.description }}

## Quick Start

```bash
# Initialize Terraform
terraform init

# Select workspace (environment)
terraform workspace select ${{ values.environment }} || terraform workspace new ${{ values.environment }}

# Review the plan
terraform plan -var-file=environments/${{ values.environment }}.tfvars

# Apply the configuration
terraform apply -var-file=environments/${{ values.environment }}.tfvars
```

## Project Structure

```
.
├── main.tf                 # Root module calling the CloudFront module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # AWS provider configuration
├── backend.tf              # S3 backend configuration
├── modules/
│   └── cloudfront/         # Reusable CloudFront module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── cloudfront.tftest.hcl  # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

| Environment | File                          | Description                      |
| ----------- | ----------------------------- | -------------------------------- |
| dev         | `environments/dev.tfvars`     | Development - short TTLs, no SSL |
| staging     | `environments/staging.tfvars` | Staging - production-like config |
| prod        | `environments/prod.tfvars`    | Production - full SSL, logging   |

## Configuration

| Setting         | Value                                |
| --------------- | ------------------------------------ |
| Origin Domain   | ${{ values.origin_domain_name }}     |
| Price Class     | ${{ values.price_class }}            |
| Default TTL     | ${{ values.default_ttl }} seconds    |
| Compression     | ${{ values.enable_compression }}     |
| Protocol Policy | ${{ values.viewer_protocol_policy }} |

## CI/CD

This project includes a GitHub Actions workflow with OIDC authentication that:

- Runs on pull requests and pushes to main
- Performs linting with TFLint
- Runs security scanning with tfsec and Checkov
- Plans and applies Terraform changes
- Runs Terraform native tests

## CloudFront Access URLs

After deployment, your content will be available at:

- **CloudFront Domain**: `https://<distribution-id>.cloudfront.net`
- **Custom Domain** (if configured): `https://${{ values.custom_domain }}`

## Cache Invalidation

To invalidate cached content:

```bash
# Invalidate all files
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"

# Invalidate specific paths
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/index.html" "/css/*"
```

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to Backstage TechDocs.

## Owner

**${{ values.owner }}**
