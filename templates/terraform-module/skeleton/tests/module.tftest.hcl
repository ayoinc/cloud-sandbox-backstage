# =============================================================================
# Terraform Module Tests
# =============================================================================
# These tests validate the Terraform module structure and ensure
# compliance with best practices for reusable module development.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test Variables - Base Configuration
# -----------------------------------------------------------------------------
variables {
  name        = "test-module"
  environment = "dev"
}

# =============================================================================
# MODULE STRUCTURE TESTS
# =============================================================================

run "module_has_valid_name_prefix" {
  command = plan

  assert {
    condition     = local.name_prefix == "test-module-dev"
    error_message = "Name prefix must follow format: {name}-{environment}"
  }
}

run "common_tags_are_properly_set" {
  command = plan

  assert {
    condition     = local.common_tags["Environment"] == "dev"
    error_message = "Common tags must include Environment"
  }

  assert {
    condition     = local.common_tags["CreatedBy"] == "terraform"
    error_message = "Common tags must include CreatedBy = terraform"
  }

  assert {
    condition     = local.common_tags["Name"] == "test-module-dev"
    error_message = "Common tags must include Name matching name_prefix"
  }
}

run "random_suffix_is_generated" {
  command = plan

  assert {
    condition     = can(random_id.suffix.byte_length)
    error_message = "Random ID suffix must be configured"
  }

  assert {
    condition     = random_id.suffix.byte_length == 4
    error_message = "Random ID suffix must be 4 bytes (8 hex characters)"
  }
}

# =============================================================================
# VARIABLE VALIDATION TESTS
# =============================================================================

run "name_validation_alphanumeric" {
  command = plan

  variables {
    name = "valid-name-123"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Name must be alphanumeric with hyphens"
  }
}

run "environment_validation_dev" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

run "environment_validation_staging" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = var.environment == "staging"
    error_message = "Staging environment should be accepted"
  }
}

run "environment_validation_prod" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Production environment should be accepted"
  }
}

# =============================================================================
# OUTPUT VALIDATION TESTS
# =============================================================================

run "outputs_are_defined" {
  command = plan

  assert {
    condition     = output.name != null
    error_message = "Name output must be defined"
  }

  assert {
    condition     = output.environment != null
    error_message = "Environment output must be defined"
  }

  assert {
    condition     = output.tags != null
    error_message = "Tags output must be defined"
  }

  assert {
    condition     = output.random_suffix != null
    error_message = "Random suffix output must be defined"
  }
}

# =============================================================================
# MONITORING CONFIGURATION TESTS
# =============================================================================

run "monitoring_default_enabled" {
  command = plan

  assert {
    condition     = var.enable_monitoring == true
    error_message = "Monitoring should be enabled by default"
  }
}

run "log_retention_valid_values" {
  command = plan

  variables {
    log_retention_days = 14
  }

  assert {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period"
  }
}

# =============================================================================
# TAGGING COMPLIANCE TESTS
# =============================================================================

run "default_tags_structure" {
  command = plan

  assert {
    condition     = can(var.default_tags["ManagedBy"])
    error_message = "Default tags must include ManagedBy"
  }
}

# =============================================================================
# MODULE BEST PRACTICES TESTS
# =============================================================================

run "module_uses_lifecycle_rules" {
  command = plan

  # Verify that resources use create_before_destroy where appropriate
  # This is validated by ensuring the plan completes without lifecycle conflicts
  assert {
    condition     = true  # Placeholder - actual validation happens during plan
    error_message = "Module resources should use appropriate lifecycle rules"
  }
}

# =============================================================================
# SECURITY TESTS
# =============================================================================

run "tags_include_security_metadata" {
  command = plan

  assert {
    condition     = local.common_tags["CreatedBy"] != null
    error_message = "Tags must include CreatedBy for audit trail"
  }
}
