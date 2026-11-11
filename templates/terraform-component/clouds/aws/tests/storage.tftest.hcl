# Plan-only tests against mocked providers: no credentials, no resources.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

mock_provider "aws" {
  alias = "secondary"
}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "ab12cd34"
    }
  }
}

# Every variable is set here so that the tests do not depend on terraform.tfvars.
variables {
  component_name            = "test-component"
  component_type            = "application"
  project_name              = "billing"
  environment               = "development"
  business_unit             = "engineering"
  cost_center               = "application-development"
  application_id            = ""
  owner                     = "group:default/platform-team"
  company                   = "example-org"
  naming_convention         = "enterprise"
  region                    = "us-east-1"
  secondary_region          = null
  create_resource_container = true
}

run "bucket_is_private_and_encrypted" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls && aws_s3_bucket_public_access_block.this.restrict_public_buckets
    error_message = "The bucket must block public access."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "The bucket must be versioned."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "The bucket must be encrypted with a KMS key."
  }

  assert {
    condition     = length(aws_s3_bucket.replica) == 0 && length(aws_s3_bucket_replication_configuration.this) == 0
    error_message = "No replica without a secondary region."
  }
}

run "secondary_region_adds_a_replica" {
  command = plan

  variables {
    secondary_region = "us-west-2"
  }

  assert {
    condition     = length(aws_s3_bucket.replica) == 1 && length(aws_s3_bucket_replication_configuration.this) == 1
    error_message = "A secondary region must add a replica bucket and replication."
  }

  assert {
    condition     = aws_s3_bucket_versioning.replica[0].versioning_configuration[0].status == "Enabled"
    error_message = "The replica bucket must be versioned."
  }
}
