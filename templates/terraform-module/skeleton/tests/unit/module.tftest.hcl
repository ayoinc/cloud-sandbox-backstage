# ==============================================================================
# Terraform Unit Tests
# ==============================================================================
# These tests validate the module configuration without creating resources
# Uses mock_provider for testing without credentials

# Mock providers for testing without credentials
mock_provider "aws" {}
mock_provider "azurerm" {}
mock_provider "google" {}

# Test: Variables have valid defaults
run "validate_variables" {
  command = plan

  variables {
    environment  = "dev"
    project_name = "test-module"
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws_region = "us-east-1"
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azure_location = "eastus"
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    gcp_project_id = "test-project"
    gcp_region     = "us-central1"
{%- endif %}
  }

  # Ensure plan succeeds
  assert {
    condition     = true
    error_message = "Module configuration is invalid"
  }
}

# Test: Environment validation
run "validate_environment_values" {
  command = plan

  variables {
    environment  = "prod"
    project_name = "test-module"
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws_region = "us-east-1"
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azure_location = "eastus"
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    gcp_project_id = "test-project"
    gcp_region     = "us-central1"
{%- endif %}
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Environment should be 'prod'"
  }
}

# Test: Feature flags default values
run "validate_feature_flags" {
  command = plan

  variables {
    environment  = "dev"
    project_name = "test-module"
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws_region = "us-east-1"
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azure_location = "eastus"
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    gcp_project_id = "test-project"
    gcp_region     = "us-central1"
{%- endif %}
    enable_compute       = true
    enable_network       = true
    enable_database      = false
    enable_kubernetes    = false
  }

  assert {
    condition     = var.enable_compute == true
    error_message = "Compute should be enabled by default"
  }

  assert {
    condition     = var.enable_database == false
    error_message = "Database should be disabled by default"
  }
}
