# Azure Database for PostgreSQL Template

This template creates a repository with the Terraform configuration of an Azure Database for PostgreSQL flexible server and a pipeline that validates and deploys it.

## What It Creates

- Resource group and PostgreSQL flexible server
- Private networking: a virtual network with a delegated subnet and a private DNS zone, or an existing subnet and zone
- Entra ID authentication only, with the administrator you name; no passwords
- A database, server parameters, backups with point-in-time restore
- Optional standby replica in another availability zone, and diagnostic logs

## Form Fields

| Field                                  | Description                                                                                |
| -------------------------------------- | ------------------------------------------------------------------------------------------ |
| Server Name                            | Name used in resource names                                                                |
| Description                            | Purpose of the database                                                                    |
| Owner                                  | Team that owns the resource                                                                |
| Environment                            | Environment the pipeline deploys on push; variable files for all three are generated       |
| Azure Region                           | Region of the server                                                                       |
| PostgreSQL Version                     | Major version                                                                              |
| Compute Size                           | Tier and VM size                                                                           |
| Storage                                | Provisioned storage in GiB; it grows automatically                                         |
| High Availability                      | Standby replica with automatic failover; needs General Purpose or Memory Optimized compute |
| Database Name                          | Database to create                                                                         |
| Administrator Object ID, Name and Type | Entra ID group, user or service principal that administers the server                      |
| Repository Location                    | GitHub repository to create                                                                |

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

Peer the created virtual network with the network of your workloads (or pass an existing subnet), then sign in as the Entra ID administrator with an access token and create database roles for your workloads' managed identities.

## Support

Contact the Platform Team for assistance.
