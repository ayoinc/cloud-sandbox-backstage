mock_provider "terraform" {}

run "naming_convention_test" {
  command = plan

  variables {
    project       = "testproject"
    environment   = "dev"
    component     = "storage"
    resource_type = "account"
    region        = "eastus"
    instance      = "001"
    provider      = "azure"
  }

  module {
    source = "./naming"
  }

  assert {
    condition     = module.naming.name == "testproject-dev-storage-account-eastus-001"
    error_message = "Naming convention does not match expected format"
  }

  assert {
    condition     = length(module.naming.name) <= 80
    error_message = "Name exceeds maximum length for Azure"
  }

  assert {
    condition     = can(regex("^[a-z0-9-]+$", module.naming.name))
    error_message = "Name contains invalid characters"
  }
}

run "aws_naming_test" {
  command = plan

  variables {
    project       = "myapp"
    environment   = "prod"
    component     = "compute"
    resource_type = "instance"
    region        = "us-west-2"
    instance      = "web-01"
    provider      = "aws"
  }

  module {
    source = "./naming"
  }

  assert {
    condition     = can(regex("^[a-z0-9-]+$", module.naming.name))
    error_message = "AWS name should be lowercase"
  }

  assert {
    condition     = length(module.naming.name) <= 63
    error_message = "AWS name should not exceed 63 characters"
  }
}

run "short_name_generation" {
  command = plan

  variables {
    project       = "verylongprojectnamethatexceedslimits"
    environment   = "production"
    component     = "complicatedcomponentname"
    resource_type = "resourcetypelengthy"
    provider      = "gcp"
  }

  module {
    source = "./naming"
  }

  assert {
    condition     = length(module.naming.short_name) <= 24
    error_message = "Short name should be limited to 24 characters"
  }
}

run "tagging_validation" {
  command = plan

  variables {
    project     = "test-project"
    environment = "staging"
    team        = "platform"
    cost_center = "engineering"
    additional_tags = {
      Application = "web"
      Owner       = "team@example.com"
    }
  }

  module {
    source = "./tagging"
  }

  assert {
    condition     = module.tagging.tags.Environment == "staging"
    error_message = "Environment tag should be set correctly"
  }

  assert {
    condition     = module.tagging.tags.Project == "test-project"
    error_message = "Project tag should be set correctly"
  }

  assert {
    condition     = lookup(module.tagging.tags, "Application", "") == "web"
    error_message = "Additional custom tags should be included"
  }

  assert {
    condition     = lookup(module.tagging.tags, "AutoShutdown", "false") == "true"
    error_message = "AutoShutdown should default to true for staging"
  }
}

run "validation_required_vars" {
  command = plan

  variables {
    required_variables = {
      project = {
        value       = "myproject"
        description = "Project name"
        pattern     = "^[a-z0-9-]+$"
      }
      environment = {
        value       = "prod"
        description = "Environment"
        pattern     = "^(dev|staging|prod)$"
      }
    }
    optional_variables = {
      region = {
        value       = ""
        description = "Region"
        pattern     = "^([a-z]+-[a-z0-9-]+)$"
      }
    }
  }

  module {
    source = "./validation"
  }

  assert {
    condition     = module.validation.is_valid == true
    error_message = "Validation should pass with correct values"
  }

  assert {
    condition     = length(module.validation.errors) == 0
    error_message = "No validation errors should be present"
  }
}

run "validation_failed_test" {
  command = plan

  variables {
    required_variables = {
      project = {
        value       = "Invalid_Project"
        description = "Project name"
        pattern     = "^[a-z0-9-]+$"
      }
    }
  }

  module {
    source = "./validation"
  }

  assert {
    condition     = module.validation.is_valid == false
    error_message = "Validation should fail with invalid values"
  }

  assert {
    condition     = length(module.validation.errors) > 0
    error_message = "Validation errors should be present"
  }
}

run "validation_empty_required" {
  command = plan

  variables {
    required_variables = {
      project = {
        value       = ""
        description = "Project name"
        pattern     = ""
      }
    }
  }

  module {
    source = "./validation"
  }

  assert {
    condition     = module.validation.is_valid == false
    error_message = "Validation should fail when required variable is empty"
  }
}