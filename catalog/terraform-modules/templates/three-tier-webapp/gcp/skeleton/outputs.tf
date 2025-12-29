# Network Outputs
output "network_id" {
  description = "ID of the VPC network"
  value       = module.vpc.network_id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = module.vpc.subnet_ids
}

# Load Balancer Outputs
output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = module.load_balancer.external_ip
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "https://${module.load_balancer.external_ip}"
}

{%- if values.computeType == "gke-autopilot" or values.computeType == "gke-standard" %}
# GKE Outputs
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.gcp_project_id}"
}
{%- endif %}

{%- if values.computeType == "mig" %}
# MIG Outputs
output "instance_group" {
  description = "URL of the managed instance group"
  value       = module.mig.instance_group
}
{%- endif %}

# Database Outputs
output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloud_sql.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the database"
  value       = module.cloud_sql.private_ip_address
}

output "database_name" {
  description = "Name of the database"
  value       = module.cloud_sql.database_name
}

{%- if values.enableCloudArmor %}
# Cloud Armor Outputs
output "cloud_armor_policy_id" {
  description = "Cloud Armor security policy ID"
  value       = module.cloud_armor.policy_id
}
{%- endif %}
