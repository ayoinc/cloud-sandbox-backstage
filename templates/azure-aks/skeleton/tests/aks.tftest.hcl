# =============================================================================
# Azure AKS - Terraform Tests
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
  name               = "test-aks"
  environment        = "dev"
  location           = "eastus"
  description        = "Test AKS cluster"
  owner              = "platform-team"
  kubernetes_version = "1.28.5"

  # System Node Pool
  system_node_vm_size = "Standard_D2s_v3"
  system_node_count   = 1
  system_min_count    = 1
  system_max_count    = 3

  # User Node Pool
  create_user_node_pool = true
  user_node_vm_size     = "Standard_D2s_v3"
  user_node_count       = 1
  user_min_count        = 0
  user_max_count        = 5
  user_node_taints      = []

  # Spot Node Pool
  create_spot_node_pool = false

  # Common
  enable_auto_scaling = true
  os_disk_size_gb     = 64
  max_surge           = "33%"
  availability_zones  = ["1"]

  # Network
  network_plugin = "azure"
  network_policy = "calico"
  outbound_type  = "loadBalancer"
  vnet_subnet_id = ""
  service_cidr   = "10.0.0.0/16"
  dns_service_ip = "10.0.0.10"

  # ACR
  create_acr = true
  acr_sku    = "Basic"

  # Monitoring
  log_retention_days = 30
  enable_defender    = false

  # Security
  enable_azure_rbac        = true
  admin_group_object_ids   = []
  enable_workload_identity = true
  enable_secret_rotation   = false

  # Upgrades
  automatic_channel_upgrade = "patch"
  maintenance_window        = null

  # Autoscaler
  scale_down_delay_after_add       = "5m"
  scale_down_unneeded              = "5m"
  scale_down_utilization_threshold = "0.7"

  tags = {
    TestTag = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: AKS Module Plan Succeeds
# -----------------------------------------------------------------------------
run "aks_plan_succeeds" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.cluster_name != ""
    error_message = "Cluster name should not be empty"
  }

  assert {
    condition     = output.resource_group_name != ""
    error_message = "Resource group name should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: AKS Naming Convention
# -----------------------------------------------------------------------------
run "aks_naming_convention" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.cluster_name == "aks-test-aks-dev"
    error_message = "Cluster name should follow convention: aks-{name}-{environment}"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-aks-dev"
    error_message = "Resource group name should follow convention: rg-{name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: ACR Created When Enabled
# -----------------------------------------------------------------------------
run "acr_created_when_enabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    create_acr = true
  }

  assert {
    condition     = output.acr_id != null
    error_message = "ACR should be created when create_acr is true"
  }

  assert {
    condition     = output.acr_login_server != null
    error_message = "ACR login server should not be null"
  }
}

# -----------------------------------------------------------------------------
# Test: ACR NOT Created When Disabled
# -----------------------------------------------------------------------------
run "acr_not_created_when_disabled" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  variables {
    create_acr = false
  }

  assert {
    condition     = output.acr_id == null
    error_message = "ACR should not be created when create_acr is false"
  }
}

# -----------------------------------------------------------------------------
# Test: Kubernetes Version
# -----------------------------------------------------------------------------
run "kubernetes_version" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.kubernetes_version == "1.28.5"
    error_message = "Kubernetes version should match input"
  }
}

# -----------------------------------------------------------------------------
# Test: Get Credentials Command
# -----------------------------------------------------------------------------
run "get_credentials_command" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.get_credentials_command != ""
    error_message = "Get credentials command should not be empty"
  }

  assert {
    condition     = can(regex("az aks get-credentials", output.get_credentials_command))
    error_message = "Get credentials command should contain az aks get-credentials"
  }
}

# -----------------------------------------------------------------------------
# Test: Cluster Info Summary
# -----------------------------------------------------------------------------
run "cluster_info_summary" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.cluster_info != null
    error_message = "Cluster info summary should not be null"
  }

  assert {
    condition     = output.cluster_info.name == "aks-test-aks-dev"
    error_message = "Cluster info name should match expected naming"
  }

  assert {
    condition     = output.cluster_info.location == "eastus"
    error_message = "Cluster info location should match input"
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
    condition     = output.cluster_name == "aks-test-aks-dev"
    error_message = "Development environment should be reflected in cluster name"
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
    condition     = output.cluster_name == "aks-test-aks-prod"
    error_message = "Production environment should be reflected in cluster name"
  }
}

# -----------------------------------------------------------------------------
# Test: Identity Outputs
# -----------------------------------------------------------------------------
run "identity_outputs" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.identity_principal_id != ""
    error_message = "Identity principal ID should not be empty"
  }

  assert {
    condition     = output.identity_client_id != ""
    error_message = "Identity client ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Log Analytics Created
# -----------------------------------------------------------------------------
run "log_analytics_created" {
  command = plan

  providers = {
    azurerm = azurerm.mock
  }

  assert {
    condition     = output.log_analytics_workspace_id != ""
    error_message = "Log Analytics workspace should be created"
  }
}
