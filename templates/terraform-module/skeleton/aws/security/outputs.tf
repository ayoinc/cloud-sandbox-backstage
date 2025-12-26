# -----------------------------------------------------------------------------
# AWS Security Module - Outputs
# -----------------------------------------------------------------------------

# KMS Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_alias_arn" {
  description = "KMS alias ARN"
  value       = aws_kms_alias.main.arn
}

# IAM Outputs
output "application_role_arn" {
  description = "Application IAM role ARN"
  value       = aws_iam_role.application.arn
}

output "application_role_name" {
  description = "Application IAM role name"
  value       = aws_iam_role.application.name
}

# Secrets Outputs
output "app_secrets_arn" {
  description = "Application secrets ARN"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "app_secrets_name" {
  description = "Application secrets name"
  value       = aws_secretsmanager_secret.app_secrets.name
}

# Security Group Outputs
output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = var.enable_bastion_sg ? aws_security_group.bastion[0].id : null
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : null
}
