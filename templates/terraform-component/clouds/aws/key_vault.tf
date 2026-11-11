# -----------------------------------------------------------------------------
# Key management: KMS key for the data of this component
# -----------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  description             = "Key of the ${var.component_name} component"
  enable_key_rotation     = true
  deletion_window_in_days = var.environment == "production" ? 30 : 7
}

resource "aws_kms_alias" "this" {
  name          = "alias/${module.naming.standard["kms"]}"
  target_key_id = aws_kms_key.this.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key."
  value       = aws_kms_key.this.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key."
  value       = aws_kms_alias.this.name
}
