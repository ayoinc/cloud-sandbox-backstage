{%- if values.cloud == 'aws' -%}
output "account_id" {
  description = "AWS account the stack is deployed to, taken from the ARN of the VPC."
  value       = provider::aws::arn_parse(aws_vpc.main.arn).account_id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, by availability zone."
  value       = { for zone, subnet in aws_subnet.private : zone => subnet.id }
}

output "log_bucket" {
  description = "Name of the log bucket."
  value       = aws_s3_bucket.logs.bucket
}

output "log_key_arn" {
  description = "ARN of the KMS key that encrypts the log bucket."
  value       = aws_kms_key.logs.arn
}
{%- elif values.cloud == 'azure' -%}
output "subscription_id" {
  description = "Subscription the stack is deployed to, taken from the ID of the resource group."
  value       = provider::azurerm::parse_resource_id(azurerm_resource_group.main.id).subscription_id
}

output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.main.id
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = azurerm_subnet.private.id
}

output "log_storage_account" {
  description = "Name of the log storage account."
  value       = azurerm_storage_account.logs.name
}
{%- else -%}
output "project_id" {
  description = "Project the stack is deployed to, taken from the ID of the network."
  value       = provider::google::project_from_id(google_compute_network.main.id)
}

output "network_name" {
  description = "Name of the VPC network."
  value       = provider::google::name_from_id(google_compute_network.main.id)
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = google_compute_subnetwork.private.id
}

output "log_bucket" {
  description = "Name of the log bucket."
  value       = google_storage_bucket.logs.name
}

output "log_key_id" {
  description = "ID of the Cloud KMS key that encrypts the log bucket."
  value       = google_kms_crypto_key.logs.id
}
{%- endif %}
