# =============================================================================
# Azure Storage Account - Root Module
# =============================================================================
# Instantiates the storage-account child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "storage_account" {
  source = "./modules/storage-account"

  name                                = var.name
  environment                         = var.environment
  location                            = var.location
  description                         = var.description
  owner                               = var.owner
  tags                                = var.tags
  replication_type                    = var.replication_type
  access_tier                         = var.access_tier
  container_names                     = var.container_names
  versioning_enabled                  = var.versioning_enabled
  soft_delete_retention_days          = var.soft_delete_retention_days
  cool_after_days                     = var.cool_after_days
  archive_after_days                  = var.archive_after_days
  expire_after_days                   = var.expire_after_days
  noncurrent_version_retention_days   = var.noncurrent_version_retention_days
  public_network_access_enabled       = var.public_network_access_enabled
  allowed_ip_ranges                   = var.allowed_ip_ranges
  allowed_subnet_ids                  = var.allowed_subnet_ids
  private_endpoint_subnet_id          = var.private_endpoint_subnet_id
  private_dns_zone_id                 = var.private_dns_zone_id
  customer_managed_key                = var.customer_managed_key
  blob_data_contributor_principal_ids = var.blob_data_contributor_principal_ids
  blob_data_reader_principal_ids      = var.blob_data_reader_principal_ids
  log_analytics_workspace_id          = var.log_analytics_workspace_id
}
