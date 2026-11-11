# A configuration that passes the TFLint configuration and the custom Checkov
# checks of this repository.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  description = "Environment the bucket belongs to."
  type        = string
}

resource "aws_s3_bucket" "logs" {
  bucket = "sample-${var.environment}-logs"

  tags = {
    owner       = "platform-team"
    environment = var.environment
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

output "bucket_name" {
  description = "Name of the log bucket."
  value       = aws_s3_bucket.logs.bucket
}
