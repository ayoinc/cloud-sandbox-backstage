# =============================================================================
# Azure Database for PostgreSQL - Root Module
# =============================================================================
# Instantiates the postgresql child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "postgresql" {
  source = "./modules/postgresql"

  name                          = var.name
  environment                   = var.environment
  location                      = var.location
  description                   = var.description
  owner                         = var.owner
  tags                          = var.tags
  postgresql_version            = var.postgresql_version
  sku_name                      = var.sku_name
  storage_gb                    = var.storage_gb
  high_availability_mode        = var.high_availability_mode
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  maintenance_window            = var.maintenance_window
  server_parameters             = var.server_parameters
  database_names                = var.database_names
  entra_administrators          = var.entra_administrators
  virtual_network_address_space = var.virtual_network_address_space
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  log_analytics_workspace_id    = var.log_analytics_workspace_id
}
