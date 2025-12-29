output "secret_ids" {
  description = "Map of secret IDs to their full resource IDs"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.id
  }
}

output "secret_names" {
  description = "Map of secret IDs to their resource names"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.name
  }
}

output "secret_version_ids" {
  description = "Map of secret IDs to their latest version IDs"
  value = {
    for k, v in google_secret_manager_secret_version.versions : k => v.id
  }
}
