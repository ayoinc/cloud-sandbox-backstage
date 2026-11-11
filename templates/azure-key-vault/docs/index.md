# Azure Key Vault Template

This template creates a repository with the Terraform configuration of an Azure Key Vault and a pipeline that validates and deploys it.

## What It Creates

- Resource group and key vault
- Azure RBAC for secrets, keys and certificates, with role assignments for the principals you list
- Soft delete with purge protection
- Firewall that denies everything by default, with an optional private endpoint
- Optional audit log in Log Analytics

## Form Fields

| Field                 | Description                                                                              |
| --------------------- | ---------------------------------------------------------------------------------------- |
| Key Vault Name        | Name used in resource names; at most 13 characters because vault names are limited to 24 |
| Description           | Purpose of the vault                                                                     |
| Owner                 | Team that owns the resource                                                              |
| Environment           | Environment the pipeline deploys on push; variable files for all three are generated     |
| Azure Region          | Region of the vault                                                                      |
| Tier                  | Standard, or Premium for keys held in a hardware security module                         |
| Soft Delete Retention | Days a deleted object can be recovered; fixed once the vault exists                      |
| Public Network Access | Keep the public endpoint, behind a firewall that admits only the ranges you list         |
| Repository Location   | GitHub repository to create                                                              |

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

Nobody can use the vault yet. Add object IDs to the `*_principal_ids` lists in the environment file, and open a network path with `allowed_ip_ranges` or `private_endpoint_subnet_id`.

## Support

Contact the Platform Team for assistance.
