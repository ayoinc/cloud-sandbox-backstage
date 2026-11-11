# ${{ values.name }}

${{ values.description }}

## Architecture

| Resource                              | Purpose                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------- |
| `cloudflare_workers_script`           | The Worker `${{ values.name }}-<environment>`, uploaded from `worker/index.mjs` |
| `cloudflare_r2_bucket`                | Bucket bound as `BUCKET` (location hint `${{ values.r2Location }}`)     |
{%- if values.dataStore == 'd1' %}
| `cloudflare_d1_database`              | SQL database bound as `DB`                                              |
{%- else %}
| `cloudflare_workers_kv_namespace`     | Key-value namespace bound as `KV`                                       |
{%- endif %}
| `random_password`                     | Bearer token bound as the secret `API_TOKEN`                            |
| `cloudflare_workers_custom_domain`    | Hostname of the Worker{% if values.customHostname %}: `${{ values.customHostname }}` in ${{ values.envName }}{% else %}, when `custom_hostname` is set{% endif %} |
| `cloudflare_workers_route`            | Route patterns from `routes`                                            |
| `cloudflare_workers_script_subdomain` | Switches the workers.dev address on or off                              |

Workers Logs are enabled; view them under **Workers & Pages > the Worker > Observability**.

## Credentials

Nothing secret is stored in this repository. The pipeline reads these repository secrets:

| Secret                  | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | API token (permissions below)                        |
| `CLOUDFLARE_ACCOUNT_ID` | ID of the Cloudflare account                         |
| `R2_ACCESS_KEY_ID`      | Access key of an R2 API token for the state bucket   |
| `R2_SECRET_ACCESS_KEY`  | Secret key of that R2 API token                      |
| `TF_STATE_BUCKET`       | Name of the R2 bucket that holds the Terraform state |

### API Token

Create a custom token under **My Profile > API Tokens** with these permissions and nothing else:

| Scope   | Permission                                                                 |
| ------- | -------------------------------------------------------------------------- |
| Account | Workers Scripts: Edit, Workers R2 Storage: Edit, D1: Edit, Workers KV Storage: Edit |
| Zone    | Workers Routes: Edit (only when a custom domain or route is used)          |

Restrict the token to this account and, for the zone permission, to the zone of the custom domain. Cloudflare does not issue short-lived credentials to GitHub Actions, so give the token an expiry date and rotate it.

### State Bucket

```bash
npx wrangler r2 bucket create <state bucket>
```

Create an R2 API token under **R2 > Manage API Tokens** with *Object Read & Write* on that bucket only; its key pair is the two `R2_*` secrets. The state contains the generated bearer token, so keep the bucket private.

## Routing

| Setting               | Effect                                                                         |
| --------------------- | ------------------------------------------------------------------------------ |
| `custom_hostname`     | Serves the Worker on a hostname; Cloudflare creates the DNS record and certificate |
| `routes`              | Sends the paths of an existing site that match a pattern to the Worker         |
| `workers_dev_enabled` | Serves the Worker on `<worker>.<account subdomain>.workers.dev`                |

Environments without a custom hostname are served on workers.dev. Every data route requires the bearer token whichever entrance is used.

## Changing the Worker

Edit `worker/index.mjs`, extend `worker/index.test.mjs` and push. Terraform notices the changed file hash and uploads a new version. The file is uploaded as it is; if the Worker grows to need npm packages, add a bundling step that writes the bundle to `worker/index.mjs` before `terraform plan`.

To add a binding, add an entry to `candidate_bindings` in `main.tf`.

## Rotating the Bearer Token

```bash
terraform apply -var-file=environments/<environment>.tfvars -replace=random_password.api_token
```

## Pipeline

| Job             | Runs                                         | Needs credentials |
| --------------- | -------------------------------------------- | ----------------- |
| Worker Tests    | `node --check`, `node --test`                | No                |
| Validate        | `terraform fmt -check`, `terraform validate` | No                |
| TFLint          | Lint rules in `.tflint.hcl`                  | No                |
| Terraform Tests | `terraform test` against mocked providers    | No                |
| Security Scan   | Trivy and Checkov                            | No                |
| Plan, Apply     | On push to `main` and on demand              | Yes               |
| Destroy, Drift  | On demand from **Run workflow**              | Yes               |

## Provider Versions

`versions.tf` constrains the providers to a minor release line and `.terraform.lock.hcl` pins the exact releases, with checksums for Linux and macOS on x86-64 and Arm64. To upgrade:

```bash
terraform init -backend=false -upgrade
terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64
```
