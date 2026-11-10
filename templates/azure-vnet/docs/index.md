# Azure Virtual Network Template

This template creates a repository with the Terraform configuration of an Azure Virtual Network and a pipeline that validates and deploys it.

## What It Creates

- Resource group and virtual network
- Public, private, database and AKS subnets, carved out of the address space
- Network security groups for the public, private and database subnets
- NAT gateway for outbound traffic (staging and production)
- Optional DDoS protection plan

## Form Fields

| Field | Description |
| ----- | ----------- |
| VNet Name | Name used in resource names |
| Description | Purpose of the network |
| Owner | Team that owns the resource |
| Environment | Environment the pipeline deploys on push; variable files for all three are generated |
| Azure Region | Region of the network |
| Address Space | CIDR block of the network in the chosen environment, /16 to /24 |
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

## Support

Contact the Platform Team for assistance.
