output "load_balancer_ip" {
  description = "Public address of the load balancer"
  value       = google_compute_global_address.load_balancer.address
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "app_service_account_email" {
  description = "Service account the application runs as"
  value       = module.app_service_account.service_account_email
}

output "gke_cluster_name" {
  description = "GKE cluster, for the GKE compute types"
  value       = one(concat(google_container_cluster.autopilot[*].name, google_container_cluster.standard[*].name))
}

output "gke_neg_name" {
  description = "Name to give the network endpoint group of the application's Kubernetes Service, for the GKE compute types"
  value       = local.runs_gke ? local.gke_neg_name : null
}

output "instance_group" {
  description = "Managed instance group, for the mig compute type"
  value       = one(google_compute_region_instance_group_manager.app[*].instance_group)
}

output "database_connection_name" {
  description = "Connection name of the Cloud SQL instance, as used by the Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip" {
  description = "Private address of the database"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the application's database"
  value       = google_sql_database.app.name
}

output "database_username" {
  description = "Database user the application connects as"
  value       = google_sql_user.app.name
}

output "database_password_secret_id" {
  description = "Secret Manager secret that holds the database user's password"
  value       = module.database_password.secret_ids[local.database_password_secret_id]
}

output "security_policy_name" {
  description = "Cloud Armor security policy, when Cloud Armor is enabled"
  value       = one(google_compute_security_policy.edge[*].name)
}
