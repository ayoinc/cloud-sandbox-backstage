# Cluster Outputs
{%- if values.cloudProvider == "aws" %}
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.fqdn
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.cluster_name}"
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.gcp_project_id}"
}
{%- endif %}

# Platform Component URLs
{%- if values.enableGitOps %}
output "argocd_url" {
  description = "ArgoCD URL"
  value       = "Access ArgoCD at the ingress URL or via port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}
{%- endif %}

{%- if values.enableObservability %}
output "grafana_url" {
  description = "Grafana URL"
  value       = "Access Grafana at the ingress URL or via port-forward: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "Access Prometheus via port-forward: kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090"
}
{%- endif %}

{%- if values.enableServiceMesh %}
output "istio_ingress_ip" {
  description = "Istio Ingress Gateway IP"
  value       = "kubectl get svc istio-ingress -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
{%- endif %}
