{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
# ${{ values.name }}
#
# One module per cloud implements the whole stack; the settings in
# terraform.tfvars and environments/ decide what it creates.
{%- if aws %}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

module "aws" {
  source = "./modules/aws"

  name_prefix         = local.name_prefix
  environment         = var.environment
  region              = var.aws_region
  secondary_region    = var.aws_secondary_region
  tags                = local.tags
  infrastructure_type = var.infrastructure_type

  enable_networking           = var.enable_networking
  network_cidr                = var.aws_network_cidr
  existing_network            = var.aws_existing_network
  allowed_ingress_cidrs       = var.allowed_ingress_cidrs
  enable_security_group_rules = var.enable_security_group_rules
  require_flow_logs           = local.compliance.require_flow_logs

  enable_kubernetes            = var.enable_kubernetes
  kubernetes_version           = var.kubernetes_version
  kubernetes_api_allowed_cidrs = var.kubernetes_api_allowed_cidrs
  node_size                    = var.node_size
  enable_autoscaling           = var.enable_autoscaling
  min_nodes                    = var.min_nodes
  max_nodes                    = var.max_nodes

  enable_database = var.enable_database
  database_type   = var.database_type
  enable_storage  = local.enable_storage
  enable_cdn      = var.enable_cdn

  enable_waf                  = var.enable_waf
  enable_secrets_manager      = var.enable_secrets_manager
  enable_kms                  = local.enable_kms
  enable_backup               = local.enable_backup
  require_deletion_protection = local.require_deletion_protection

  enable_monitoring         = var.enable_monitoring
  enable_managed_prometheus = local.enable_managed_prometheus
  enable_alerting           = var.enable_alerting
  alert_email               = var.alert_email
  log_retention_days        = local.log_retention_days

  enable_disaster_recovery = var.enable_disaster_recovery
  enable_cost_optimization = var.enable_cost_optimization
}
{%- endif %}
{%- if azure %}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------

module "azure" {
  source = "./modules/azure"

  name_prefix         = local.name_prefix
  environment         = var.environment
  region              = var.azure_location
  secondary_region    = var.azure_secondary_location
  tags                = local.tags
  infrastructure_type = var.infrastructure_type

  enable_networking           = var.enable_networking
  network_cidr                = var.azure_network_cidr
  existing_network            = var.azure_existing_network
  allowed_ingress_cidrs       = var.allowed_ingress_cidrs
  enable_security_group_rules = var.enable_security_group_rules
  require_flow_logs           = local.compliance.require_flow_logs

  enable_kubernetes            = var.enable_kubernetes
  kubernetes_version           = var.kubernetes_version
  kubernetes_api_allowed_cidrs = var.kubernetes_api_allowed_cidrs
  node_size                    = var.node_size
  enable_autoscaling           = var.enable_autoscaling
  min_nodes                    = var.min_nodes
  max_nodes                    = var.max_nodes

  enable_database = var.enable_database
  database_type   = var.database_type
  enable_storage  = local.enable_storage
  enable_cdn      = var.enable_cdn

  enable_waf                  = var.enable_waf
  enable_secrets_manager      = var.enable_secrets_manager
  enable_kms                  = local.enable_kms
  enable_backup               = local.enable_backup
  require_deletion_protection = local.require_deletion_protection

  enable_monitoring         = var.enable_monitoring
  enable_managed_prometheus = local.enable_managed_prometheus
  enable_alerting           = var.enable_alerting
  alert_email               = var.alert_email
  log_retention_days        = local.log_retention_days

  enable_disaster_recovery = var.enable_disaster_recovery
  enable_cost_optimization = var.enable_cost_optimization
}
{%- endif %}
{%- if gcp %}

# -----------------------------------------------------------------------------
# Google Cloud
# -----------------------------------------------------------------------------

module "gcp" {
  source = "./modules/gcp"

  project_id = var.gcp_project_id

  name_prefix         = local.name_prefix
  environment         = var.environment
  region              = var.gcp_region
  secondary_region    = var.gcp_secondary_region
  tags                = local.tags
  infrastructure_type = var.infrastructure_type

  enable_networking           = var.enable_networking
  network_cidr                = var.gcp_network_cidr
  existing_network            = var.gcp_existing_network
  allowed_ingress_cidrs       = var.allowed_ingress_cidrs
  enable_security_group_rules = var.enable_security_group_rules
  require_flow_logs           = local.compliance.require_flow_logs

  enable_kubernetes            = var.enable_kubernetes
  kubernetes_version           = var.kubernetes_version
  kubernetes_api_allowed_cidrs = var.kubernetes_api_allowed_cidrs
  node_size                    = var.node_size
  enable_autoscaling           = var.enable_autoscaling
  min_nodes                    = var.min_nodes
  max_nodes                    = var.max_nodes

  enable_database = var.enable_database
  database_type   = var.database_type
  enable_storage  = local.enable_storage
  enable_cdn      = var.enable_cdn

  enable_waf                  = var.enable_waf
  enable_secrets_manager      = var.enable_secrets_manager
  enable_kms                  = local.enable_kms
  enable_backup               = local.enable_backup
  require_deletion_protection = local.require_deletion_protection

  enable_monitoring         = var.enable_monitoring
  enable_managed_prometheus = local.enable_managed_prometheus
  enable_alerting           = var.enable_alerting
  alert_email               = var.alert_email
  log_retention_days        = local.log_retention_days

  enable_disaster_recovery = var.enable_disaster_recovery
  enable_cost_optimization = var.enable_cost_optimization
}
{%- endif %}
{%- if datadog %}

# -----------------------------------------------------------------------------
# Datadog: connects the cloud account so that its metrics reach Datadog
# -----------------------------------------------------------------------------
{%- if aws %}

module "datadog_aws" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/datadog-aws"

  name_prefix = local.name_prefix
  tags        = local.tags

  datadog_site = var.datadog_site
}
{%- endif %}
{%- if azure %}

module "datadog_azure" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/datadog-azure"

  name_prefix = local.name_prefix
  tags        = local.tags
}
{%- endif %}
{%- if gcp %}

module "datadog_gcp" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/datadog-gcp"

  name_prefix = local.name_prefix
  tags        = local.tags

  project_id = var.gcp_project_id
}
{%- endif %}
{%- endif %}
{%- if newrelic %}

# -----------------------------------------------------------------------------
# New Relic: links the cloud account so that its metrics reach New Relic
# -----------------------------------------------------------------------------
{%- if aws %}

module "newrelic_aws" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/newrelic-aws"

  name_prefix = local.name_prefix
  tags        = local.tags
}
{%- endif %}
{%- if azure %}

module "newrelic_azure" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/newrelic-azure"

  name_prefix = local.name_prefix
  tags        = local.tags
}
{%- endif %}
{%- if gcp %}

module "newrelic_gcp" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/newrelic-gcp"

  name_prefix = local.name_prefix
  tags        = local.tags

  project_id      = var.gcp_project_id
  newrelic_region = var.newrelic_region
}
{%- endif %}
{%- endif %}
{%- if elastic %}

# -----------------------------------------------------------------------------
# Elastic Stack: Elasticsearch and Kibana on Elastic Cloud, next to the stack
# -----------------------------------------------------------------------------

module "elastic" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/integrations/elastic"

  name_prefix = local.name_prefix
  tags        = local.tags

  cloud_provider = "${{ "azure" if values.cloud_provider == "azure" else ("gcp" if values.cloud_provider == "gcp" else "aws") }}"
  region         = var.${{ "azure_location" if values.cloud_provider == "azure" else ("gcp_region" if values.cloud_provider == "gcp" else "aws_region") }}
  zone_count     = var.environment == "production" ? 2 : 1
}
{%- endif %}
