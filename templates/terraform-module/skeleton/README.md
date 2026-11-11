{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# ${{ values.name }}

${{ values.description }}

A Terraform module of building blocks for {% if values.provider == 'multi-cloud' %}AWS, Azure and Google Cloud{% elif aws %}AWS{% elif azure %}Azure{% else %}Google Cloud{% endif %}. Each
building block is a submodule that is switched on with an `enable_*` variable
and can also be used on its own.

## Building blocks

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

Compute, database and Kubernetes run inside the network this module creates,
so they need `enable_network = true`.
{%- if values.provider == 'multi-cloud' %}

The flags apply to every cloud: `enable_storage = true` creates object storage
on AWS, on Azure and on Google Cloud.
{%- endif %}

## Usage

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

`examples/complete` is a runnable configuration. Every variable is described in
`variables.tf`, every output in `outputs.tf`. The submodules under
{% if aws %}`aws/`{% endif %}{% if aws and (azure or gcp) %}, {% endif %}{% if azure %}`azure/`{% endif %}{% if azure and gcp %}, {% endif %}{% if gcp %}`gcp/`{% endif %} have many more settings than the root passes on; call a
submodule directly, or extend `main.tf`, to use them. Each submodule has a
`*.auto.tfvars.example` that shows its settings.

## Requirements

- Terraform `${{ values.terraform_version }}`
{%- if aws %}
- Provider `hashicorp/aws` `~> 6.0`
{%- endif %}
{%- if azure %}
- Provider `hashicorp/azurerm` `~> 4.0`
{%- endif %}
{%- if gcp %}
- Provider `hashicorp/google` `~> 8.0`
{%- endif %}

## Development

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

The tests plan against mocked providers and need no cloud account. The same
checks, TFLint and a Trivy scan run in `.github/workflows/terraform.yaml` on
every push and pull request. See `docs/index.md`.
