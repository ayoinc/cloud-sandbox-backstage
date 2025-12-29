output "event_bus_name" {
  description = "Name of the EventBridge event bus"
  value       = local.event_bus_name
}

output "event_bus_arn" {
  description = "ARN of the EventBridge event bus"
  value       = local.event_bus_arn
}

output "rule_arns" {
  description = "Map of rule names to their ARNs"
  value = {
    for name, rule in aws_cloudwatch_event_rule.this : name => rule.arn
  }
}

output "archive_arn" {
  description = "ARN of the event archive (null if archiving is disabled)"
  value       = var.enable_archive && var.event_bus_name != null ? aws_cloudwatch_event_archive.this[0].arn : null
}
