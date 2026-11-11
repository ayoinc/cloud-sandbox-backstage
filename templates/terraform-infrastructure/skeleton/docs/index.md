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

## Overview

This repository holds an infrastructure stack on ${{ cloud }}, described in
Terraform and deployed by GitHub Actions to {% if values.environments | length == 1 %}one environment{% else %}${{ values.environments | length }} environments{% endif %}:
{% for e in values.environments %}`${{ e }}`{% if not loop.last %}, {% endif %}{% endfor %}. Each environment has its own settings file, its own state
and its own stage in the pipeline.

| Setting | Value |
| ------- | ----- |
| Cloud | ${{ cloud }} |
| Infrastructure pattern | `${{ values.infrastructure_type }}` |
{%- if aws %}
| AWS region | `${{ values.region }}` |
{%- endif %}
{%- if azure %}
| Azure location | `${{ values.azure_location }}` |
{%- endif %}
{%- if gcp %}
| Google Cloud region | `${{ values.gcp_region }}` |
{%- endif %}
| Owner | `${{ values.owner }}` |

## Features

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

{% if multi -%}
The same stack is created on each of the three clouds by `modules/aws`,
`modules/azure` and `modules/gcp`.
{%- else -%}
Everything is implemented by `modules/${{ values.cloud_provider }}`.
{%- endif %} The root module passes it the settings
and applies the rules described below.

### What a feature creates

| Feature | Result |
| ------- | ------ |
| Network | Network with public and private subnets in two zones and NAT for outbound traffic. When off, name an existing network in `terraform.tfvars` ({% if aws %}`aws_existing_network`{% endif %}{% if multi %}, {% endif %}{% if azure %}`azure_existing_network`{% endif %}{% if multi %}, {% endif %}{% if gcp %}`gcp_existing_network`{% endif %}) before enabling components that need one |
| Tiered security groups | Separate web, app and data tiers; data stores accept traffic from the app tier and the cluster only |
| Kubernetes | Managed cluster with private nodes and a private API; `kubernetes_api_allowed_cidrs` opens the API to listed networks |
| Database | Private, encrypted managed database with generated credentials; highly available in production |
| Object storage | Private, versioned, encrypted bucket that accepts TLS only |
| CDN | CDN in front of the object storage, HTTPS only; the storage is reachable through the CDN only |
| Web application firewall | Managed-rule policy, attached to the CDN when there is one |
| Secret store | Holds the generated database credentials |
| Customer-managed keys | One key with rotation for storage, database, secrets and logs |
| Backups | Backup vault and plan; database backups kept for 35 days instead of 7 |
| Monitoring | Central log destination, diagnostics of the components, dashboard |
| Alerting | Notification target and alert rules for the components that exist; set `alert_email` to receive them |
| Disaster recovery | Object storage and database backups replicated to the secondary region |
| Cost optimisation | Storage lifecycle tiering; outside production also spot nodes, a single NAT and the smallest database tier |

### Infrastructure pattern

`${{ values.infrastructure_type }}`{% if values.infrastructure_type in ["container-platform", "ml-platform", "serverless-platform"] %} adds a container registry{% endif %}{% if values.infrastructure_type == "ml-platform" %} and{% endif %}{% if values.infrastructure_type in ["data-platform", "ml-platform"] %} adds two data-lake buckets, `raw` and `curated`, with lifecycle rules{% endif %}{% if values.infrastructure_type == "networking-foundation" %} adds a private DNS zone attached to the network{% endif %}{% if values.infrastructure_type == "web-application" %} adds nothing beyond the features above{% endif %}.

### Monitoring solution

{% if values.monitoring_solution == "native" -%}
`native`: the cloud's own logging, dashboards and alerts.
{%- elif values.monitoring_solution == "prometheus-grafana" -%}
`prometheus-grafana`: in addition to the cloud's own logging, a managed
Prometheus workspace wired to the cluster, and a managed Grafana where the
cloud offers one (Google Cloud does not).
{%- elif values.monitoring_solution == "elastic-stack" -%}
`elastic-stack`: in addition to the cloud's own logging, an Elasticsearch and
Kibana deployment on Elastic Cloud in the region of the stack
(`modules/integrations/elastic`). Its endpoints are Terraform outputs.
{%- elif values.monitoring_solution == "datadog" -%}
`datadog`: in addition to the cloud's own logging, the cloud account is
connected to Datadog so that its metrics appear there
(`modules/integrations/datadog-*`). Set `datadog_site` in `terraform.tfvars` if
your account is not on `datadoghq.com`. Logs are not forwarded.
{%- else -%}
`new-relic`: in addition to the cloud's own logging, the cloud account is
linked to New Relic so that its metrics appear there
(`modules/integrations/newrelic-*`). Set `newrelic_region` in `terraform.tfvars`
if your account is in the EU region.
{%- endif %}

### Compliance baseline

`compliance_framework` applies a baseline on top of the settings and tags
every resource with it. It makes the stack meet the framework's technical
expectations for these settings; it does not replace an audit.

| Framework | Minimum log retention | Customer-managed keys | Backups | Deletion protection | Flow logs |
| --------- | --------------------- | --------------------- | ------- | ------------------- | --------- |
| `none`    | as set                | as set                | as set  | production only     | no        |
| `cis`     | 365 days              | as set                | as set  | production only     | yes       |
| `pci-dss` | 365 days              | yes                   | yes     | yes                 | yes       |
| `hipaa`   | 2192 days (6 years)   | yes                   | yes     | yes                 | yes       |
| `sox`     | 2557 days (7 years)   | yes                   | yes     | yes                 | no        |
| `gdpr`    | as set                | yes                   | yes     | production only     | no        |

This stack uses `${{ values.compliance_framework }}`. The output `effective_settings` shows the
settings after the baseline is applied.

## Environments

| File | Purpose |
| ---- | ------- |
| `terraform.tfvars` | Settings shared by every environment |
{%- for e in values.environments %}
| `environments/${{ e }}.tfvars` | Settings of `${{ e }}`; they take precedence |
{%- endfor %}

Resource names start with the stack name and the short environment (`dev`,
`stg`, `prod`). Production is always protected from deletion and gets a highly
available database.

To add an environment, copy one of the files, set `environment`, and add the
name to the three `matrix.environment` lists in the workflow.

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main`, on pull
requests and on demand.

| Job           | What it does                                                                  | Needs credentials |
| ------------- | ----------------------------------------------------------------------------- | ----------------- |
| Validate      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` | No                |
| Lint          | TFLint with the Terraform and cloud rule sets                                 | No                |
| Test          | `terraform test` for the stack and for each module, against mocked providers  | No                |
| Security scan | Trivy per environment, with that environment's settings; fails on HIGH and CRITICAL findings | No |
| Plan          | `terraform plan` per environment against its remote state                     | Yes               |
| Apply         | `terraform apply` of that plan, one environment after the other, on pushes to `main` | Yes        |

Plan and Apply are skipped, not failed, until all of these repository secrets
are set:

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

Each Apply runs in the GitHub environment of the same name. Add required
reviewers to an environment (for example `production`) to approve its applies
by hand. Start the workflow manually with the action `destroy` to remove the
stack.

## Working Locally

These checks need Terraform 1.10 or later and no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

To plan an environment from your machine, initialise with its state:

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

## Repository Structure

```
${{ values.name }}/
├── .github/workflows/terraform.yaml   # Validation and deployment pipeline
├── docs/index.md                      # This documentation
├── environments/                      # One settings file per environment
├── modules/                           # The stack per cloud{% if datadog or newrelic or elastic %} and the monitoring integration{% endif %}
├── tests/infrastructure.tftest.hcl    # Tests of the stack against mocked providers
├── backend.tf                         # Remote state
├── locals.tf                          # Names, tags and the compliance baselines
├── main.tf                            # Calls the modules
├── outputs.tf
├── providers.tf
├── terraform.tfvars                   # Settings shared by every environment
├── variables.tf
├── versions.tf
├── .tflint.hcl                        # TFLint configuration
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```
