################################################################################
# GCP Cloud Storage Outputs
################################################################################

output "bucket_name" {
  description = "Name of the bucket"
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "URL of the bucket"
  value       = google_storage_bucket.this.url
}

output "bucket_self_link" {
  description = "Self link of the bucket"
  value       = google_storage_bucket.this.self_link
}

output "bucket_location" {
  description = "Location of the bucket"
  value       = google_storage_bucket.this.location
}

output "bucket_storage_class" {
  description = "Storage class of the bucket"
  value       = google_storage_bucket.this.storage_class
}

output "bucket_id" {
  description = "ID of the bucket"
  value       = google_storage_bucket.this.id
}

output "website_url" {
  description = "Website URL (if website hosting is enabled)"
  value       = var.website_config != null ? "https://storage.googleapis.com/${google_storage_bucket.this.name}" : null
}
