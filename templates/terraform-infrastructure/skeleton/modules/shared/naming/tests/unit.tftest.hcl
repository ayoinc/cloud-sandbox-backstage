# Unit tests for naming module
# Uses mock_provider - no credentials needed

variables {
  project     = "myproject"
  environment = "dev"
  component   = "storage"
}

run "azure_storage_naming" {
  command = plan
  
  variables {
    provider_type = "azure"
    resource_type = "storage"
  }
  
  assert {
    condition     = output.name == "myprojectdevstorage"
    error_message = "Azure storage name should remove hyphens and be lowercase"
  }
}

run "aws_s3_naming" {
  command = plan
  
  variables {
    provider_type = "aws"
    resource_type = "s3"
  }
  
  assert {
    condition     = output.name == "myproject-dev-storage"
    error_message = "AWS S3 name should use hyphens and be lowercase"
  }
}

run "gcp_storage_naming" {
  command = plan
  
  variables {
    provider_type = "gcp"
    resource_type = "storage"
  }
  
  assert {
    condition     = output.name == "myproject-dev-storage"
    error_message = "GCP storage name should use hyphens and be lowercase"
  }
}

run "generic_naming" {
  command = plan
  
  variables {
    provider_type = "generic"
  }
  
  assert {
    condition     = output.name == "myproject-dev-storage"
    error_message = "Generic name should use base naming convention"
  }
}

run "environment_validation" {
  command = plan
  
  variables {
    environment = "invalid"
  }
  
  expect_failures = [
    var.environment,
  ]
}