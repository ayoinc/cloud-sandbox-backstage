# =============================================================================
# Production Environment Configuration
# =============================================================================

# Location
azure_location   = "eastus"
secondary_region = "westus2"

# Module Enablement - All modules enabled for production
enable_networking  = true
enable_compute     = false
enable_containers  = true
enable_storage     = true
enable_database    = true
enable_security    = true
enable_identity    = true
enable_monitoring  = true
enable_integration = true
enable_governance  = true

# Features
enable_dr                = true
enable_high_availability = true
enable_auto_shutdown     = false

# Networking
vnet_address_space = ["10.2.0.0/16"]

# AKS
kubernetes_version = "1.28"
aks_node_count     = 5
aks_node_vm_size   = "Standard_D8s_v3"
aks_min_node_count = 3
aks_max_node_count = 20

# Database
database_type       = "postgresql"
database_sku_name   = "GP_Gen5_4"
database_storage_mb = 131072

# Compute
vm_size  = "Standard_D4s_v3"
vm_count = 3

# Governance
monthly_budget = 10000
