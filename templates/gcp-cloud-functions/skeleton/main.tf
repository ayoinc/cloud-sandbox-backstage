# =============================================================================
# GCP Cloud Run Functions - Root Module
# =============================================================================
# Instantiates the cloud-function child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "cloud_function" {
  source = "./modules/cloud-function"

  name                          = var.name
  environment                   = var.environment
  project_id                    = var.project_id
  region                        = var.region
  description                   = var.description
  owner                         = var.owner
  labels                        = var.labels
  runtime                       = var.runtime
  entry_point                   = var.entry_point
  source_dir                    = var.source_dir
  trigger_type                  = var.trigger_type
  allow_unauthenticated         = var.allow_unauthenticated
  invokers                      = var.invokers
  ingress_settings              = var.ingress_settings
  available_memory              = var.available_memory
  timeout_seconds               = var.timeout_seconds
  min_instance_count            = var.min_instance_count
  max_instance_count            = var.max_instance_count
  environment_variables         = var.environment_variables
  secret_environment_variables  = var.secret_environment_variables
  runtime_service_account_roles = var.runtime_service_account_roles
  enable_apis                   = var.enable_apis
}
