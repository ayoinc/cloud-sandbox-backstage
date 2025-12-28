# =============================================================================
# TERRAFORM TESTS
# =============================================================================
# Native Terraform tests for the Azure Full Infrastructure Stack
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Resource Group Module
# -----------------------------------------------------------------------------
run "test_resource_group_naming" {
  command = plan

  variables {
    azure_location     = "eastus"
    enable_networking  = false
    enable_compute     = false
    enable_containers  = false
    enable_storage     = false
    enable_database    = false
    enable_security    = false
    enable_identity    = false
    enable_monitoring  = false
    enable_integration = false
    enable_governance  = false
  }

  assert {
    condition     = can(regex("^rg-", module.resource_group_primary.name))
    error_message = "Resource group name should start with 'rg-' prefix"
  }
}

# -----------------------------------------------------------------------------
# Test: Networking Module (when enabled)
# -----------------------------------------------------------------------------
run "test_networking_enabled" {
  command = plan

  variables {
    azure_location     = "eastus"
    enable_networking  = true
    enable_security    = false
    enable_storage     = false
    enable_monitoring  = false
    enable_compute     = false
    enable_containers  = false
    enable_database    = false
    enable_identity    = false
    enable_integration = false
    enable_governance  = false
  }

  assert {
    condition     = length(module.resource_group_network) == 1
    error_message = "Network resource group should be created when networking is enabled"
  }

  assert {
    condition     = length(module.networking) == 1
    error_message = "Networking module should be created when networking is enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Security Module (when enabled)
# -----------------------------------------------------------------------------
run "test_security_enabled" {
  command = plan

  variables {
    azure_location     = "eastus"
    enable_networking  = false
    enable_security    = true
    enable_storage     = false
    enable_monitoring  = false
    enable_compute     = false
    enable_containers  = false
    enable_database    = false
    enable_identity    = false
    enable_integration = false
    enable_governance  = false
  }

  assert {
    condition     = length(module.resource_group_security) == 1
    error_message = "Security resource group should be created when security is enabled"
  }

  assert {
    condition     = length(module.security) == 1
    error_message = "Security module should be created when security is enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: All Modules Disabled
# -----------------------------------------------------------------------------
run "test_minimal_deployment" {
  command = plan

  variables {
    azure_location     = "eastus"
    enable_networking  = false
    enable_compute     = false
    enable_containers  = false
    enable_storage     = false
    enable_database    = false
    enable_security    = false
    enable_identity    = false
    enable_monitoring  = false
    enable_integration = false
    enable_governance  = false
  }

  # Primary resource group should always be created
  assert {
    condition     = module.resource_group_primary.name != ""
    error_message = "Primary resource group should always be created"
  }

  # Optional modules should not be created
  assert {
    condition     = length(module.networking) == 0
    error_message = "Networking module should not be created when disabled"
  }

  assert {
    condition     = length(module.security) == 0
    error_message = "Security module should not be created when disabled"
  }

  assert {
    condition     = length(module.storage) == 0
    error_message = "Storage module should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Tags are Applied
# -----------------------------------------------------------------------------
run "test_tags_applied" {
  command = plan

  variables {
    azure_location     = "eastus"
    enable_networking  = false
    enable_security    = false
    enable_storage     = false
    enable_monitoring  = false
    enable_compute     = false
    enable_containers  = false
    enable_database    = false
    enable_identity    = false
    enable_integration = false
    enable_governance  = false
  }

  assert {
    condition     = contains(keys(module.resource_group_primary.tags), "ManagedBy")
    error_message = "Resources should have ManagedBy tag"
  }

  assert {
    condition     = module.resource_group_primary.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be 'terraform'"
  }
}
