output "deployment_id" {
  description = "ID of the Elastic Cloud deployment."
  value       = ec_deployment.this.id
}

output "elastic_region" {
  description = "Elastic Cloud region the deployment runs in."
  value       = local.elastic_region
}

output "elasticsearch_endpoint" {
  description = "HTTPS endpoint of Elasticsearch."
  value       = ec_deployment.this.elasticsearch.https_endpoint
}

output "kibana_endpoint" {
  description = "HTTPS endpoint of Kibana."
  value       = ec_deployment.this.kibana.https_endpoint
}

output "cloud_id" {
  description = "Cloud ID that Elastic Agent, Beats and Logstash use to find the deployment."
  value       = ec_deployment.this.elasticsearch.cloud_id
}

output "elasticsearch_username" {
  description = "Name of the built-in superuser created with the deployment."
  value       = ec_deployment.this.elasticsearch_username
}

output "elasticsearch_password" {
  description = "Password of the built-in superuser. Use it to create API keys for the shippers, not in the shippers themselves."
  value       = ec_deployment.this.elasticsearch_password
  sensitive   = true
}
