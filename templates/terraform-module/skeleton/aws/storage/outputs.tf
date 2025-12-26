# -----------------------------------------------------------------------------
# AWS Storage Module - Outputs
# -----------------------------------------------------------------------------

# S3 Outputs
output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.main.id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

# EFS Outputs
output "efs_id" {
  description = "EFS file system ID"
  value       = var.enable_efs ? aws_efs_file_system.main[0].id : null
}

output "efs_arn" {
  description = "EFS file system ARN"
  value       = var.enable_efs ? aws_efs_file_system.main[0].arn : null
}

output "efs_dns_name" {
  description = "EFS DNS name"
  value       = var.enable_efs ? aws_efs_file_system.main[0].dns_name : null
}

output "efs_mount_target_ids" {
  description = "EFS mount target IDs"
  value       = var.enable_efs ? aws_efs_mount_target.main[*].id : []
}

output "efs_access_point_id" {
  description = "EFS access point ID"
  value       = var.enable_efs ? aws_efs_access_point.main[0].id : null
}

output "efs_security_group_id" {
  description = "EFS security group ID"
  value       = var.enable_efs ? aws_security_group.efs[0].id : null
}
