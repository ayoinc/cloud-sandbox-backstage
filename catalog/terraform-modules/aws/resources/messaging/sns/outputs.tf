output "topic_id" {
  description = "The ID of the SNS topic"
  value       = aws_sns_topic.this.id
}

output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.this.name
}

output "subscription_arns" {
  description = "Map of subscription ARNs"
  value       = { for k, v in aws_sns_topic_subscription.this : k => v.arn }
}
