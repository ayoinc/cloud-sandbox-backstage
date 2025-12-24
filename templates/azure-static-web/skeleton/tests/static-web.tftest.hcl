# =============================================================================
# Azure Static Web App - Terraform Tests
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
  name                        = "test-static-web"
  environment                 = "dev"
  location                    = "eastus2"
  description                 = "Test Static Web App for validation"
  owner                       = "platform-team"
  sku_tier                    = "Free"
  framework                   = "react"
  enable_preview_environments = true
  enable_config_file_changes  = true
  custom_domain               = ""
  api_backend_resource_id     = ""
  tags = {
    TestTag = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: Static Web App Module Plan Succeeds
# -----------------------------------------------------------------------------
run "static_web_plan_succeeds" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.static_web_app_name != ""
    error_message = "Static Web App name should not be empty"
  }

  assert {
    condition     = output.resource_group_name != ""
    error_message = "Resource group name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Static Web App Naming Convention
# -----------------------------------------------------------------------------
run "static_web_naming_convention" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.static_web_app_name == "swa-test-static-web-dev"
    error_message = "Static Web App name should follow convention: swa-{name}-{environment}"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-static-web-dev"
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
# Test: Build Configuration Output - React
# -----------------------------------------------------------------------------
run "build_config_react" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    framework = "react"
  }

  assert {
    condition     = output.build_config != null
    error_message = "Build config should not be null"
  }

  assert {
    condition     = output.build_config.app_location == "/"
    error_message = "React app_location should be '/'"
  }

  assert {
    condition     = output.build_config.output_location == "build"
    error_message = "React output_location should be 'build'"
  }
}

# -----------------------------------------------------------------------------
# Test: Build Configuration Output - Vue
# -----------------------------------------------------------------------------
run "build_config_vue" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    framework = "vue"
  }

  assert {
    condition     = output.build_config != null
    error_message = "Build config should not be null for Vue"
  }

  assert {
    condition     = output.build_config.output_location == "dist"
    error_message = "Vue output_location should be 'dist'"
  }
}

# -----------------------------------------------------------------------------
# Test: Build Configuration Output - Next.js
# -----------------------------------------------------------------------------
run "build_config_nextjs" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    framework = "nextjs"
  }

  assert {
    condition     = output.build_config != null
    error_message = "Build config should not be null for Next.js"
  }

  assert {
    condition     = output.build_config.output_location == ".next"
    error_message = "Next.js output_location should be '.next'"
  }
}

# -----------------------------------------------------------------------------
# Test: Build Configuration Output - Angular
# -----------------------------------------------------------------------------
run "build_config_angular" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    framework = "angular"
  }

  assert {
    condition     = output.build_config != null
    error_message = "Build config should not be null for Angular"
  }

  assert {
    condition     = output.build_config.output_location == "dist/app"
    error_message = "Angular output_location should be 'dist/app'"
  }
}

# -----------------------------------------------------------------------------
# Test: Build Configuration Output - Static
# -----------------------------------------------------------------------------
run "build_config_static" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    framework = "static"
  }

  assert {
    condition     = output.build_config != null
    error_message = "Build config should not be null for static"
  }

  assert {
    condition     = output.build_config.output_location == ""
    error_message = "Static output_location should be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Static Web App Info Summary
# -----------------------------------------------------------------------------
run "static_web_info_summary" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.static_web_app_info != null
    error_message = "Static Web App info summary should not be null"
  }

  assert {
    condition     = output.static_web_app_info.name == "swa-test-static-web-dev"
    error_message = "Static Web App info name should match expected naming"
  }

  assert {
    condition     = output.static_web_app_info.framework == "react"
    error_message = "Static Web App info framework should be 'react'"
  }

  assert {
    condition     = output.static_web_app_info.sku_tier == "Free"
    error_message = "Static Web App info sku_tier should be 'Free'"
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
    condition     = output.resource_group_name == "rg-test-static-web-dev"
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
    condition     = output.resource_group_name == "rg-test-static-web-staging"
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
    condition     = output.resource_group_name == "rg-test-static-web-prod"
    error_message = "Production environment should be reflected in resource names"
  }
}

# -----------------------------------------------------------------------------
# Test: SKU Tier - Free
# -----------------------------------------------------------------------------
run "sku_tier_free" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    sku_tier = "Free"
  }

  assert {
    condition     = output.static_web_app_info.sku_tier == "Free"
    error_message = "SKU tier should be 'Free'"
  }
}

# -----------------------------------------------------------------------------
# Test: SKU Tier - Standard
# -----------------------------------------------------------------------------
run "sku_tier_standard" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    sku_tier = "Standard"
  }

  assert {
    condition     = output.static_web_app_info.sku_tier == "Standard"
    error_message = "SKU tier should be 'Standard'"
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
      Project    = "frontend"
    }
  }

  assert {
    condition     = output.static_web_app_info != null
    error_message = "Static Web App should be created with custom tags"
  }
}

# -----------------------------------------------------------------------------
# Test: Static Web App ID Output
# -----------------------------------------------------------------------------
run "static_web_app_id_output" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.static_web_app_id != ""
    error_message = "Static Web App ID should not be empty"
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
    condition     = output.static_web_app_info.location == "westus2"
    error_message = "Static Web App location should be 'westus2'"
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
    condition     = output.static_web_app_info.location == "westeurope"
    error_message = "Static Web App location should be 'westeurope'"
  }
}
