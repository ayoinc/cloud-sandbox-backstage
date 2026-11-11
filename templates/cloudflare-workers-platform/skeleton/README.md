# ${{ values.name }}

${{ values.description }}

A Cloudflare Worker with an R2 bucket and a {% if values.dataStore == 'd1' %}D1 database{% else %}Workers KV namespace{% endif %}. Terraform creates the storage, uploads the Worker with its bindings and attaches the routing, so one `terraform apply` is a complete deployment.

## Quick Start

```bash
# Check everything without a Cloudflare account
node --test "worker/*.test.mjs"
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
```

```bash
# Deploy from a workstation
export CLOUDFLARE_API_TOKEN=<api token>
export TF_VAR_account_id=<account id>
export AWS_ACCESS_KEY_ID=<r2 access key id> AWS_SECRET_ACCESS_KEY=<r2 secret access key>
export AWS_ENDPOINT_URL_S3="https://$TF_VAR_account_id.r2.cloudflarestorage.com"

terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/${{ values.envName }}/terraform.tfstate"
terraform apply -var-file=environments/${{ values.envName }}.tfvars
```

## The Worker

`worker/index.mjs` is a single ES module that Terraform uploads unchanged.

| Route                 | Methods            | Backed by                                                      |
| --------------------- | ------------------ | -------------------------------------------------------------- |
| `/healthz`            | `GET`              | Nothing; open to everyone                                      |
| `/items/<key>`        | `GET, PUT, DELETE` | {% if values.dataStore == 'd1' %}D1 database (`DB`){% else %}KV namespace (`KV`){% endif %} |
| `/files/<key>`        | `GET, PUT, DELETE` | R2 bucket (`BUCKET`)                                           |

Every route except `/healthz` requires `Authorization: Bearer <token>`. Terraform generates the token and binds it to the Worker as a secret:

```bash
TOKEN=$(terraform output -raw api_token)
curl -X PUT -H "Authorization: Bearer $TOKEN" --data 'hello' https://<worker address>/items/greeting
curl -H "Authorization: Bearer $TOKEN" https://<worker address>/items/greeting
```

## Project Structure

```
.
├── worker/
│   ├── index.mjs           # Worker code
│   └── index.test.mjs      # Tests with in-memory bindings
├── main.tf                 # R2 bucket, data store, Worker, bindings and routing
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
├── providers.tf            # Cloudflare provider configuration
├── versions.tf             # Terraform and provider version constraints
├── backend.tf              # State backend (Cloudflare R2)
├── environments/
│   ├── dev.tfvars          # Development environment
│   ├── staging.tfvars      # Staging environment
│   └── prod.tfvars         # Production environment
├── tests/
│   └── workers.tftest.hcl  # Terraform tests against mocked providers
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```

## Environments

Each environment is a separate Worker (`${{ values.name }}-<environment>`) with its own bucket and data store.

| Environment | File                          | Description                                  |
| ----------- | ----------------------------- | -------------------------------------------- |
| dev         | `environments/dev.tfvars`     | Development, every request logged            |
| staging     | `environments/staging.tfvars` | Staging, mirrors production                  |
| prod        | `environments/prod.tfvars`    | Production, a tenth of the requests logged   |

## CI/CD

`.github/workflows/terraform.yaml` runs on every push to `main` and on demand:

- **Checks** (no account needed): Worker tests, `terraform fmt`, `terraform validate`, TFLint, `terraform test`, Trivy and Checkov
- **Plan and apply** for the `${{ values.envName }}` environment once these repository secrets exist: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` and `TF_STATE_BUCKET`

Other environments, destroy and drift detection are run from **Actions > Terraform > Run workflow**. The [documentation](docs/index.md) explains how to create the token and the state bucket.

## Documentation

See the [docs](docs/) directory, which is published to TechDocs in the portal.

## Owner

**${{ values.owner }}**
