# DigitalOcean Kubernetes Cluster Template

This template creates a repository with the Terraform configuration of a DigitalOcean Kubernetes (DOKS) cluster and a pipeline that validates and deploys it.

## What It Creates

- A VPC and a DOKS cluster inside it
- An autoscaling default node pool, with further pools declared in a variable
- Automatic patch upgrades in a maintenance window, with surge upgrades
- Container registry integration, optionally creating the registry
- An optional allowlist for the Kubernetes API and a highly available control plane in production
- A DigitalOcean project that groups the resources

## Form Fields

| Field                                | Description                                                                          |
| ------------------------------------ | ------------------------------------------------------------------------------------ |
| Cluster Name                         | Name of the cluster; the environment is appended                                     |
| Description                          | Purpose of the cluster                                                               |
| Owner                                | Team that owns the resource                                                          |
| Environment                          | Environment the pipeline deploys on push; variable files for all three are generated |
| Region                               | DigitalOcean region                                                                  |
| Kubernetes Version                   | Minor version; the latest patch release is used                                      |
| Node Size, Minimum and Maximum Count | Default node pool of the chosen environment                                          |
| Container Registry                   | Integrate with the existing registry, create one, or none                            |
| Repository Location                  | GitHub repository to create                                                          |

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`                    | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs a cloud account.

Plan and apply are skipped until these repository secrets exist:

| Secret                                             | Description                                  |
| -------------------------------------------------- | -------------------------------------------- |
| `DIGITALOCEAN_TOKEN`                               | Scoped API token                             |
| `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY` | Spaces key for the Terraform state           |
| `TF_STATE_BUCKET`                                  | Spaces bucket that holds the Terraform state |

Credentials are never written to the repository. The documentation of the generated repository explains how to create them.

### After the First Apply

Run `doctl kubernetes cluster kubeconfig save <cluster>` to configure `kubectl` with short-lived credentials.

## Support

Contact the Platform Team for assistance.
