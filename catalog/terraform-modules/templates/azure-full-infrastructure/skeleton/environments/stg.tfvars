# =============================================================================
# Staging Environment Configuration
# =============================================================================

# Location
azure_location = "eastus"

# Module Enablement
enable_networking  = true
enable_compute     = false
enable_containers  = true
enable_storage     = true
enable_database    = true
enable_security    = true
enable_identity    = true
enable_monitoring  = true
enable_integration = false
enable_governance  = true

# Features
enable_dr                = false
enable_high_availability = true
enable_auto_shutdown     = true
auto_shutdown_schedule   = "0 20 * * 1-5"

# Networking
vnet_address_space = ["10.1.0.0/16"]

# AKS
kubernetes_version = "1.28"
aks_node_count     = 3
aks_node_vm_size   = "Standard_D4s_v3"
aks_min_node_count = 2
aks_max_node_count = 6

# Database
database_type       = "postgresql"
database_sku_name   = "GP_Gen5_2"
database_storage_mb = 65536

# Compute
vm_size  = "Standard_D2s_v3"
vm_count = 2

# Governance
monthly_budget = 2000
