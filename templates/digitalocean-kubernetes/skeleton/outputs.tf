# =============================================================================
# DigitalOcean Kubernetes - Outputs
# =============================================================================

output "cluster_id" {
  description = "ID of the cluster."
  value       = digitalocean_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = digitalocean_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  description = "Address of the Kubernetes API."
  value       = digitalocean_kubernetes_cluster.this.endpoint
}

output "kubernetes_version" {
  description = "Version the cluster runs."
  value       = digitalocean_kubernetes_cluster.this.version
}

output "vpc_id" {
  description = "ID of the VPC the cluster is in."
  value       = digitalocean_vpc.this.id
}

output "registry_endpoint" {
  description = "Endpoint of the created container registry. Null when none was created."
  value       = one(digitalocean_container_registry.this[*].endpoint)
}

output "kubeconfig_command" {
  description = "Command that adds the cluster to the local kubeconfig with short-lived credentials."
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.this.id}"
}
