output "security_policy_id" {
  description = "The unique identifier of the security policy"
  value       = google_compute_security_policy.policy.id
}

output "security_policy_self_link" {
  description = "The URI of the security policy"
  value       = google_compute_security_policy.policy.self_link
}

output "security_policy_fingerprint" {
  description = "Fingerprint of the security policy"
  value       = google_compute_security_policy.policy.fingerprint
}
