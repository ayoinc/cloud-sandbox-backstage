# -----------------------------------------------------------------------------
# Log workspace: CloudWatch log group
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days log events are kept."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period CloudWatch Logs supports, for example 7, 30, 90 or 365."
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.project_name}/${var.environment}/${var.component_name}"
  retention_in_days = var.log_retention_days
}

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}
