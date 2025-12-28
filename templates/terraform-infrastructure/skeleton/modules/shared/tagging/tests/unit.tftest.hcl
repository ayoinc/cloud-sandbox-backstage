# Unit tests for tagging module
# Uses mock_provider - no credentials needed

variables {
  project     = "myproject"
  environment = "dev"
  component   = "storage"
}

run "dev_environment_tags" {
  command = plan
  
  assert {
    condition     = output.tags["Environment"] == "dev"
    error_message = "Environment tag should be set to dev"
  }
  
  assert {
    condition     = output.tags["AutoShutdown"] == "true"
    error_message = "AutoShutdown should be true for dev environment"
  }
  
  assert {
    condition     = output.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be terraform"
  }
  
  assert {
    condition     = output.tags["Component"] == "storage"
    error_message = "Component tag should be set when component is specified"
  }
}

run "prod_environment_tags" {
  command = plan
  
  variables {
    environment = "prod"
  }
  
  assert {
    condition     = output.tags["BackupEnabled"] == "true"
    error_message = "BackupEnabled should be true for prod environment"
  }
  
  assert {
    condition     = output.tags["CostCenter"] == "production"
    error_message = "CostCenter should be production for prod environment"
  }
}

run "extra_tags_merge" {
  command = plan
  
  variables {
    extra_tags = {
      Owner = "platform-team"
      Tier  = "standard"
    }
  }
  
  assert {
    condition     = output.tags["Owner"] == "platform-team"
    error_message = "Extra tags should be merged with standard tags"
  }
  
  assert {
    condition     = output.tags["Tier"] == "standard"
    error_message = "All extra tags should be included"
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