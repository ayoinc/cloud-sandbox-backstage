{%- set provider = values.provider -%}
{%- set backend = values.backendType -%}
{%- set res = values.resources or [] -%}
{%- set has_network = "virtual-network" in res or "virtual-machine" in res -%}
{%- if provider == "aws" -%}{%- set cloud = "AWS" -%}{%- elif provider == "azure" -%}{%- set cloud = "Azure" -%}{%- else -%}{%- set cloud = "Google Cloud" -%}{%- endif -%}
# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds one ${{ values.componentType }} infrastructure component on
${{ cloud }} for the `${{ values.environment }}` environment in `${{ values.region }}`. It is
described in Terraform, tested without cloud access and deployed by GitHub
Actions.

| Setting           | Value                             |
| ----------------- | --------------------------------- |
| Component type    | `${{ values.componentType }}`     |
| Project           | `${{ values.projectName }}`       |
| Business unit     | `${{ values.businessUnit }}`      |
| Cost center       | `${{ values.costCenter }}`        |
{%- if values.applicationId %}
| Application ID    | `${{ values.applicationId }}`     |
{%- endif %}
| Owner             | `${{ values.owner }}`             |
| Naming convention | `${{ values.namingConvention }}`  |
{%- if values.secondaryRegion %}
| Secondary region  | `${{ values.secondaryRegion }}`   |
{%- endif %}

## Resources

| Resource | Included | What is created |
| -------- | -------- | --------------- |
{%- if provider == "aws" %}
| Resource container | ${{ "yes" if values.createResourceGroup else "no" }} | AWS resource group that collects the component's resources by tag |
| Object storage | ${{ "yes" if "object-storage" in res else "no" }} | S3 bucket: versioned, encrypted with its own KMS key, no public access, TLS only{% if values.secondaryRegion %}; replicated to `${{ values.secondaryRegion }}`{% endif %} |
| Virtual network | ${{ "yes" if has_network else "no" }} | VPC with two public and two private subnets in two zones, NAT gateway |
| Key management | ${{ "yes" if "key-vault" in res else "no" }} | KMS key with yearly rotation and an alias |
| Container registry | ${{ "yes" if "container-registry" in res else "no" }} | ECR repository: immutable tags, scan on push, old images expire |
| Log workspace | ${{ "yes" if "log-workspace" in res else "no" }} | CloudWatch log group with retention |
| Virtual machine | ${{ "yes" if "virtual-machine" in res else "no" }} | EC2 instance (Amazon Linux 2023) in a private subnet, reached with Session Manager |
{%- elif provider == "azure" %}
| Resource container | ${{ "yes" if values.createResourceGroup else "no" }} | Resource group; when not created, an existing one named by `resource_group_name` is used |
| Object storage | ${{ "yes" if "object-storage" in res else "no" }} | Storage account with a private blob container: TLS 1.2, versioning, network access denied by default{% if values.secondaryRegion %}; replicated to a second account in `${{ values.secondaryRegion }}`{% endif %} |
| Virtual network | ${{ "yes" if has_network else "no" }} | Virtual network with a public and a private subnet, network security group, NAT gateway |
| Key management | ${{ "yes" if "key-vault" in res else "no" }} | Key Vault with role-based access, purge protection, network access denied by default |
| Container registry | ${{ "yes" if "container-registry" in res else "no" }} | Container Registry without admin user |
| Log workspace | ${{ "yes" if "log-workspace" in res else "no" }} | Log Analytics workspace with retention |
| Virtual machine | ${{ "yes" if "virtual-machine" in res else "no" }} | Ubuntu 22.04 VM in the private subnet without public IP address, SSH key only |
{%- else %}
| Resource container | ${{ "yes" if values.createResourceGroup else "no" }} | New project in the folder `folder_id`, billed to `billing_account`; when not created, the existing project `project_id` is used |
| Object storage | ${{ "yes" if "object-storage" in res else "no" }} | Cloud Storage bucket: versioned, uniform access, public access prevented{% if values.secondaryRegion %}; copied daily to a bucket in `${{ values.secondaryRegion }}`{% endif %} |
| Virtual network | ${{ "yes" if has_network else "no" }} | VPC network with a public and a private subnet, flow logs, Cloud NAT |
| Key management | ${{ "yes" if "key-vault" in res else "no" }} | Cloud KMS key ring with a key that rotates every 90 days |
| Container registry | ${{ "yes" if "container-registry" in res else "no" }} | Artifact Registry repository for container images with immutable tags and cleanup policies |
| Log workspace | ${{ "yes" if "log-workspace" in res else "no" }} | Cloud Logging bucket with retention |
| Virtual machine | ${{ "yes" if "virtual-machine" in res else "no" }} | Debian 12 VM without external IP address, reached through Identity-Aware Proxy with OS Login |
{%- endif %}

Every resource is defined in its own file (`storage.tf`, `network.tf`,
`key_vault.tf`, `registry.tf`, `logs.tf`, `vm.tf`) together with the variables
that tune it and its outputs. Files of resources that were not selected are not
part of this repository.

## Names and Tags

`modules/naming` builds every resource name from the convention chosen for this
component:

| Convention   | Pattern                                 |
| ------------ | --------------------------------------- |
| `enterprise` | company-project-environment-type-number |
| `team`       | team-project-type-environment-number    |
| `project`    | project-type-environment-number         |

The company is `${{ values.company }}`, the team is the business unit, and the
environment is shortened to `dev`, `stg` or `prod`. Names that a service limits
in length are shortened and get a hash; names that must be unique across
${{ cloud }} get a random suffix.

`modules/tagging` produces the {% if provider == "gcp" %}labels{% else %}tags{% endif %} every resource carries: component, component
type, project, environment, business unit, cost center, owner{% if values.applicationId %}, application ID{% endif %} and
`ManagedBy = terraform`.
{%- if "virtual-machine" in res %}

## Automatic Shutdown

{% if values.autoShutdown -%}
Outside production the virtual machine is stopped on the schedule
`${{ values.autoShutdown }}` (UTC), set as `auto_shutdown_schedule` in
`terraform.tfvars`.
{%- if provider == "azure" %} Azure stops the machine every day at that time; the
weekday part of the expression is not used.
{%- endif %}
{%- else -%}
No shutdown schedule is set. Add `auto_shutdown_schedule = "0 19 * * 1-5"` to
`terraform.tfvars` to stop the virtual machine on a schedule outside production.
{%- endif %}
Production machines are never stopped automatically. Start a stopped machine
from the ${{ cloud }} console or CLI.
{%- endif %}

## Changing the Component

Edit `terraform.tfvars` and push. Settings with defaults are declared at the
top of each resource file, for example `log_retention_days` in `logs.tf`.

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main`, on pull
requests and on demand.

| Job           | What it does                                                                  | Needs credentials |
| ------------- | ----------------------------------------------------------------------------- | ----------------- |
| Validate      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` | No                |
| Lint          | TFLint with the Terraform and ${{ cloud }} rule sets                          | No                |
| Test          | `terraform test` for the naming and tagging modules and for the component, against mocked providers | No |
| Security scan | Trivy on the Terraform code; fails on HIGH and CRITICAL findings              | No                |
| Plan          | `terraform plan` against the state backend                                    | Yes               |
| Apply         | `terraform apply` of that plan, on pushes to `main`                           | Yes               |

Plan and Apply are skipped, not failed, until all of these are configured under
Settings > Secrets and variables > Actions:

| Name | Kind | Purpose |
| ---- | ---- | ------- |
{%- if provider == "aws" or backend == "s3" %}
| `AWS_ROLE_ARN` | secret | IAM role the workflow assumes through GitHub OIDC |
{%- endif %}
{%- if provider == "azure" or backend == "azure" %}
| `AZURE_CLIENT_ID` | secret | App registration with a federated credential for this repository |
| `AZURE_TENANT_ID` | secret | Tenant of that app registration |
| `AZURE_SUBSCRIPTION_ID` | secret | Subscription the workflow works in |
{%- endif %}
{%- if provider == "gcp" or backend == "gcs" %}
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | secret | Workload identity provider for this repository |
| `GCP_SERVICE_ACCOUNT` | secret | Service account the workflow impersonates |
{%- endif %}
{%- if provider == "gcp" %}
| `GCP_PROJECT_ID` | secret | Existing project to deploy into (used when no project is created) |
| `GCP_BILLING_ACCOUNT` | secret | Billing account of the new project (used when a project is created) |
| `GCP_FOLDER_ID` | variable | Folder of the new project, for example `folders/123456789` (used when a project is created) |
{%- endif %}
{%- if backend == "remote" %}
| `TF_API_TOKEN` | secret | HCP Terraform / Terraform Enterprise API token |
| `TF_CLOUD_ORGANIZATION` | variable | HCP Terraform organization |
{%- elif backend == "s3" %}
| `TF_STATE_BUCKET` | secret | S3 bucket that stores the state |
| `TF_STATE_REGION` | variable | Region of that bucket; optional, defaults to `${{ values.region if provider == "aws" else "us-east-1" }}` |
{%- elif backend == "azure" %}
| `TF_STATE_STORAGE_ACCOUNT` | secret | Storage account that stores the state |
| `TF_STATE_CONTAINER` | variable | Blob container; optional, defaults to `tfstate` |
{%- elif backend == "gcs" %}
| `TF_STATE_BUCKET` | secret | Cloud Storage bucket that stores the state |
{%- endif %}

Apply runs in the GitHub environment `${{ values.environment }}`. Add required
reviewers to that environment to approve each apply by hand. Start the workflow
manually with the action `destroy` to remove the component.

## State

{% if backend == "remote" -%}
The state is kept in HCP Terraform (or Terraform Enterprise), in the workspace
{%- if values.stateFileStructure == "hierarchical" %}
`${{ values.name }}-${{ values.environment }}` of the project `${{ values.componentType }}-${{ values.provider }}`.
{%- else %}
`${{ values.componentType }}-${{ values.provider }}-${{ values.environment }}-${{ values.name }}`.
{%- endif %}
Set the workspace's execution mode to **Local**: Terraform then runs in GitHub
Actions with the credentials below, and HCP Terraform stores and locks the
state.
{%- else -%}
The state is kept in {% if backend == "s3" %}an S3 bucket{% elif backend == "azure" %}an Azure Storage container{% else %}a Cloud Storage bucket{% endif %}; `backend.tf` sets its path
inside the bucket (${{ "hierarchical" if values.stateFileStructure == "hierarchical" else "flat" }} layout).
{%- if values.separateWorkspaces %}
Each environment uses its own Terraform workspace; the pipeline selects the
workspace `${{ values.environment }}`.
{%- else %}
The environment is part of the state path and the default workspace is used.
{%- endif %}
State locking is ${{ "on" if values.enableStateLocking else "off: concurrent runs are not prevented" }}.
{%- endif %}

## Working Locally

These checks need Terraform 1.10 or later and no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

## Repository Structure

```
${{ values.name }}/
├── .github/workflows/terraform.yaml   # Validation and deployment pipeline
├── docs/index.md                      # This documentation
├── modules/naming/                    # Naming conventions
├── modules/tagging/                   # Standard tags and labels
├── tests/                             # Terraform tests against mocked providers
├── backend.tf                         # State backend
├── main.tf                            # Naming, tagging and the resource container
├── providers.tf
├── terraform.tfvars                   # The settings of this component
├── variables.tf
├── versions.tf
├── outputs.tf
├── .tflint.hcl                        # TFLint configuration
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```
