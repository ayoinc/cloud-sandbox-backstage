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

# Get connection details
terraform output cloud_sql_info
```

## Project Structure

```
.
├── main.tf                 # Root module calling the Cloud SQL module
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Google provider configuration
├── backend.tf              # GCS backend configuration
├── modules/
│   └── cloud-sql/          # Reusable Cloud SQL module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── cloud-sql.tftest.hcl  # Terraform native tests
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Connecting to Cloud SQL

### Using Cloud SQL Proxy

```bash
# Get the connection name
CONNECTION_NAME=$(terraform output -raw connection_name)

# Start Cloud SQL Proxy
cloud-sql-proxy $CONNECTION_NAME --port=5432

# Connect using psql (PostgreSQL) or mysql client
psql -h localhost -p 5432 -U app_user -d ${{ values.name | replace("-", "_") }}
```

### Getting Database Credentials

```bash
# Get the password from Secret Manager
gcloud secrets versions access latest --secret="${{ values.name }}-${{ values.environment }}-db-password"

# Or get it from Terraform output
terraform output -raw user_password
```

## Environments

| Environment | File                          | Description                      |
| ----------- | ----------------------------- | -------------------------------- |
| dev         | `environments/dev.tfvars`     | Development - minimal, public IP |
| staging     | `environments/staging.tfvars` | Staging - production-like        |
| prod        | `environments/prod.tfvars`    | Production - HA, private IP      |

## CI/CD

This project includes a GitHub Actions workflow with OIDC authentication that:

- Runs on pull requests and pushes to main
- Performs linting with TFLint
- Runs security scanning with tfsec and Checkov
- Plans and applies Terraform changes
- Runs Terraform native tests

## Documentation

See the [docs](docs/) directory for detailed documentation, which is published to Backstage TechDocs.

## Owner

**${{ values.owner }}**
