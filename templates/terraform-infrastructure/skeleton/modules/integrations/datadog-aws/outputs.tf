output "integration_id" {
  description = "ID of the AWS account integration in Datadog."
  value       = datadog_integration_aws_account.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role Datadog assumes."
  value       = aws_iam_role.datadog.arn
}

output "iam_role_name" {
  description = "Name of the IAM role Datadog assumes."
  value       = aws_iam_role.datadog.name
}

output "iam_policy_arns" {
  description = "ARNs of the managed policies that carry the read-only actions of the integration."
  value       = aws_iam_policy.datadog[*].arn
}
