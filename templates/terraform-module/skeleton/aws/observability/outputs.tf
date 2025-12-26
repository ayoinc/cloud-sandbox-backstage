# -----------------------------------------------------------------------------
# AWS Observability Module - Outputs
# -----------------------------------------------------------------------------

# Log Group Outputs
output "log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "Application log group ARN"
  value       = aws_cloudwatch_log_group.main.arn
}

output "system_log_group_name" {
  description = "System log group name"
  value       = aws_cloudwatch_log_group.system.name
}

output "security_log_group_name" {
  description = "Security log group name"
  value       = aws_cloudwatch_log_group.security.name
}

# Dashboard Outputs
output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.enable_dashboard ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : null
}

# Alarm Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.enable_alarms ? aws_sns_topic.alarms[0].arn : null
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs"
  value = var.enable_alarms ? {
    high_cpu        = aws_cloudwatch_metric_alarm.high_cpu[0].arn
    high_memory     = aws_cloudwatch_metric_alarm.high_memory[0].arn
    rds_high_cpu    = aws_cloudwatch_metric_alarm.rds_high_cpu[0].arn
    rds_low_storage = aws_cloudwatch_metric_alarm.rds_low_storage[0].arn
    error_logs      = aws_cloudwatch_metric_alarm.error_logs[0].arn
  } : {}
}
