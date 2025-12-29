# Terraform native tests for AWS S3 module

variables {
  project_name      = "test-project"
  environment       = "test"
  bucket_name       = "test-bucket-unique-12345"
  enable_versioning = true
  enable_encryption = true

  tags = {
    Test = "true"
  }
}

run "bucket_creation" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.bucket == "test-bucket-unique-12345"
    error_message = "Bucket name should match input"
  }
}

run "versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.main[0].versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled"
  }
}

run "encryption_enabled" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.main) > 0
    error_message = "Server-side encryption should be configured"
  }
}

run "public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true
    error_message = "Public ACLs should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_policy == true
    error_message = "Public policy should be blocked"
  }
}
