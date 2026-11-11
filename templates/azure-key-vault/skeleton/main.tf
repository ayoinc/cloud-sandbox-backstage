# =============================================================================
# Azure Key Vault - Root Module
# =============================================================================
# Instantiates the key-vault child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "key_vault" {
  source = "./modules/key-vault"

  name                               = var.name
  environment                        = var.environment
  location                           = var.location
  description                        = var.description
  owner                              = var.owner
  tags                               = var.tags
  sku_name                           = var.sku_name
  soft_delete_retention_days         = var.soft_delete_retention_days
  enabled_for_disk_encryption        = var.enabled_for_disk_encryption
  enabled_for_deployment             = var.enabled_for_deployment
  enabled_for_template_deployment    = var.enabled_for_template_deployment
  public_network_access_enabled      = var.public_network_access_enabled
  allowed_ip_ranges                  = var.allowed_ip_ranges
  allowed_subnet_ids                 = var.allowed_subnet_ids
  trusted_services_bypass            = var.trusted_services_bypass
  private_endpoint_subnet_id         = var.private_endpoint_subnet_id
  private_dns_zone_id                = var.private_dns_zone_id
  administrator_principal_ids        = var.administrator_principal_ids
  secrets_officer_principal_ids      = var.secrets_officer_principal_ids
  secrets_user_principal_ids         = var.secrets_user_principal_ids
  crypto_user_principal_ids          = var.crypto_user_principal_ids
  certificates_officer_principal_ids = var.certificates_officer_principal_ids
  log_analytics_workspace_id         = var.log_analytics_workspace_id
}
