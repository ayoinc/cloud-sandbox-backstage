data "azurerm_client_config" "current" {}

locals {
  is_production = var.environment == "production"

  # The Azure modules of cloud-sandbox-backstage name the production environment "prod".
  module_environment = local.is_production ? "prod" : var.environment
  environment_code   = { dev = "dev", staging = "stg", production = "prd" }[var.environment]

  # Names with hyphens use the project name with repeated hyphens collapsed. Storage accounts and the Key Vault
  # allow 24 characters without hyphens: 2 for the kind, 11 of the project, 3 for the environment and 6 random ones.
  project_slug   = replace(var.project_name, "/-+/", "-")
  name_prefix    = "${local.project_slug}-${var.environment}"
  compact_prefix = "${substr(replace(var.project_name, "-", ""), 0, 11)}${local.environment_code}"
  unique_suffix  = random_string.suffix.result

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Platform    = "data"
  }

  # --- What the chosen features add up to --------------------------------------

  # A Synapse workspace cannot exist without a Data Lake Storage Gen2 filesystem, so the warehouse brings the
  # storage account with it even when the data lake zones are disabled.
  create_synapse      = var.enable_data_warehouse
  create_lake_account = var.enable_data_lake || local.create_synapse
  lake_zones          = var.enable_data_lake ? ["raw", "processed", "curated"] : []
  lake_filesystems    = concat(local.lake_zones, local.create_synapse ? ["synapse"] : [])

  etl_native = var.enable_etl_pipelines && var.etl_engine == "native"
  etl_spark  = var.enable_etl_pipelines && var.etl_engine == "spark"

  # Data Factory is both the native ETL engine and the orchestrator.
  create_data_factory = local.etl_native || var.enable_orchestration
  create_databricks   = local.etl_spark

  create_purview = var.enable_data_catalog
  # Lineage is reported to the catalog, so it needs one.
  lineage_enabled = var.enable_data_lineage && local.create_purview

  customer_managed_keys = var.enable_encryption && (local.create_lake_account || var.enable_ml_platform || local.create_databricks)
  # The vault holds the encryption key, the SQL administrator password and the secrets of Azure Machine Learning.
  create_key_vault = local.customer_managed_keys || var.enable_ml_platform || local.create_synapse

  restrict_networks = length(var.allowed_ip_ranges) > 0
}

# Storage accounts, Key Vaults, Synapse workspaces, Purview accounts, Event Hubs namespaces and data factories
# share one global namespace each.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

module "resource_group" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/resource-group?ref=${{ values.moduleRef }}"

  name        = local.name_prefix
  project     = local.project_slug
  environment = local.module_environment
  location    = var.location
  tags        = local.common_tags
}
