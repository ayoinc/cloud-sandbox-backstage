# =============================================================================
# GCP Cloud Storage - Root Module
# =============================================================================
# Instantiates the cloud-storage child module.
# Environment-specific values are passed with -var-file.
# =============================================================================

module "cloud_storage" {
  source = "./modules/cloud-storage"

  name                              = var.name
  environment                       = var.environment
  project_id                        = var.project_id
  owner                             = var.owner
  labels                            = var.labels
  location                          = var.location
  storage_class                     = var.storage_class
  force_destroy                     = var.force_destroy
  versioning_enabled                = var.versioning_enabled
  soft_delete_retention_days        = var.soft_delete_retention_days
  nearline_after_days               = var.nearline_after_days
  coldline_after_days               = var.coldline_after_days
  archive_after_days                = var.archive_after_days
  expire_after_days                 = var.expire_after_days
  noncurrent_versions_to_keep       = var.noncurrent_versions_to_keep
  noncurrent_version_retention_days = var.noncurrent_version_retention_days
  customer_managed_encryption       = var.customer_managed_encryption
  kms_key_name                      = var.kms_key_name
  kms_key_rotation_period           = var.kms_key_rotation_period
  object_viewers                    = var.object_viewers
  object_users                      = var.object_users
  object_admins                     = var.object_admins
  enable_apis                       = var.enable_apis
}
