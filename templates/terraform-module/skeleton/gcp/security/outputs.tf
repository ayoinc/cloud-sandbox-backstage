output "kms_key_id" {
  description = "ID of the encryption key (projects/<project>/locations/<region>/keyRings/<ring>/cryptoKeys/<key>)."
  value       = google_kms_crypto_key.main.id

  # Buckets can only be encrypted once the storage service agent may use the key.
  depends_on = [google_kms_crypto_key_iam_member.storage_service_agent]
}

output "kms_key_name" {
  description = "Name of the encryption key."
  value       = google_kms_crypto_key.main.name
}

output "kms_key_ring_id" {
  description = "ID of the key ring."
  value       = google_kms_key_ring.main.id
}

output "kms_key_ring_name" {
  description = "Name of the key ring."
  value       = google_kms_key_ring.main.name
}

output "service_account_email" {
  description = "Email of the application service account."
  value       = google_service_account.application.email
}

output "service_account_id" {
  description = "Fully qualified ID of the application service account."
  value       = google_service_account.application.id
}

output "service_account_member" {
  description = "IAM member string of the application service account."
  value       = local.service_account_member
}

output "secret_ids" {
  description = "Secret Manager secret IDs keyed by the short names given in secret_names."
  value       = { for name, secret in google_secret_manager_secret.main : name => secret.secret_id }
}

output "org_policy_names" {
  description = "Names of the organization policies enforced on the project."
  value = concat(
    google_org_policy_policy.require_os_login[*].name,
    google_org_policy_policy.restrict_vm_external_ips[*].name,
    google_org_policy_policy.allowed_policy_member_domains[*].name,
  )
}
