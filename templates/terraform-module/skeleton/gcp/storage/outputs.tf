# -----------------------------------------------------------------------------
# GCP Storage Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Cloud Storage Bucket Outputs
# -----------------------------------------------------------------------------

output "bucket_name" {
  description = "The name of the storage bucket"
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "The URL of the storage bucket"
  value       = google_storage_bucket.main.url
}

output "bucket_self_link" {
  description = "The self link of the storage bucket"
  value       = google_storage_bucket.main.self_link
}

output "bucket_location" {
  description = "The location of the storage bucket"
  value       = google_storage_bucket.main.location
}

output "bucket_storage_class" {
  description = "The storage class of the bucket"
  value       = google_storage_bucket.main.storage_class
}

output "bucket_project" {
  description = "The project ID containing the bucket"
  value       = google_storage_bucket.main.project
}

# -----------------------------------------------------------------------------
# Bucket Access Outputs
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "The unique identifier of the bucket"
  value       = google_storage_bucket.main.id
}

output "bucket_uniform_access_enabled" {
  description = "Whether uniform bucket-level access is enabled"
  value       = google_storage_bucket.main.uniform_bucket_level_access
}

# -----------------------------------------------------------------------------
# Filestore Outputs
# -----------------------------------------------------------------------------

output "filestore_id" {
  description = "The ID of the Filestore instance (if enabled)"
  value       = var.enable_filestore ? google_filestore_instance.main[0].id : null
}

output "filestore_name" {
  description = "The name of the Filestore instance (if enabled)"
  value       = var.enable_filestore ? google_filestore_instance.main[0].name : null
}

output "filestore_ip" {
  description = "The IP address of the Filestore instance (if enabled)"
  value       = var.enable_filestore ? google_filestore_instance.main[0].networks[0].ip_addresses[0] : null
}

output "filestore_file_shares" {
  description = "The file shares of the Filestore instance (if enabled)"
  value       = var.enable_filestore ? google_filestore_instance.main[0].file_shares : null
}

output "filestore_mount_path" {
  description = "The NFS mount path for the Filestore instance (if enabled)"
  value       = var.enable_filestore ? "${google_filestore_instance.main[0].networks[0].ip_addresses[0]}:/${var.filestore_share_name}" : null
}

output "filestore_network" {
  description = "The network configuration of the Filestore instance (if enabled)"
  value       = var.enable_filestore ? google_filestore_instance.main[0].networks : null
}
