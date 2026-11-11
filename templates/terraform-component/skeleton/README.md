{%- set provider = values.provider -%}
{%- set backend = values.backendType -%}
{%- set res = values.resources or [] -%}
{%- set has_network = "virtual-network" in res or "virtual-machine" in res -%}
{%- if provider == "aws" -%}{%- set cloud = "AWS" -%}{%- elif provider == "azure" -%}{%- set cloud = "Azure" -%}{%- else -%}{%- set cloud = "Google Cloud" -%}{%- endif -%}
# ${{ values.name }}

${{ values.description }}

A ${{ values.componentType }} infrastructure component on ${{ cloud }}, managed with
Terraform.

| Setting           | Value                             |
| ----------------- | --------------------------------- |
| Environment       | `${{ values.environment }}`       |
| Region            | `${{ values.region }}`            |
| Project           | `${{ values.projectName }}`       |
| Business unit     | `${{ values.businessUnit }}`      |
| Cost center       | `${{ values.costCenter }}`        |
| Naming convention | `${{ values.namingConvention }}`  |

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

Each resource lives in its own file with its variables and outputs, and has a
test file under `tests/`. Change the settings in `terraform.tfvars`.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request:
formatting, validation, TFLint, `terraform test` against mocked providers and a
Trivy scan need no credentials and always run. Plan and Apply are skipped until
the following are configured in the repository settings:

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

## Working locally

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

See `docs/index.md` for details.
