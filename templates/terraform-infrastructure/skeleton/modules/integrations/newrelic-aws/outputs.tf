output "linked_account_id" {
  description = "ID of the linked AWS account in New Relic."
  value       = newrelic_cloud_aws_link_account.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role New Relic assumes."
  value       = aws_iam_role.newrelic.arn
}

output "iam_role_name" {
  description = "Name of the IAM role New Relic assumes."
  value       = aws_iam_role.newrelic.name
}
