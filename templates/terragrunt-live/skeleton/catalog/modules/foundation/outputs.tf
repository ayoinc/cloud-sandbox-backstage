{%- if values.cloud == 'aws' -%}
output "kms_key_arn" {
  description = "ARN of the key."
  value       = aws_kms_key.main.arn
}

output "kms_key_alias" {
  description = "Alias of the key."
  value       = aws_kms_alias.main.name
}
{%- elif values.cloud == 'azure' -%}
output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group."
  value       = azurerm_resource_group.main.id
}
{%- else -%}
output "kms_key_id" {
  description = "ID of the key. It is published once Cloud Storage may use the key."
  value       = google_kms_crypto_key.logs.id

  depends_on = [google_kms_crypto_key_iam_member.storage]
}
{%- endif %}
