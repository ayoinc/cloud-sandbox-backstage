# =============================================================================
# AZURE FULL INFRASTRUCTURE STACK
# =============================================================================
# {{ description }}
#
# This Terraform configuration orchestrates all enabled Azure modules.
# All resources are created through modules - no bare resource blocks.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }

  # Backend configuration - uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "{{ projectName }}/{{ environment }}/terraform.tfstate"
  # }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = var.environment != "prod"
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "prod"
    }
  }
}

provider "azuread" {}

# -----------------------------------------------------------------------------
# Locals - Common Configuration
# -----------------------------------------------------------------------------

locals {
  # Project identifiers
  project     = "{{ projectName }}"
  environment = "{{ environment }}"
  location    = var.azure_location

  # Common tags applied to all resources
  common_tags = {
    Project      = local.project
    Environment  = local.environment
    BusinessUnit = "{{ businessUnit }}"
    ManagedBy    = "terraform"
    CostCenter   = "{{ businessUnit }}"
    Tier         = var.enable_dr ? "critical" : "standard"
    SLA          = local.environment == "prod" ? "24x7" : "business-hours"
    DR           = var.enable_dr ? "enabled" : "disabled"
    AutoShutdown = var.enable_auto_shutdown ? "enabled" : "disabled"
    CreatedBy    = "backstage"
    TemplateRef  = "azure-full-infrastructure"
  }

  # Enable flags from variables (set by Backstage template)
  enable_network     = var.enable_networking
  enable_compute     = var.enable_compute
  enable_containers  = var.enable_containers
  enable_storage     = var.enable_storage
  enable_database    = var.enable_database
  enable_security    = var.enable_security
  enable_identity    = var.enable_identity
  enable_monitoring  = var.enable_monitoring
  enable_integration = var.enable_integration
  enable_governance  = var.enable_governance
}

# =============================================================================
# CORE MODULE - Resource Groups
# =============================================================================
# All infrastructure requires at least one resource group.
# We create resource groups per module category for better organization.
# =============================================================================

# Primary Resource Group (always created)
module "resource_group_primary" {
  source = "./modules/resource-group"

  name        = local.project
  location    = local.location
  project     = local.project
  environment = local.environment
  tags        = local.common_tags

  enable_delete_lock = local.environment == "prod"
}

# Network Resource Group (if networking enabled)
module "resource_group_network" {
  source = "./modules/resource-group"
  count  = local.enable_network ? 1 : 0

  name        = "${local.project}-network"
  location    = local.location
  project     = local.project
  environment = local.environment
  tags        = merge(local.common_tags, { Category = "networking" })

  enable_delete_lock = local.environment == "prod"
}

# Security Resource Group (if security enabled)
module "resource_group_security" {
  source = "./modules/resource-group"
  count  = local.enable_security ? 1 : 0

  name        = "${local.project}-security"
  location    = local.location
  project     = local.project
  environment = local.environment
  tags        = merge(local.common_tags, { Category = "security" })

  enable_delete_lock = true # Always lock security resources
}

# Monitoring Resource Group (if monitoring enabled)
module "resource_group_monitoring" {
  source = "./modules/resource-group"
  count  = local.enable_monitoring ? 1 : 0

  name        = "${local.project}-monitoring"
  location    = local.location
  project     = local.project
  environment = local.environment
  tags        = merge(local.common_tags, { Category = "monitoring" })

  enable_delete_lock = local.environment == "prod"
}

# =============================================================================
# NETWORKING MODULE
# =============================================================================

module "networking" {
  source = "./modules/networking"
  count  = local.enable_network ? 1 : 0

  resource_group_name = module.resource_group_network[0].name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Network configuration
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets

  # High availability options
  enable_ddos_protection = var.enable_high_availability && local.environment == "prod"
}

# =============================================================================
# SECURITY MODULE
# =============================================================================

module "security" {
  source = "./modules/security"
  count  = local.enable_security ? 1 : 0

  resource_group_name = module.resource_group_security[0].name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Key Vault configuration
  enable_soft_delete         = true
  soft_delete_retention_days = local.environment == "prod" ? 90 : 7
  enable_purge_protection    = local.environment == "prod"

  # Network access (if networking enabled)
  subnet_ids = local.enable_network ? [
    for k, v in module.networking[0].subnet_ids : v
  ] : []

  depends_on = [module.resource_group_security]
}

# =============================================================================
# STORAGE MODULE
# =============================================================================

module "storage" {
  source = "./modules/storage"
  count  = local.enable_storage ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Storage configuration
  account_tier             = local.environment == "prod" ? "Premium" : "Standard"
  account_replication_type = var.enable_high_availability ? "GRS" : "LRS"
  enable_versioning        = true
  enable_soft_delete       = true

  # Network access (if networking enabled)
  subnet_ids = local.enable_network ? [
    for k, v in module.networking[0].subnet_ids : v
  ] : []

  depends_on = [module.resource_group_primary]
}

# =============================================================================
# MONITORING MODULE
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  count  = local.enable_monitoring ? 1 : 0

  resource_group_name = module.resource_group_monitoring[0].name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Log Analytics configuration
  retention_in_days = local.environment == "prod" ? 90 : 30
  sku               = local.environment == "prod" ? "PerGB2018" : "Free"

  depends_on = [module.resource_group_monitoring]
}

# =============================================================================
# CONTAINERS MODULE (AKS + ACR)
# =============================================================================

module "containers" {
  source = "./modules/containers"
  count  = local.enable_containers ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # AKS configuration
  kubernetes_version  = var.kubernetes_version
  node_count          = var.aks_node_count
  node_vm_size        = var.aks_node_vm_size
  enable_auto_scaling = var.enable_high_availability
  min_node_count      = var.aks_min_node_count
  max_node_count      = var.aks_max_node_count

  # Networking (if enabled)
  vnet_subnet_id = local.enable_network ? module.networking[0].subnet_ids["aks"] : null

  # Monitoring (if enabled)
  log_analytics_workspace_id = local.enable_monitoring ? module.monitoring[0].workspace_id : null

  depends_on = [
    module.resource_group_primary,
    module.networking,
    module.monitoring
  ]
}

# =============================================================================
# DATABASE MODULE
# =============================================================================

module "database" {
  source = "./modules/database"
  count  = local.enable_database ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Database configuration
  database_type = var.database_type
  sku_name      = var.database_sku_name
  storage_mb    = var.database_storage_mb

  # High availability
  enable_geo_redundant_backup = var.enable_dr
  enable_high_availability    = var.enable_high_availability

  # Networking (if enabled)
  subnet_id = local.enable_network ? module.networking[0].subnet_ids["database"] : null

  # Key Vault for secrets (if security enabled)
  key_vault_id = local.enable_security ? module.security[0].key_vault_id : null

  depends_on = [
    module.resource_group_primary,
    module.networking,
    module.security
  ]
}

# =============================================================================
# COMPUTE MODULE
# =============================================================================

module "compute" {
  source = "./modules/compute"
  count  = local.enable_compute ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # VM configuration
  vm_size  = var.vm_size
  vm_count = var.vm_count
  os_type  = var.os_type

  # Networking (if enabled)
  subnet_id = local.enable_network ? module.networking[0].subnet_ids["compute"] : null

  # Auto-shutdown (for non-prod)
  enable_auto_shutdown   = var.enable_auto_shutdown
  auto_shutdown_schedule = var.auto_shutdown_schedule

  depends_on = [
    module.resource_group_primary,
    module.networking
  ]
}

# =============================================================================
# IDENTITY MODULE
# =============================================================================

module "identity" {
  source = "./modules/identity"
  count  = local.enable_identity ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Managed identity configuration
  create_user_assigned_identity = true

  depends_on = [module.resource_group_primary]
}

# =============================================================================
# INTEGRATION MODULE
# =============================================================================

module "integration" {
  source = "./modules/integration"
  count  = local.enable_integration ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Service Bus configuration
  enable_service_bus = true
  service_bus_sku    = local.environment == "prod" ? "Premium" : "Standard"

  # Event Grid configuration
  enable_event_grid = true

  depends_on = [module.resource_group_primary]
}

# =============================================================================
# GOVERNANCE MODULE
# =============================================================================

module "governance" {
  source = "./modules/governance"
  count  = local.enable_governance ? 1 : 0

  resource_group_name = module.resource_group_primary.name
  location            = local.location
  project             = local.project
  environment         = local.environment
  tags                = local.common_tags

  # Cost management
  enable_budget_alerts = true
  monthly_budget       = var.monthly_budget

  # Policy assignments
  enable_tagging_policy = true
  required_tags         = ["Project", "Environment", "CostCenter"]

  depends_on = [module.resource_group_primary]
}
