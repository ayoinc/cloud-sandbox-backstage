# =============================================================================
# Azure VNet - Terraform Tests
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
  name                 = "test-vnet"
  environment          = "dev"
  location             = "eastus"
  description          = "Test VNet for validation"
  owner                = "platform-team"
  address_space        = "10.0.0.0/16"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  database_subnet_cidr = "10.0.3.0/24"
  aks_subnet_cidr      = "10.0.16.0/20"
  enable_nat_gateway   = true
  nat_idle_timeout     = 10
  availability_zones   = ["1"]
  dns_servers          = []
  enable_ddos_protection = false
  tags = {
    TestTag = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: VNet Module Plan Succeeds
# -----------------------------------------------------------------------------
run "vnet_plan_succeeds" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.vnet_name != ""
    error_message = "VNet name should not be empty"
  }

  assert {
    condition     = output.resource_group_name != ""
    error_message = "Resource group name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: VNet Naming Convention
# -----------------------------------------------------------------------------
run "vnet_naming_convention" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.vnet_name == "vnet-test-vnet-dev"
    error_message = "VNet name should follow convention: vnet-{name}-{environment}"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-vnet-dev"
    error_message = "Resource group name should follow convention: rg-{name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet IDs are Created
# -----------------------------------------------------------------------------
run "subnet_ids_created" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.public_subnet_id != ""
    error_message = "Public subnet ID should not be empty"
  }

  assert {
    condition     = output.private_subnet_id != ""
    error_message = "Private subnet ID should not be empty"
  }

  assert {
    condition     = output.database_subnet_id != ""
    error_message = "Database subnet ID should not be empty"
  }

  assert {
    condition     = output.aks_subnet_id != ""
    error_message = "AKS subnet ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: NSG IDs are Created
# -----------------------------------------------------------------------------
run "nsg_ids_created" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.public_nsg_id != ""
    error_message = "Public NSG ID should not be empty"
  }

  assert {
    condition     = output.private_nsg_id != ""
    error_message = "Private NSG ID should not be empty"
  }

  assert {
    condition     = output.database_nsg_id != ""
    error_message = "Database NSG ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: NAT Gateway is Created When Enabled
# -----------------------------------------------------------------------------
run "nat_gateway_created_when_enabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    enable_nat_gateway = true
  }

  assert {
    condition     = output.nat_gateway_id != null
    error_message = "NAT Gateway should be created when enable_nat_gateway is true"
  }
}

# -----------------------------------------------------------------------------
# Test: NAT Gateway is NOT Created When Disabled
# -----------------------------------------------------------------------------
run "nat_gateway_not_created_when_disabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = output.nat_gateway_id == null
    error_message = "NAT Gateway should not be created when enable_nat_gateway is false"
  }
}

# -----------------------------------------------------------------------------
# Test: VNet Address Space
# -----------------------------------------------------------------------------
run "vnet_address_space" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = contains(output.vnet_address_space, "10.0.0.0/16")
    error_message = "VNet address space should include the configured CIDR"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet Map Contains All Subnets
# -----------------------------------------------------------------------------
run "subnet_map_complete" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = length(output.subnet_ids) == 4
    error_message = "Subnet IDs map should contain 4 subnets"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "public")
    error_message = "Subnet IDs map should contain 'public' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "private")
    error_message = "Subnet IDs map should contain 'private' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "database")
    error_message = "Subnet IDs map should contain 'database' key"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "aks")
    error_message = "Subnet IDs map should contain 'aks' key"
  }
}

# -----------------------------------------------------------------------------
# Test: VNet Info Summary
# -----------------------------------------------------------------------------
run "vnet_info_summary" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.vnet_info != null
    error_message = "VNet info summary should not be null"
  }

  assert {
    condition     = output.vnet_info.name == "vnet-test-vnet-dev"
    error_message = "VNet info name should match expected naming"
  }

  assert {
    condition     = output.vnet_info.location == "eastus"
    error_message = "VNet info location should match input"
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
    condition     = output.resource_group_name == "rg-test-vnet-dev"
    error_message = "Development environment should be reflected in resource names"
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
    condition     = output.resource_group_name == "rg-test-vnet-prod"
    error_message = "Production environment should be reflected in resource names"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple Availability Zones
# -----------------------------------------------------------------------------
run "multiple_availability_zones" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    availability_zones = ["1", "2", "3"]
    enable_nat_gateway = true
  }

  assert {
    condition     = output.nat_gateway_id != null
    error_message = "NAT Gateway should be created with multiple availability zones"
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
      Project    = "infrastructure"
    }
  }

  assert {
    condition     = output.vnet_info != null
    error_message = "VNet should be created with custom tags"
  }
}
