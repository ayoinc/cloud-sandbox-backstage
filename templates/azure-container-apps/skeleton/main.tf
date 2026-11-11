# =============================================================================
# Azure Container Apps - Root Module
# =============================================================================
# Instantiates the container-app child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "container_app" {
  source = "./modules/container-app"

  name                            = var.name
  environment                     = var.environment
  location                        = var.location
  description                     = var.description
  owner                           = var.owner
  tags                            = var.tags
  container_image                 = var.container_image
  container_cpu                   = var.container_cpu
  container_memory                = var.container_memory
  environment_variables           = var.environment_variables
  secret_environment_variables    = var.secret_environment_variables
  key_vault_id                    = var.key_vault_id
  container_registry              = var.container_registry
  min_replicas                    = var.min_replicas
  max_replicas                    = var.max_replicas
  concurrent_requests_per_replica = var.concurrent_requests_per_replica
  target_port                     = var.target_port
  external_ingress_enabled        = var.external_ingress_enabled
  health_probe_path               = var.health_probe_path
  infrastructure_subnet_id        = var.infrastructure_subnet_id
  internal_load_balancer_enabled  = var.internal_load_balancer_enabled
  zone_redundancy_enabled         = var.zone_redundancy_enabled
  log_retention_days              = var.log_retention_days
}
