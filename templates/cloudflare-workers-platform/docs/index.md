# Cloudflare Workers Platform Template

This template creates a repository with a Cloudflare Worker, the Terraform configuration of everything it needs and a pipeline that tests and deploys both.

## What It Creates

- A Worker (ES module) with tests that run on Node.js with in-memory bindings
- An R2 bucket bound to the Worker
- A D1 database or a Workers KV namespace bound to the Worker
- A generated bearer token, bound as a secret, that the Worker requires on every data request
- A custom domain, optional routes, and the workers.dev address switched off when a custom domain is set
- Workers Logs

## Form Fields

| Field               | Description                                                                          |
| ------------------- | ------------------------------------------------------------------------------------ |
| Worker Name         | Name of the Worker; the environment is appended                                      |
| Description         | Purpose of the Worker                                                                |
| Owner               | Team that owns the component                                                         |
| Environment         | Environment the pipeline deploys on push; variable files for all three are generated |
| Data Store          | D1 database or Workers KV namespace                                                  |
| R2 Bucket Location  | Location hint of the bucket and the database                                         |
| Custom Domain       | Optional hostname in a zone of the same account                                      |
| Repository Location | GitHub repository to create                                                          |

## The Generated Repository

| Path                                                       | Content                                           |
| ---------------------------------------------------------- | ------------------------------------------------- |
| `worker/`                                                  | Worker code and its tests                         |
| `main.tf`, `variables.tf`, `outputs.tf`                    | Terraform configuration (Cloudflare provider v5)  |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                 |
| `tests/`                                                   | Terraform tests that run against mocked providers |
| `.github/workflows/terraform.yaml`                         | Pipeline                                          |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                   |

### Pipeline

The pipeline passes on the first push with nothing configured: it runs the Worker tests, checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov.

Plan and apply are skipped until these repository secrets exist:

| Secret                                     | Description                              |
| ------------------------------------------ | ---------------------------------------- |
| `CLOUDFLARE_API_TOKEN`                     | API token with the Workers permissions   |
| `CLOUDFLARE_ACCOUNT_ID`                    | Account to deploy into                   |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | R2 credentials for the Terraform state   |
| `TF_STATE_BUCKET`                          | R2 bucket that holds the Terraform state |

Credentials are never written to the repository. The documentation of the generated repository lists the token permissions and explains how to create the state bucket.

## Support

Contact the Platform Team for assistance.
