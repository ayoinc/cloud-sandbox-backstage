# Azure Full Infrastructure Template

This template creates a repository with the Terraform configuration of a complete Azure infrastructure stack and a pipeline that validates and deploys it. The stack is made of modules that you switch on or off.

## What It Creates

| Module      | Creates                                                                                                                       |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Networking  | Virtual network, five subnets with a network security group each; optional NAT gateway, Bastion host and DDoS protection plan |
| Compute     | Linux virtual machines with private addresses, SSH keys and an optional daily shutdown                                        |
| Containers  | AKS cluster with a system and an autoscaling user node pool, and a container registry                                         |
| Storage     | Storage account with blob versioning and soft delete                                                                          |
| Database    | PostgreSQL flexible server with one database                                                                                  |
| Security    | Key Vault with Azure RBAC authorization and purge protection                                                                  |
| Identity    | User-assigned managed identity for workloads                                                                                  |
| Monitoring  | Log Analytics workspace and Application Insights                                                                              |
| Integration | Service Bus namespace and Event Grid topic                                                                                    |
| Governance  | Monthly budget with alerts and tag policies in audit mode                                                                     |

Enabled modules are wired to each other: AKS, PostgreSQL and the virtual machines use the virtual network, AKS logs to the Log Analytics workspace, and the managed identity may read Key Vault secrets.

## Form Fields

| Field                                                                                        | Description                                                                          |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Project Name                                                                                 | Name used in resource names (3-13 characters)                                        |
| Description                                                                                  | Purpose of the stack                                                                 |
| Owner                                                                                        | Team that owns the infrastructure                                                    |
| Environment                                                                                  | Environment the pipeline deploys on push; variable files for all three are generated |
| Business Unit                                                                                | Recorded in the BusinessUnit and CostCenter tags                                     |
| Primary Region, Secondary Region                                                             | Region of the resources, and of the registry replica with Disaster Recovery          |
| Module switches                                                                              | The modules to create, the same set in every environment                             |
| Enable Disaster Recovery, Enable High Availability, Enable Auto-Shutdown, Auto-Shutdown Time | Applied to the chosen environment; the other environments get defaults               |
| Repository Location                                                                          | GitHub repository to create                                                          |

## The Generated Repository

| Path                                                       | Content                                            |
| ---------------------------------------------------------- | -------------------------------------------------- |
| `main.tf`, `variables.tf`, `outputs.tf`, `modules/`        | Terraform configuration                            |
| `environments/dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One variable file per environment                  |
| `tests/`                                                   | Terraform tests that run against a mocked provider |
| `.github/workflows/terraform.yaml`                         | Pipeline                                           |
| `docs/`, `mkdocs.yml`, `catalog-info.yaml`                 | TechDocs and the catalog entity                    |

### Pipeline

The pipeline passes on the first push with nothing configured: it checks formatting, validates the configuration, lints it with TFLint, runs the Terraform tests and scans it with Trivy and Checkov. None of these needs an Azure account.

Plan and apply sign in to Azure with OIDC. They are skipped until these repository secrets exist:

| Secret                  | Description                                     |
| ----------------------- | ----------------------------------------------- |
| `AZURE_CLIENT_ID`       | Application (client) ID of the app registration |
| `AZURE_TENANT_ID`       | Directory (tenant) ID                           |
| `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into                     |
| `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state  |
| `INFRACOST_API_KEY`     | Optional: cost estimates on pull requests       |

The documentation of the generated repository explains how to create the app registration, its permissions and the state storage account.

## Support

Contact the Platform Team for assistance.
