# =============================================================================
# Cloudflare Workers - Outputs
# =============================================================================

output "worker_name" {
  description = "Name of the Worker."
  value       = cloudflare_workers_script.this.script_name
}

output "url" {
  description = "Address of the Worker on its custom hostname. Null when there is none."
  value       = var.custom_hostname != "" ? "https://${var.custom_hostname}" : null
}

output "r2_bucket_name" {
  description = "Name of the R2 bucket bound as BUCKET."
  value       = cloudflare_r2_bucket.this.name
}

output "d1_database_id" {
  description = "ID of the D1 database bound as DB. Null when the data store is kv."
  value       = one(cloudflare_d1_database.this[*].id)
}

output "kv_namespace_id" {
  description = "ID of the KV namespace bound as KV. Null when the data store is d1."
  value       = one(cloudflare_workers_kv_namespace.this[*].id)
}

output "api_token" {
  description = "Bearer token the Worker requires on data requests."
  value       = random_password.api_token.result
  sensitive   = true
}
