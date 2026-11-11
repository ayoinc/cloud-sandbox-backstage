output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "cluster_location" {
  description = "Region of the GKE cluster"
  value       = google_container_cluster.this.location
}

output "cluster_endpoint" {
  description = "DNS-based endpoint of the Kubernetes API"
  value       = local.cluster_host
}

output "cluster_version" {
  description = "Kubernetes version the control plane runs"
  value       = google_container_cluster.this.master_version
}

output "get_credentials_command" {
  description = "Command that adds the cluster to the local kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --location ${var.region} --project ${var.gcp_project_id} --dns-endpoint"
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "subnet_id" {
  description = "ID of the cluster subnet"
  value       = module.vpc.subnet_ids["gke"]
}

output "node_machine_type" {
  description = "Machine type of the nodes"
  value       = local.node_machine_types[var.node_size]
}

output "node_service_account_email" {
  description = "Service account the nodes run as"
  value       = module.node_identity.service_account_email
}

output "workload_identity_pool" {
  description = "Workload identity pool of the cluster, used in IAM members of Kubernetes service accounts"
  value       = local.workload_identity_pool
}

output "external_dns_service_account_email" {
  description = "Google service account of external-dns, when enable_external_dns is true"
  value       = one(module.external_dns_identity[*].service_account_email)
}

output "storage_class" {
  description = "Name of the StorageClass the platform components use"
  value       = local.cloud.storage_class
}
