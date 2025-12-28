# =============================================================================
# Development Environment Configuration
# =============================================================================

# Location
azure_location = "eastus"

# Module Enablement
enable_networking  = true
enable_compute     = false
enable_containers  = false
enable_storage     = true
enable_database    = false
enable_security    = true
enable_identity    = false
enable_monitoring  = true
enable_integration = false
enable_governance  = false

# Features
enable_dr                = false
enable_high_availability = false
enable_auto_shutdown     = true
auto_shutdown_schedule   = "0 19 * * 1-5"

# Networking
vnet_address_space = ["10.0.0.0/16"]

# AKS (if enabled)
kubernetes_version = "1.28"
aks_node_count     = 2
aks_node_vm_size   = "Standard_D2s_v3"

# Database (if enabled)
database_type       = "postgresql"
database_sku_name   = "B_Gen5_1"
database_storage_mb = 32768

# Compute (if enabled)
vm_size  = "Standard_B2s"
vm_count = 1

# Governance
monthly_budget = 500
