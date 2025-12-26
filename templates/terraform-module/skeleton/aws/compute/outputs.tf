# -----------------------------------------------------------------------------
# AWS Compute Module - Outputs
# -----------------------------------------------------------------------------

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value       = aws_launch_template.main.latest_version
}

output "autoscaling_group_id" {
  description = "Auto Scaling Group ID"
  value       = aws_autoscaling_group.main.id
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.main.arn
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.compute.id
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.compute.arn
}

output "iam_role_name" {
  description = "IAM role name"
  value       = aws_iam_role.compute.name
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = aws_iam_instance_profile.compute.arn
}
