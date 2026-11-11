# Azure Container Apps Template

This template creates a repository with the Terraform configuration of an Azure Container Apps service and a pipeline that validates and deploys it.

## What It Creates

- Resource group, Log Analytics workspace and Container Apps environment (workload profiles, Consumption)
- User-assigned managed identity, with optional `AcrPull` and Key Vault access
- Container app with HTTPS ingress, health probes and HTTP autoscaling
- Optional virtual network integration with an internal load balancer and zone redundancy

## Form Fields

| Field                        | Description                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------------- |
| Application Name             | Name used in resource names; at most 21 characters because app names are limited to 32 |
| Description                  | Purpose of the application                                                             |
| Owner                        | Team that owns the component                                                           |
| Environment                  | Environment the pipeline deploys on push; variable files for all three are generated   |
| Azure Region                 | Region of the environment                                                              |
| Container Image              | Image to run; the default is a public sample that listens on port 80                   |
| Container Port               | Port the container listens on                                                          |
| CPU per Replica              | vCPUs; memory is 2Gi per vCPU                                                          |
| Minimum and Maximum Replicas | Autoscaling range; a minimum of 0 scales to zero                                       |
| External Ingress             | Accept requests from the internet instead of only from the environment                 |
| Repository Location          | GitHub repository to create                                                            |

Values chosen in the form apply to the chosen environment; the other two environment files start from defaults suited to them.

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/`        | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline runs on pushes to `main` and passes with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs a Azure account.

Plan and apply sign in to Azure with OIDC. They are skipped until these repository secrets exist:

| Secret                  | Description                                                         |
| ----------------------- | ------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`       | Application (client) ID of the app registration or managed identity |
| `AZURE_TENANT_ID`       | Directory (tenant) ID                                               |
| `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into                                         |
| `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state                      |

The documentation of the generated repository explains how to create the app registration, its permissions and the state storage account.

### After the First Apply

Replace the sample image with your own in the environment file. For a private registry set `container_registry`; for secrets set `key_vault_id` and `secret_environment_variables`.

## Support

Contact the Platform Team for assistance.
