# =============================================================================
# GCP Cloud Storage Module - Outputs
# =============================================================================
# =============================================================================

output "bucket_name" {
  description = "Name of the bucket"
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket"
  value       = google_storage_bucket.main.url
}

output "bucket_self_link" {
  description = "URI of the bucket in the Cloud Storage API"
  value       = google_storage_bucket.main.self_link
}

output "bucket_location" {
  description = "Location of the bucket"
  value       = google_storage_bucket.main.location
}

output "kms_key_name" {
  description = "Cloud KMS key that encrypts the objects, or null with Google-managed encryption"
  value       = local.kms_key_name_set ? local.kms_key_name : null
}
