{%- set provider = values.cloud_provider -%}
{%- if provider == "aws" -%}
  {%- set cloud = "AWS" -%}{%- set net = "VPC" -%}{%- set k8s = "EKS" -%}{%- set db = "RDS for PostgreSQL" -%}
{%- elif provider == "azure" -%}
  {%- set cloud = "Azure" -%}{%- set net = "virtual network" -%}{%- set k8s = "AKS" -%}{%- set db = "Azure Database for PostgreSQL" -%}
{%- else -%}
  {%- set cloud = "Google Cloud" -%}{%- set net = "VPC network" -%}{%- set k8s = "GKE Autopilot" -%}{%- set db = "Cloud SQL for PostgreSQL" -%}
{%- endif -%}
# ${{ values.name }}

${{ values.description }}

A ${{ cloud }} sandbox managed with Terraform: a ${{ net }} with public and
private subnets and, when switched on, a bastion host, a Kubernetes cluster
(${{ k8s }}) and a PostgreSQL database (${{ db }}).

## Configuration

The values chosen when the sandbox was created are in `terraform.tfvars`:

| Setting         | Value                         |
| --------------- | ----------------------------- |
| Cloud provider  | ${{ cloud }}                  |
| Region          | `${{ values.region }}`        |
| Environment     | `${{ values.environment }}`   |
| Network CIDR    | `${{ values.vpc_cidr }}`      |
| Public subnets  | ${{ values.public_subnets }}  |
| Private subnets | ${{ values.private_subnets }} |
| Bastion host    | ${{ "yes" if values.include_bastion else "no" }} |
| Kubernetes      | ${{ "yes" if values.include_eks else "no" }} |
| Database        | ${{ "yes" if values.include_rds else "no" }} |

Edit `terraform.tfvars` and push to change the sandbox.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request:

| Job           | What it does                                                       |
| ------------- | ------------------------------------------------------------------ |
| Validate      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` |
| Lint          | TFLint with the Terraform and ${{ cloud }} rule sets               |
| Test          | `terraform test` against mocked providers                          |
| Security scan | Trivy; fails on HIGH and CRITICAL findings                         |
| Plan          | `terraform plan`, once deployment credentials exist                |
| Apply         | `terraform apply` on `main`, once deployment credentials exist     |

Plan and Apply are skipped until these repository secrets are set:

{% if provider == "aws" -%}
| Secret            | Purpose                                                    |
| ----------------- | ---------------------------------------------------------- |
| `AWS_ROLE_ARN`    | IAM role the workflow assumes through GitHub OIDC          |
| `TF_STATE_BUCKET` | S3 bucket that stores the Terraform state                  |

The optional repository variable `TF_STATE_REGION` names the region of the
state bucket when it differs from `${{ values.region }}`.
{%- elif provider == "azure" -%}
| Secret                     | Purpose                                                          |
| -------------------------- | ---------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | App registration with a federated credential for this repository |
| `AZURE_TENANT_ID`          | Tenant of that app registration                                  |
| `AZURE_SUBSCRIPTION_ID`    | Subscription the sandbox is created in                           |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account that stores the Terraform state                  |

The state goes to the blob container `tfstate`; the optional repository
variable `TF_STATE_CONTAINER` names another one. The identity needs the
Contributor role on the subscription and Storage Blob Data Contributor on the
state container.
{%- else -%}
| Secret                           | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider for this repository  |
| `GCP_SERVICE_ACCOUNT`            | Service account the workflow impersonates       |
| `GCP_PROJECT_ID`                 | Project the sandbox is created in               |
| `TF_STATE_BUCKET`                | Cloud Storage bucket that stores the Terraform state |
{%- endif %}

Run the workflow manually with the action `destroy` to remove the sandbox.

## Working locally

Checks that need no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

Planning and applying:

{% if provider == "aws" -%}
```bash
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/terraform.tfstate" \
  -backend-config="region=${{ values.region }}" \
  -backend-config="use_lockfile=true"
terraform plan
terraform apply
```
{%- elif provider == "azure" -%}
```bash
az login
export ARM_SUBSCRIPTION_ID=<subscription id>
terraform init \
  -backend-config="storage_account_name=<state storage account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform plan
terraform apply
```
{%- else -%}
```bash
gcloud auth application-default login
export TF_VAR_project_id=<project id>
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="prefix=${{ values.name }}"
terraform plan
terraform apply
```
{%- endif %}

See `docs/index.md` for details.
