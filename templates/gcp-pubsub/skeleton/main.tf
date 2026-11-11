# =============================================================================
# GCP Pub/Sub - Root Module
# =============================================================================
# Instantiates the pubsub child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "pubsub" {
  source = "./modules/pubsub"

  name                        = var.name
  environment                 = var.environment
  project_id                  = var.project_id
  region                      = var.region
  owner                       = var.owner
  labels                      = var.labels
  message_retention_duration  = var.message_retention_duration
  allowed_persistence_regions = var.allowed_persistence_regions
  kms_key_name                = var.kms_key_name
  schema_type                 = var.schema_type
  schema_definition_file      = var.schema_definition_file
  schema_encoding             = var.schema_encoding
  subscriptions               = var.subscriptions
  dead_letter_enabled         = var.dead_letter_enabled
  max_delivery_attempts       = var.max_delivery_attempts
  publishers                  = var.publishers
  subscribers                 = var.subscribers
  enable_apis                 = var.enable_apis
}
