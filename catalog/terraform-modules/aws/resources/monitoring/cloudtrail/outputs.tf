output "trail_id" {
  description = "The ID of the CloudTrail trail"
  value       = aws_cloudtrail.this.id
}

output "trail_arn" {
  description = "The ARN of the CloudTrail trail"
  value       = aws_cloudtrail.this.arn
}

output "trail_home_region" {
  description = "The home region of the CloudTrail trail"
  value       = aws_cloudtrail.this.home_region
}

output "trail_status" {
  description = "Whether logging is enabled for the trail"
  value       = aws_cloudtrail.this.enable_logging
}
