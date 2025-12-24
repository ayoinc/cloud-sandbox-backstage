# =============================================================================
# Azure Functions - Terraform Tests
# =============================================================================
# Uses Terraform native testing framework with output.* references.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Provider for Testing
# -----------------------------------------------------------------------------
mock_provider "azurerm" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name                 = "test-functions"
  environment          = "dev"
  location             = "eastus2"
  description          = "Test Function App for validation"
  owner                = "platform-team"
  runtime_stack        = "node"
  runtime_version      = "18"
  sku_tier             = "Consumption"
  storage_account_tier = "Standard"
  enable_app_insights  = true
  app_settings         = {}
  cors_allowed_origins = ["https://portal.azure.com"]
  cors_support_credentials = false
  tags = {
    TestTag = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: Function App Module Plan Succeeds
# -----------------------------------------------------------------------------
run "function_app_plan_succeeds" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.function_app_name != ""
    error_message = "Function App name should not be empty"
  }

  assert {
    condition     = output.resource_group_name != ""
    error_message = "Resource group name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Function App Naming Convention
# -----------------------------------------------------------------------------
run "function_app_naming_convention" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.function_app_name == "func-test-functions-dev"
    error_message = "Function App name should follow convention: func-{name}-{environment}"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-functions-dev"
    error_message = "Resource group name should follow convention: rg-{name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: URL Output Format
# -----------------------------------------------------------------------------
run "url_output_format" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.url != ""
    error_message = "URL output should not be empty"
  }

  assert {
    condition     = can(regex("^https://", output.url))
    error_message = "URL should start with https://"
  }
}

# -----------------------------------------------------------------------------
# Test: Default Hostname Output
# -----------------------------------------------------------------------------
run "default_hostname_output" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.default_hostname != ""
    error_message = "Default hostname should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Storage Account Output
# -----------------------------------------------------------------------------
run "storage_account_output" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.storage_account_name != ""
    error_message = "Storage account name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Runtime Stack - Node.js
# -----------------------------------------------------------------------------
run "runtime_stack_node" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    runtime_stack   = "node"
    runtime_version = "18"
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App info should not be null"
  }

  assert {
    condition     = output.function_app_info.runtime_stack == "node"
    error_message = "Runtime stack should be 'node'"
  }

  assert {
    condition     = output.function_app_info.runtime_version == "18"
    error_message = "Runtime version should be '18'"
  }
}

# -----------------------------------------------------------------------------
# Test: Runtime Stack - Python
# -----------------------------------------------------------------------------
run "runtime_stack_python" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    runtime_stack   = "python"
    runtime_version = "3.11"
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App info should not be null for Python"
  }

  assert {
    condition     = output.function_app_info.runtime_stack == "python"
    error_message = "Runtime stack should be 'python'"
  }
}

# -----------------------------------------------------------------------------
# Test: Runtime Stack - .NET
# -----------------------------------------------------------------------------
run "runtime_stack_dotnet" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    runtime_stack   = "dotnet"
    runtime_version = "8.0"
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App info should not be null for .NET"
  }

  assert {
    condition     = output.function_app_info.runtime_stack == "dotnet"
    error_message = "Runtime stack should be 'dotnet'"
  }
}

# -----------------------------------------------------------------------------
# Test: Runtime Stack - Java
# -----------------------------------------------------------------------------
run "runtime_stack_java" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    runtime_stack   = "java"
    runtime_version = "17"
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App info should not be null for Java"
  }

  assert {
    condition     = output.function_app_info.runtime_stack == "java"
    error_message = "Runtime stack should be 'java'"
  }
}

# -----------------------------------------------------------------------------
# Test: SKU Tier - Consumption
# -----------------------------------------------------------------------------
run "sku_tier_consumption" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    sku_tier = "Consumption"
  }

  assert {
    condition     = output.function_app_info.sku_tier == "Consumption"
    error_message = "SKU tier should be 'Consumption'"
  }
}

# -----------------------------------------------------------------------------
# Test: SKU Tier - Premium
# -----------------------------------------------------------------------------
run "sku_tier_premium" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    sku_tier = "Premium"
  }

  assert {
    condition     = output.function_app_info.sku_tier == "Premium"
    error_message = "SKU tier should be 'Premium'"
  }
}

# -----------------------------------------------------------------------------
# Test: SKU Tier - Dedicated
# -----------------------------------------------------------------------------
run "sku_tier_dedicated" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    sku_tier = "Dedicated"
  }

  assert {
    condition     = output.function_app_info.sku_tier == "Dedicated"
    error_message = "SKU tier should be 'Dedicated'"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation - Development
# -----------------------------------------------------------------------------
run "environment_dev" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-functions-dev"
    error_message = "Development environment should be reflected in resource names"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation - Staging
# -----------------------------------------------------------------------------
run "environment_staging" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    environment = "staging"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-functions-staging"
    error_message = "Staging environment should be reflected in resource names"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation - Production
# -----------------------------------------------------------------------------
run "environment_prod" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-functions-prod"
    error_message = "Production environment should be reflected in resource names"
  }
}

# -----------------------------------------------------------------------------
# Test: Application Insights Enabled
# -----------------------------------------------------------------------------
run "app_insights_enabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    enable_app_insights = true
  }

  assert {
    condition     = output.function_app_info.app_insights != null
    error_message = "Application Insights should be created when enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Application Insights Disabled
# -----------------------------------------------------------------------------
run "app_insights_disabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    enable_app_insights = false
  }

  assert {
    condition     = output.function_app_info.app_insights == null
    error_message = "Application Insights should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Function App Info Summary
# -----------------------------------------------------------------------------
run "function_app_info_summary" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App info summary should not be null"
  }

  assert {
    condition     = output.function_app_info.name == "func-test-functions-dev"
    error_message = "Function App info name should match expected naming"
  }

  assert {
    condition     = output.function_app_info.runtime_stack == "node"
    error_message = "Function App info runtime_stack should be 'node'"
  }

  assert {
    condition     = output.function_app_info.sku_tier == "Consumption"
    error_message = "Function App info sku_tier should be 'Consumption'"
  }
}

# -----------------------------------------------------------------------------
# Test: Managed Identity Output
# -----------------------------------------------------------------------------
run "managed_identity_output" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.principal_id != ""
    error_message = "Principal ID should not be empty"
  }

  assert {
    condition     = output.function_app_info.managed_identity != ""
    error_message = "Managed identity principal ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Location Configuration
# -----------------------------------------------------------------------------
run "location_westus2" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    location = "westus2"
  }

  assert {
    condition     = output.function_app_info.location == "westus2"
    error_message = "Function App location should be 'westus2'"
  }
}

# -----------------------------------------------------------------------------
# Test: Location Configuration - Europe
# -----------------------------------------------------------------------------
run "location_westeurope" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    location = "westeurope"
  }

  assert {
    condition     = output.function_app_info.location == "westeurope"
    error_message = "Function App location should be 'westeurope'"
  }
}

# -----------------------------------------------------------------------------
# Test: Custom Tags
# -----------------------------------------------------------------------------
run "custom_tags" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    tags = {
      CostCenter = "engineering"
      Project    = "serverless"
    }
  }

  assert {
    condition     = output.function_app_info != null
    error_message = "Function App should be created with custom tags"
  }
}
