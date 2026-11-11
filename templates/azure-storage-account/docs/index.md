# Azure Storage Account Template

This template creates a repository with the Terraform configuration of an Azure Storage account and a pipeline that validates and deploys it.

## What It Creates

- Resource group and general-purpose v2 storage account
- Entra ID as the only way in: no shared keys, no anonymous access
- Firewall that denies everything by default, with an optional private endpoint for the blob service
- Private blob containers, versioning, change feed and soft delete
- Lifecycle policy that tiers blobs and expires previous versions
- Optional customer-managed key from Key Vault, data role assignments and access logs

## Form Fields

| Field                 | Description                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------ |
| Storage Account Name  | Name used in resource names; at most 15 characters because account names are limited to 24 |
| Description           | Purpose of the account                                                                     |
| Owner                 | Team that owns the resource                                                                |
| Environment           | Environment the pipeline deploys on push; variable files for all three are generated       |
| Azure Region          | Region of the account                                                                      |
| Redundancy            | How many copies Azure keeps, and where                                                     |
| Default Access Tier   | Tier of blobs that have none set                                                           |
| Containers            | Private blob containers to create                                                          |
| Blob Versioning       | Keep previous versions of overwritten and deleted blobs                                    |
| Soft Delete Retention | Days a deleted blob or container can be restored                                           |
| Repository Location   | GitHub repository to create                                                                |

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

The account has no keys. Add the object IDs of the people and workloads that need the data to `blob_data_contributor_principal_ids` or `blob_data_reader_principal_ids`, and open a network path (`allowed_ip_ranges` or `private_endpoint_subnet_id`) in the environment file.

## Support

Contact the Platform Team for assistance.
