output "store_url" {
  description = "Address of the store."
  value       = var.enable_cdn ? "http://${google_compute_global_address.frontend[0].address}" : google_cloud_run_v2_service.frontend.uri
}

output "frontend_url" {
  description = "Address of the storefront service on Cloud Run."
  value       = google_cloud_run_v2_service.frontend.uri
}

output "api_url" {
  description = "Address of the API service on Cloud Run."
  value       = google_cloud_run_v2_service.backend.uri
}

output "database_connection_name" {
  description = "Connection name of the Cloud SQL instance."
  value       = google_sql_database_instance.main.connection_name
}

output "admin_token" {
  description = "Bearer token of the admin API."
  value       = random_password.admin_token.result
  sensitive   = true
}
