# =============================================================================
# SHARED MODULES - NATIVE TERRAFORM TESTS
# =============================================================================
# Uses terraform test with mock_provider for credential-less testing
# Run with: terraform test -verbose
# =============================================================================

# -----------------------------------------------------------------------------
# NAMING MODULE TESTS
# -----------------------------------------------------------------------------

# Test Azure naming convention
run "test_azure_naming" {
  command = plan

  variables {
    cloud_provider = "azure"
    project        = "myapp"
    environment    = "prod"
    component      = "api"
    resource_type  = "virtual_network"
    region         = "eastus"
    instance       = 1
  }

  module {
    source = "./../naming"
  }

  assert {
    condition     = output.prefix == "vnet"
    error_message = "Azure VNet prefix should be 'vnet'"
  }

  assert {
    condition     = output.environment_short == "p"
    error_message = "Prod environment should abbreviate to 'p'"
  }

  assert {
    condition     = output.region_short == "eus"
    error_message = "eastus should abbreviate to 'eus'"
  }

  assert {
    condition     = can(regex("^vnet-myapp-api-p-eus", output.name))
    error_message = "Name should follow Azure CAF naming pattern"
  }
}

# Test AWS naming convention
run "test_aws_naming" {
  command = plan

  variables {
    cloud_provider = "aws"
    project        = "webapp"
    environment    = "dev"
    component      = "backend"
    resource_type  = "vpc"
    region         = "us-east-1"
    instance       = 1
  }

  module {
    source = "./../naming"
  }

  assert {
    condition     = output.prefix == "vpc"
    error_message = "AWS VPC prefix should be 'vpc'"
  }

  assert {
    condition     = output.environment_short == "d"
    error_message = "Dev environment should abbreviate to 'd'"
  }

  assert {
    condition     = can(regex("^vpc-webapp-backend-d-", output.name))
    error_message = "Name should follow AWS naming pattern"
  }
}

# Test GCP naming convention
run "test_gcp_naming" {
  command = plan

  variables {
    cloud_provider = "gcp"
    project        = "dataplatform"
    environment    = "staging"
    component      = "etl"
    resource_type  = "gke_cluster"
    region         = "us-central1"
    instance       = 2
  }

  module {
    source = "./../naming"
  }

  assert {
    condition     = output.prefix == "gke"
    error_message = "GCP GKE prefix should be 'gke'"
  }

  assert {
    condition     = output.environment_short == "s"
    error_message = "Staging environment should abbreviate to 's'"
  }

  assert {
    condition     = can(regex("-02$", output.name))
    error_message = "Instance 2 should have '-02' suffix"
  }
}

# Test name without hyphens (for storage accounts)
run "test_name_no_hyphens" {
  command = plan

  variables {
    cloud_provider = "azure"
    project        = "myapp"
    environment    = "prod"
    component      = "data"
    resource_type  = "storage_account"
    region         = "westeurope"
  }

  module {
    source = "./../naming"
  }

  assert {
    condition     = !can(regex("-", output.name_no_hyphens))
    error_message = "name_no_hyphens should not contain hyphens"
  }

  assert {
    condition     = length(output.name_no_hyphens) <= 24
    error_message = "Azure storage account name should be max 24 chars"
  }
}

# Test unique name generation
run "test_unique_name" {
  command = plan

  variables {
    cloud_provider = "azure"
    project        = "test"
    environment    = "dev"
    resource_type  = "key_vault"
    region         = "uksouth"
  }

  module {
    source = "./../naming"
  }

  assert {
    condition     = length(output.unique_name) > length(output.name)
    error_message = "Unique name should include hash suffix"
  }

  assert {
    condition     = can(regex("-[a-f0-9]{6}$", output.unique_name))
    error_message = "Unique name should end with 6-char hash"
  }
}

# -----------------------------------------------------------------------------
# TAGGING MODULE TESTS
# -----------------------------------------------------------------------------

# Test production environment tagging
run "test_production_tags" {
  command = plan

  variables {
    project             = "myapp"
    environment         = "prod"
    layer               = "application"
    owner               = "platform-team"
    cost_center         = "cc-12345"
    data_classification = "confidential"
    auto_shutdown       = true
  }

  module {
    source = "./../tagging"
  }

  assert {
    condition     = output.is_production == true
    error_message = "Should identify as production environment"
  }

  assert {
    condition     = output.auto_shutdown_enabled == false
    error_message = "Auto-shutdown should be disabled for production"
  }

  assert {
    condition     = output.tags["Environment"] == "prod"
    error_message = "Environment tag should be 'prod'"
  }

  assert {
    condition     = output.tags["DataClassification"] == "confidential"
    error_message = "Data classification should be 'confidential'"
  }
}

# Test non-production environment tagging
run "test_dev_tags" {
  command = plan

  variables {
    project       = "testapp"
    environment   = "dev"
    layer         = "application"
    auto_shutdown = true
  }

  module {
    source = "./../tagging"
  }

  assert {
    condition     = output.is_production == false
    error_message = "Should not identify as production"
  }

  assert {
    condition     = output.auto_shutdown_enabled == true
    error_message = "Auto-shutdown should be enabled for dev"
  }

  assert {
    condition     = can(output.tags["ShutdownSchedule"])
    error_message = "Should have shutdown schedule tag"
  }
}

# Test GCP labels format
# run "test_gcp_labels" {
#   command = plan
# 
#   module {
#     source = "./../tagging"
# 
#     cloud_provider = "gcp"
#     project        = "MyProject"
#     environment    = "staging"
#   }
# 
#   # GCP labels must be lowercase
#   assert {
#     condition     = output.gcp_labels["project"] == "myproject"
#     error_message = "GCP labels should be lowercase"
#   }
# 
#   assert {
#     condition     = output.gcp_labels["environment"] == "staging"
#     error_message = "GCP environment label should exist"
#   }

# Test additional tags merge
run "test_additional_tags" {
  command = plan

  variables {
    project     = "app"
    environment = "dev"
    layer       = "application"
    additional_tags = {
      CustomTag = "custom-value"
      Team      = "devops"
    }
  }

  module {
    source = "./../tagging"
  }

  assert {
    condition     = output.tags["CustomTag"] == "custom-value"
    error_message = "Additional tags should be merged"
  }

  assert {
    condition     = output.tags["Team"] == "devops"
    error_message = "Team tag should be present"
  }
}

# Test compliance tagging
run "test_compliance_tags" {
  command = plan

  variables {
    project             = "financeapp"
    environment         = "prod"
    layer               = "data"
    compliance          = ["pci", "sox", "gdpr"]
    data_classification = "restricted"
  }

  module {
    source = "./../tagging"
  }

  assert {
    condition     = can(regex("pci", output.tags["Compliance"]))
    error_message = "Compliance tag should include 'pci'"
  }

  assert {
    condition     = output.tags["DataClassification"] == "restricted"
    error_message = "Data classification should be 'restricted'"
  }
}

# -----------------------------------------------------------------------------
# VALIDATION MODULE TESTS
# -----------------------------------------------------------------------------

# Test required variables validation
run "test_required_validation_pass" {
  command = plan

  variables {
    required_variables = {
      project     = "myapp"
      environment = "prod"
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "Validation should pass with all required variables"
  }

  assert {
    condition     = output.error_count == 0
    error_message = "Should have no errors"
  }
}

# Test required variables validation failure
run "test_required_validation_fail" {
  command = plan

  variables {
    required_variables = {
      project     = "myapp"
      environment = ""
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == false
    error_message = "Validation should fail with empty required variable"
  }

  assert {
    condition     = output.error_count > 0
    error_message = "Should have validation errors"
  }
}

# Test pattern validation
run "test_pattern_validation" {
  command = plan

  variables {
    patterns = {
      project_name = {
        value   = "my-valid-project"
        pattern = "^[a-z][a-z0-9-]*$"
        message = "must be lowercase with hyphens"
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "Pattern validation should pass for valid input"
  }
}

# Test pattern validation failure
run "test_pattern_validation_fail" {
  command = plan

  variables {
    patterns = {
      project_name = {
        value   = "Invalid_Project!"
        pattern = "^[a-z][a-z0-9-]*$"
        message = "must be lowercase with hyphens"
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == false
    error_message = "Pattern validation should fail for invalid input"
  }

  assert {
    condition     = length(output.errors) > 0
    error_message = "Should have pattern errors"
  }
}

# Test range validation
run "test_range_validation" {
  command = plan

  variables {
    ranges = {
      instance_count = {
        value = 5
        min   = 1
        max   = 10
      }
      cpu_cores = {
        value = 4
        min   = 2
        max   = 16
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "Range validation should pass for values within range"
  }
}

# Test range validation failure
run "test_range_validation_fail" {
  command = plan

  variables {
    ranges = {
      instance_count = {
        value = 100
        min   = 1
        max   = 10
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == false
    error_message = "Range validation should fail for out-of-range values"
  }
}

# Test enum validation
run "test_enum_validation" {
  command = plan

  variables {
    enums = {
      environment = {
        value   = "prod"
        allowed = ["dev", "staging", "prod"]
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "Enum validation should pass for allowed value"
  }
}

# Test enum validation failure
run "test_enum_validation_fail" {
  command = plan

  variables {
    enums = {
      environment = {
        value   = "production"
        allowed = ["dev", "staging", "prod"]
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == false
    error_message = "Enum validation should fail for disallowed value"
  }
}

# Test length validation
run "test_length_validation" {
  command = plan

  variables {
    lengths = {
      storage_account = {
        value = "mystorageaccount"
        min   = 3
        max   = 24
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "Length validation should pass for valid length"
  }
}

# Test optional variables resolution
run "test_optional_resolution" {
  command = plan

  variables {
    optional_variables = {
      region = {
        value   = ""
        default = "eastus"
      }
      tier = {
        value   = "premium"
        default = "standard"
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.resolved_optionals["region"] == "eastus"
    error_message = "Empty optional should resolve to default"
  }

  assert {
    condition     = output.resolved_optionals["tier"] == "premium"
    error_message = "Set optional should use provided value"
  }
}

# Test combined validations
run "test_combined_validations" {
  command = plan

  variables {
    required_variables = {
      project = "myapp"
    }
    patterns = {
      project = {
        value   = "myapp"
        pattern = "^[a-z]+$"
        message = "lowercase only"
      }
    }
    ranges = {
      count = {
        value = 3
        min   = 1
        max   = 5
      }
    }
    enums = {
      env = {
        value   = "dev"
        allowed = ["dev", "prod"]
      }
    }
    fail_on_error = false
  }

  module {
    source = "./../validation"
  }

  assert {
    condition     = output.valid == true
    error_message = "All combined validations should pass"
  }

  assert {
    condition     = output.validation_report.total_errors == 0
    error_message = "Validation report should show no errors"
  }
}
