output "bucket_name" {
  description = "Name of the bucket."
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = google_storage_bucket.main.url
}

output "bucket_self_link" {
  description = "Self link of the bucket."
  value       = google_storage_bucket.main.self_link
}

output "bucket_location" {
  description = "Location of the bucket."
  value       = google_storage_bucket.main.location
}

output "filestore_id" {
  description = "ID of the Filestore instance, or null when disabled."
  value       = var.enable_filestore ? google_filestore_instance.main[0].id : null
}

output "filestore_name" {
  description = "Name of the Filestore instance, or null when disabled."
  value       = var.enable_filestore ? google_filestore_instance.main[0].name : null
}

output "filestore_ip" {
  description = "IP address of the Filestore instance, or null when disabled."
  value       = var.enable_filestore ? google_filestore_instance.main[0].networks[0].ip_addresses[0] : null
}

output "filestore_mount_path" {
  description = "NFS export to mount (<ip>:/<share>), or null when disabled."
  value       = var.enable_filestore ? "${google_filestore_instance.main[0].networks[0].ip_addresses[0]}:/${var.filestore_share_name}" : null
}
