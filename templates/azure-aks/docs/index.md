# Azure AKS Cluster Template

This template creates a repository with the Terraform configuration of an Azure Kubernetes Service cluster and a pipeline that validates and deploys it.

## What It Creates

- Resource group and AKS cluster with Entra ID sign-in and Azure RBAC (local accounts disabled)
- System node pool, autoscaling user node pool and an optional spot node pool
- Azure Container Registry with pull access for the cluster
- Log Analytics workspace with Container Insights
- Azure Policy add-on

## Form Fields

| Field | Description |
| ----- | ----------- |
| Cluster Name | Name used in resource names |
| Description | Purpose of the cluster |
| Owner | Team that owns the resource |
| Environment | Environment the pipeline deploys on push; variable files for all three are generated |
| Azure Region | Region of the cluster |
| Kubernetes Version | Minor version; AKS selects the latest patch |
| Node VM Size, Node Count, Max Node Count | Size of the user node pool in the chosen environment |
| Repository Location | GitHub repository to create |

## The Generated Repository

| Path | Content |
| ---- | ------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/` | Terraform configuration |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment |
| `tests/` | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml` | Pipeline |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml` | TechDocs and the catalog entity |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs an Azure account.

Plan and apply sign in to Azure with OIDC. They are skipped until these repository secrets exist:

| Secret | Description |
| ------ | ----------- |
| `AZURE_CLIENT_ID` | Application (client) ID of the app registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into |
| `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state |
| `INFRACOST_API_KEY` | Optional: cost estimates on pull requests |

The documentation of the generated repository explains how to create the app registration, its permissions and the state storage account.

### After the First Apply

Grant users the `Azure Kubernetes Service RBAC Cluster Admin` role (or a narrower one) on the cluster, then run `az aks get-credentials`.

## Support

Contact the Platform Team for assistance.
