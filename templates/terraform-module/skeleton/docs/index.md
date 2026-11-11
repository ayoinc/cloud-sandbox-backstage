{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# ${{ values.name }}

${{ values.description }}

## Overview

This repository is a reusable Terraform module for {% if values.provider == 'multi-cloud' %}AWS, Azure and Google Cloud{% elif aws %}AWS{% elif azure %}Azure{% else %}Google Cloud{% endif %}. It
is made of building blocks: one submodule per concern, switched on with an
`enable_*` variable of the root module.

| Building block | Variable | Default |{% if aws %} AWS |{% endif %}{% if azure %} Azure |{% endif %}{% if gcp %} Google Cloud |{% endif %}
| -------------- | -------- | ------- |{% if aws %} --- |{% endif %}{% if azure %} ----- |{% endif %}{% if gcp %} ------------ |{% endif %}
| Network | `enable_network` | on |{% if aws %} VPC, public/private/database subnets, NAT, flow logs |{% endif %}{% if azure %} Virtual network, subnets per tier, NSGs, NAT gateway |{% endif %}{% if gcp %} VPC network, subnets, Cloud NAT, firewall rules |{% endif %}
| Security | `enable_security` | on |{% if aws %} KMS key, Secrets Manager secret, application role |{% endif %}{% if azure %} Key Vault, managed identity |{% endif %}{% if gcp %} Cloud KMS key, Secret Manager, service account |{% endif %}
| Storage | `enable_storage` | on |{% if aws %} S3 bucket, optional EFS |{% endif %}{% if azure %} Storage account, containers, optional file share |{% endif %}{% if gcp %} Cloud Storage bucket, optional Filestore |{% endif %}
| Observability | `enable_observability` | on |{% if aws %} CloudWatch log groups, dashboard, alarms, SNS topic |{% endif %}{% if azure %} Log Analytics, Application Insights, alerts |{% endif %}{% if gcp %} Log sink and bucket, alert policies, dashboard |{% endif %}
| Compute | `enable_compute` | off |{% if aws %} Launch template and Auto Scaling group |{% endif %}{% if azure %} Virtual machine scale set |{% endif %}{% if gcp %} Instance template and managed instance group |{% endif %}
| Database | `enable_database` | off |{% if aws %} RDS, optional ElastiCache |{% endif %}{% if azure %} PostgreSQL flexible server, optional Managed Redis |{% endif %}{% if gcp %} Cloud SQL, optional Memorystore |{% endif %}
| Kubernetes | `enable_kubernetes` | off |{% if aws %} EKS cluster and node group |{% endif %}{% if azure %} AKS cluster |{% endif %}{% if gcp %} GKE cluster, Artifact Registry |{% endif %}
| Serverless | `enable_serverless` | off |{% if aws %} Lambda, optional API Gateway and SQS |{% endif %}{% if azure %} Function app, optional API Management and Service Bus |{% endif %}{% if gcp %} Cloud Run or Cloud Functions, optional Pub/Sub |{% endif %}

Compute, database and Kubernetes run inside the network this module creates;
enabling one of them without `enable_network` is rejected with a clear message.
{%- if values.provider == 'multi-cloud' %}

The flags apply to every cloud at once. A configuration that uses the module
must configure all three providers.
{%- endif %}

## Using the Module

```hcl
{%- if aws %}
provider "aws" {
  region = "us-east-1"
}
{% endif %}
{%- if azure %}
provider "azurerm" {
  features {}
}
{% endif %}
{%- if gcp %}
provider "google" {
  project = "my-project"
  region  = "us-central1"
}
{% endif %}
module "platform" {
  source = "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}"

  project_name = "billing"
  environment  = "dev"
{%- if gcp %}

  gcp_project_id = "my-project"
{%- endif %}

  enable_compute  = true
  enable_database = true
}
```

The module contains no provider configuration; the caller configures the
provider{% if values.provider == 'multi-cloud' %}s{% endif %}, as `examples/complete` does.

### Inputs

| Variable | Default | Purpose |
| -------- | ------- | ------- |
| `project_name` | required | Prefix of every resource name: lowercase letters, digits and hyphens |
| `environment` | `dev` | `dev`, `staging` or `prod` |
| `tags` | `{}` | Additional tags for all resources |
| `enable_*` | see above | Switch a building block on or off |
{%- if aws %}
| `aws_vpc_cidr` | `10.0.0.0/16` | CIDR block of the VPC |
| `aws_availability_zones` | `[]` | Zones for the subnets; empty uses the first three of the region |
{%- endif %}
{%- if azure %}
| `azure_location` | `eastus2` | Location for all resources |
| `azure_resource_group_name` | derived | Name of the resource group the module creates |
| `azure_vnet_cidr` | `10.1.0.0/16` | Address space of the virtual network |
{%- endif %}
{%- if gcp %}
| `gcp_project_id` | required | Project the resources are created in |
| `gcp_region` | `us-central1` | Region for regional resources |
| `gcp_zone` | zone a of the region | Zone for zonal resources |
| `gcp_network_cidr` | `10.2.0.0/16` | Address range of the VPC network |
| `gcp_enable_apis` | `true` | Enable the Google Cloud APIs the selected building blocks need |
{%- endif %}

### Submodules

The root passes only the essential settings to each submodule. Every submodule
has many more (sizes, retention, access lists, optional components), declared
in its `variables.tf` and shown in its `*.auto.tfvars.example`. To use them,
call the submodule directly:

```hcl
module "storage" {
  source = "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}//{% if aws %}aws{% elif azure %}azure{% else %}gcp{% endif %}/storage"

  project_name = "billing"
  environment  = "dev"
{%- if not aws and azure %}
  location            = "eastus2"
  resource_group_name = "billing-dev-rg"
{%- elif not aws and gcp %}
  project_id = "my-project"
  region     = "us-central1"
{%- endif %}
}
```

## Security Defaults

The building blocks are private and encrypted by default: data stores have no
public network access, object storage blocks public access and accepts TLS
only, Kubernetes API servers are private until an allow list is set, and
nothing accepts traffic from `0.0.0.0/0`. The pipeline's Trivy scan fails on
HIGH and CRITICAL findings; the few exceptions are marked in the code with
their reason.
{%- if gcp %}

Customer-managed encryption on Google Cloud: the root passes the KMS key to
the storage bucket. Other services need their service agent granted on the key
first; pass `kms_key_id` to those submodules yourself once that is done.
{%- endif %}

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main`, on pull
requests and on demand. It needs no secrets.

| Job             | What it does                                                                          |
| --------------- | ------------------------------------------------------------------------------------- |
| Validate        | `terraform fmt -check`, `terraform validate` for the module and for `examples/complete` |
| Lint            | TFLint on the module, every submodule and the example                                 |
| Test            | `terraform test` for the root module against mocked providers                         |
| Test submodules | `terraform test` in every submodule                                                   |
| Security scan   | Trivy with every building block switched on (`tests/all-features.tfvars`)             |
| Cost estimate   | Infracost on `examples/complete`; skipped until the secret `INFRACOST_API_KEY` is set |

## Development

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test

# One submodule
cd {% if aws %}aws{% elif azure %}azure{% else %}gcp{% endif %}/network
terraform init -backend=false
terraform test
```

Requirements: Terraform `${{ values.terraform_version }}`.

## Releasing

Consumers should pin a version. Tag a release and reference it:

```hcl
source = "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}?ref=v1.0.0"
```

## Repository Structure

```
${{ values.name }}/
├── .github/workflows/terraform.yaml   # Pipeline
{%- if aws %}
├── aws/                               # AWS submodules
{%- endif %}
{%- if azure %}
├── azure/                             # Azure submodules
{%- endif %}
{%- if gcp %}
├── gcp/                               # Google Cloud submodules
{%- endif %}
├── examples/complete/                 # Runnable example
├── tests/module.tftest.hcl            # Tests of the root module
├── tests/all-features.tfvars          # Every building block on, for the security scan
├── docs/index.md                      # This documentation
├── main.tf                            # Calls the submodules
├── variables.tf
├── outputs.tf
├── locals.tf
├── versions.tf
├── .tflint.hcl
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```
