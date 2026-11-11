{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
{%- set multi = values.cloud_provider == 'multi-cloud' -%}
{%- set backend = "azurerm" if values.cloud_provider == "azure" else ("gcs" if values.cloud_provider == "gcp" else "s3") -%}
{%- if multi -%}{%- set cloud = "AWS, Azure and Google Cloud" -%}{%- elif aws -%}{%- set cloud = "AWS" -%}{%- elif azure -%}{%- set cloud = "Azure" -%}{%- else -%}{%- set cloud = "Google Cloud" -%}{%- endif -%}
# ${{ values.name }}

${{ values.description }}

Infrastructure stack on ${{ cloud }}, managed with Terraform. Pattern:
`${{ values.infrastructure_type }}`. Environments: {% for e in values.environments %}`${{ e }}`{% if not loop.last %}, {% endif %}{% endfor %}.

## What the stack contains

| Feature | Setting | Value |
| ------- | ------- | ----- |
| Network | `enable_networking` | ${{ "on" if values.enable_networking else "off" }} |
| Tiered security groups | `enable_security_group_rules` | ${{ "on" if values.enable_security_group_rules else "off" }} |
| Kubernetes | `enable_kubernetes` | ${{ "on" if values.enable_kubernetes else "off" }}{% if values.enable_kubernetes %}: ${{ values.node_instance_type }} nodes, ${{ values.min_nodes }} to ${{ values.max_nodes }}{% if not values.enable_autoscaling %} (fixed at ${{ values.min_nodes }}){% endif %}{% endif %} |
| Database | `enable_database` | ${{ "on" if values.enable_database else "off" }}{% if values.enable_database %}: `${{ values.database_type }}`{% endif %} |
| Object storage | `enable_storage` | ${{ "on" if (values.enable_storage or values.enable_cdn) else "off" }} |
| CDN | `enable_cdn` | ${{ "on" if values.enable_cdn else "off" }} |
| Web application firewall | `enable_waf` | ${{ "on" if values.enable_waf else "off" }} |
| Secret store | `enable_secrets_manager` | ${{ "on" if values.enable_secrets_manager else "off" }} |
| Customer-managed keys | `enable_kms` | ${{ "on" if values.enable_kms else "off" }} |
| Backups | `enable_backup` | ${{ "on" if values.enable_backup else "off" }} |
| Compliance baseline | `compliance_framework` | `${{ values.compliance_framework }}` |
| Monitoring | `enable_monitoring` | ${{ "on" if values.enable_monitoring else "off" }}{% if values.enable_monitoring %}: `${{ values.monitoring_solution }}`{% endif %} |
| Alerting | `enable_alerting` | ${{ "on" if values.enable_alerting else "off" }} |
| Log retention | `log_retention_days` | ${{ values.log_retention_days }} days |
| Disaster recovery | `enable_disaster_recovery` | ${{ "on" if values.enable_disaster_recovery else "off" }} |
| Cost optimisation | `enable_cost_optimization` | ${{ "on" if values.enable_cost_optimization else "off" }} |

The settings live in `terraform.tfvars` and apply to every environment;
`environments/<name>.tfvars` holds what differs per environment. Edit and push
to change the stack.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request.
Formatting, validation, TFLint, `terraform test` against mocked providers and
a Trivy scan per environment need no credentials and always run. Plan and
Apply run per environment and are skipped until these repository secrets are
set:

| Secret | Purpose |
| ------ | ------- |
{%- if aws %}
| `AWS_ROLE_ARN` | IAM role the workflow assumes through GitHub OIDC |
{%- endif %}
{%- if azure %}
| `AZURE_CLIENT_ID` | App registration with a federated credential for this repository |
| `AZURE_TENANT_ID` | Tenant of that app registration |
| `AZURE_SUBSCRIPTION_ID` | Subscription the stack is created in |
{%- endif %}
{%- if gcp %}
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider for this repository |
| `GCP_SERVICE_ACCOUNT` | Service account the workflow impersonates |
| `GCP_PROJECT_ID` | Project the stack is created in |
{%- endif %}
{%- if backend == "azurerm" %}
| `TF_STATE_STORAGE_ACCOUNT` | Storage account that stores the Terraform state (container `tfstate`, or the one named by the variable `TF_STATE_CONTAINER`) |
{%- elif backend == "gcs" %}
| `TF_STATE_BUCKET` | Cloud Storage bucket that stores the Terraform state |
{%- else %}
| `TF_STATE_BUCKET` | S3 bucket that stores the Terraform state (in `${{ values.region }}`, or the region named by the variable `TF_STATE_REGION`) |
{%- endif %}
{%- if datadog %}
| `DD_API_KEY`, `DD_APP_KEY` | Datadog API and application keys |
{%- endif %}
{%- if newrelic %}
| `NEW_RELIC_API_KEY`, `NEW_RELIC_ACCOUNT_ID` | New Relic user API key and account ID |
{%- endif %}
{%- if elastic %}
| `EC_API_KEY` | Elastic Cloud API key |
{%- endif %}

## Working locally

Checks that need no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

Planning an environment:

{% if backend == "azurerm" -%}
```bash
az login
export ARM_SUBSCRIPTION_ID=<subscription id>
terraform init \
  -backend-config="storage_account_name=<state storage account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}/staging.tfstate"
terraform plan -var-file=environments/staging.tfvars
```
{%- elif backend == "gcs" -%}
```bash
gcloud auth application-default login
export TF_VAR_gcp_project_id=<project id>
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="prefix=${{ values.name }}/staging"
terraform plan -var-file=environments/staging.tfvars
```
{%- else -%}
```bash
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/staging/terraform.tfstate" \
  -backend-config="region=${{ values.region }}"
terraform plan -var-file=environments/staging.tfvars
```
{%- endif %}

See `docs/index.md` for details.
