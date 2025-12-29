# =============================================================================
# AZURE FULL INFRASTRUCTURE - LOCALS
# =============================================================================

locals {
  # Standard tags for all resources
  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "${{ values.name }}"
    Owner       = "${{ values.owner }}"
  }, var.additional_tags)

  # Environment-specific configurations
  env_configs = {
    dev = {
      # Monitoring
      log_retention_days = 30

      # Storage
      storage_replication = "LRS"

      # Compute
      vm_size = "Standard_B2s"

      # AKS
      aks_sku_tier   = "Free"
      aks_node_count = 1
      aks_max_nodes  = 3

      # Database
      sql_sku = "Basic"
    }

    staging = {
      # Monitoring
      log_retention_days = 60

      # Storage
      storage_replication = "ZRS"

      # Compute
      vm_size = "Standard_D2s_v3"

      # AKS
      aks_sku_tier   = "Standard"
      aks_node_count = 2
      aks_max_nodes  = 5

      # Database
      sql_sku = "S1"
    }

    prod = {
      # Monitoring
      log_retention_days = 90

      # Storage
      storage_replication = "GRS"

      # Compute
      vm_size = "Standard_D4s_v3"

      # AKS
      aks_sku_tier   = "Standard"
      aks_node_count = 3
      aks_max_nodes  = 10

      # Database
      sql_sku = "P1"
    }
  }

  env_config = lookup(local.env_configs, var.environment, local.env_configs["dev"])
}
