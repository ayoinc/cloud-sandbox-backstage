# -----------------------------------------------------------------------------
# GCP Security Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# KMS Key Ring Outputs
# -----------------------------------------------------------------------------

output "key_ring_id" {
  description = "The ID of the KMS key ring"
  value       = google_kms_key_ring.main.id
}

output "key_ring_name" {
  description = "The name of the KMS key ring"
  value       = google_kms_key_ring.main.name
}

output "key_ring_location" {
  description = "The location of the KMS key ring"
  value       = google_kms_key_ring.main.location
}

# -----------------------------------------------------------------------------
# KMS Crypto Key Outputs
# -----------------------------------------------------------------------------

output "crypto_key_id" {
  description = "The ID of the KMS crypto key"
  value       = google_kms_crypto_key.main.id
}

output "crypto_key_name" {
  description = "The name of the KMS crypto key"
  value       = google_kms_crypto_key.main.name
}

output "crypto_key_self_link" {
  description = "The self link of the KMS crypto key"
  value       = "projects/${var.project_id}/locations/${var.region}/keyRings/${google_kms_key_ring.main.name}/cryptoKeys/${google_kms_crypto_key.main.name}"
}

output "crypto_key_rotation_period" {
  description = "The rotation period of the KMS crypto key"
  value       = google_kms_crypto_key.main.rotation_period
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "The email address of the application service account"
  value       = google_service_account.application.email
}

output "service_account_id" {
  description = "The unique ID of the application service account"
  value       = google_service_account.application.unique_id
}

output "service_account_name" {
  description = "The fully-qualified name of the application service account"
  value       = google_service_account.application.name
}

output "service_account_member" {
  description = "The IAM member string for the service account"
  value       = "serviceAccount:${google_service_account.application.email}"
}

# -----------------------------------------------------------------------------
# Secret Manager Outputs
# -----------------------------------------------------------------------------

output "secret_id" {
  description = "The ID of the main application secret"
  value       = google_secret_manager_secret.app_secrets.secret_id
}

output "secret_name" {
  description = "The fully-qualified name of the main application secret"
  value       = google_secret_manager_secret.app_secrets.name
}

output "secret_version_name" {
  description = "The name of the latest secret version"
  value       = google_secret_manager_secret_version.app_secrets.name
}

output "additional_secret_ids" {
  description = "Map of additional secret IDs"
  value = {
    for key, secret in google_secret_manager_secret.additional : key => secret.secret_id
  }
}

output "additional_secret_names" {
  description = "Map of additional secret names"
  value = {
    for key, secret in google_secret_manager_secret.additional : key => secret.name
  }
}

# -----------------------------------------------------------------------------
# Service Account Key Outputs (if created)
# -----------------------------------------------------------------------------

output "service_account_key_secret_id" {
  description = "The secret ID containing the service account key (if created)"
  value       = var.create_service_account_key ? google_secret_manager_secret.service_account_key[0].secret_id : null
}

# -----------------------------------------------------------------------------
# Project Information
# -----------------------------------------------------------------------------

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.current.number
}
