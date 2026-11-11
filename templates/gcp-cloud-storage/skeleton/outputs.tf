# =============================================================================
# GCP Cloud Storage - Root Outputs
# =============================================================================
# =============================================================================

output "bucket_name" {
  description = "Name of the bucket"
  value       = module.cloud_storage.bucket_name
}

output "bucket_url" {
  description = "gs:// URL of the bucket"
  value       = module.cloud_storage.bucket_url
}

output "bucket_self_link" {
  description = "URI of the bucket in the Cloud Storage API"
  value       = module.cloud_storage.bucket_self_link
}

output "bucket_location" {
  description = "Location of the bucket"
  value       = module.cloud_storage.bucket_location
}

output "kms_key_name" {
  description = "Cloud KMS key that encrypts the objects, or null with Google-managed encryption"
  value       = module.cloud_storage.kms_key_name
}
