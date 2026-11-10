# =============================================================================
# Azure Full Infrastructure
# =============================================================================
# Orchestrates the modules under ./modules. Each enable_* variable switches one
# module on or off; enabled modules are wired to each other automatically.
# =============================================================================

locals {
  prefix = "${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project      = var.name
      Environment  = var.environment
      BusinessUnit = var.business_unit
      CostCenter   = var.business_unit
      ManagedBy    = "terraform"
      DR           = var.enable_dr ? "enabled" : "disabled"
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.description != "" ? { Description = substr(var.description, 0, 256) } : {},
  )

  # Subnet layout inside the virtual network (shown for 10.0.0.0/16).
  subnets = {
    default = {
      address_prefix    = cidrsubnet(var.vnet_address_space, 8, 1) # 10.0.1.0/24
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    aks = {
      address_prefix    = cidrsubnet(var.vnet_address_space, 4, 1) # 10.0.16.0/20
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    database = {
      address_prefix    = cidrsubnet(var.vnet_address_space, 8, 32) # 10.0.32.0/24
      service_endpoints = ["Microsoft.Storage"]
      delegation        = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
    compute = {
      address_prefix    = cidrsubnet(var.vnet_address_space, 8, 33) # 10.0.33.0/24
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    private_endpoints = {
      address_prefix = cidrsubnet(var.vnet_address_space, 8, 34) # 10.0.34.0/24
    }
  }

  # Subnets whose workloads reach Key Vault and storage through service endpoints.
  service_subnets = ["default", "aks", "compute"]

  service_subnet_ids = var.enable_networking ? [
    for name in local.service_subnets : module.networking[0].subnet_ids[name]
  ] : []

  storage_replication_type = (
    var.enable_dr && var.enable_high_availability ? "GZRS" :
    var.enable_dr ? "GRS" :
    var.enable_high_availability ? "ZRS" : "LRS"
  )

  is_prod = var.environment == "prod"
}

# The compute module attaches its virtual machines to a subnet.
resource "terraform_data" "requirements" {
  lifecycle {
    precondition {
      condition     = !var.enable_compute || var.enable_networking
      error_message = "enable_compute needs enable_networking: virtual machines are attached to the compute subnet."
    }
  }
}

# =============================================================================
# Resource Groups
# =============================================================================
# Workloads share the primary group. Networking, security and monitoring have
# their own groups so access to them can be granted separately.

module "resource_group_primary" {
  source = "./modules/resource-group"

  name               = "rg-${local.prefix}"
  location           = var.location
  tags               = local.common_tags
  enable_delete_lock = local.is_prod
}

module "resource_group_network" {
  source = "./modules/resource-group"
  count  = var.enable_networking ? 1 : 0

  name               = "rg-${local.prefix}-network"
  location           = var.location
  tags               = merge(local.common_tags, { Category = "networking" })
  enable_delete_lock = local.is_prod
}

module "resource_group_security" {
  source = "./modules/resource-group"
  count  = var.enable_security ? 1 : 0

  name               = "rg-${local.prefix}-security"
  location           = var.location
  tags               = merge(local.common_tags, { Category = "security" })
  enable_delete_lock = local.is_prod
}

module "resource_group_monitoring" {
  source = "./modules/resource-group"
  count  = var.enable_monitoring ? 1 : 0

  name               = "rg-${local.prefix}-monitoring"
  location           = var.location
  tags               = merge(local.common_tags, { Category = "monitoring" })
  enable_delete_lock = local.is_prod
}

# =============================================================================
# Networking
# =============================================================================

module "networking" {
  source = "./modules/networking"
  count  = var.enable_networking ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_network[0].name
  tags                = local.common_tags

  address_space = var.vnet_address_space
  subnets       = local.subnets

  enable_nat_gateway  = var.enable_nat_gateway
  nat_gateway_subnets = local.service_subnets

  enable_bastion        = var.enable_bastion
  bastion_subnet_prefix = cidrsubnet(var.vnet_address_space, 10, 1016) # 10.0.254.0/26

  enable_ddos_protection = var.enable_ddos_protection
}

# =============================================================================
# Monitoring
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_monitoring[0].name
  tags                = local.common_tags

  retention_in_days = var.log_retention_days
}

# =============================================================================
# Security
# =============================================================================

module "security" {
  source = "./modules/security"
  count  = var.enable_security ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_security[0].name
  tags                = local.common_tags

  restrict_network_access = var.restrict_network_access
  allowed_subnet_ids      = local.service_subnet_ids
  allowed_ip_ranges       = var.allowed_ip_ranges
}

# =============================================================================
# Identity
# =============================================================================

module "identity" {
  source = "./modules/identity"
  count  = var.enable_identity ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  grant_key_vault_access = var.enable_security
  key_vault_id           = var.enable_security ? module.security[0].key_vault_id : null
}

# =============================================================================
# Storage
# =============================================================================

module "storage" {
  source = "./modules/storage"
  count  = var.enable_storage ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  replication_type           = local.storage_replication_type
  soft_delete_retention_days = local.is_prod ? 30 : 7

  restrict_network_access = var.restrict_network_access
  allowed_subnet_ids      = local.service_subnet_ids
  allowed_ip_ranges       = var.allowed_ip_ranges
}

# =============================================================================
# Containers
# =============================================================================

module "containers" {
  source = "./modules/containers"
  count  = var.enable_containers ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  kubernetes_version = var.kubernetes_version
  node_vm_size       = var.aks_node_vm_size
  node_count         = var.aks_node_count
  min_node_count     = var.aks_min_node_count
  max_node_count     = var.aks_max_node_count

  enable_high_availability = var.enable_high_availability

  # Geo-replication needs the Premium registry
  acr_sku                 = var.enable_dr ? "Premium" : "Standard"
  georeplication_location = var.enable_dr ? var.secondary_location : null

  enable_vnet_integration = var.enable_networking
  vnet_subnet_id          = var.enable_networking ? module.networking[0].subnet_ids["aks"] : null

  enable_container_insights  = var.enable_monitoring
  log_analytics_workspace_id = var.enable_monitoring ? module.monitoring[0].workspace_id : null
}

# =============================================================================
# Database
# =============================================================================

module "database" {
  source = "./modules/database"
  count  = var.enable_database ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  sku_name              = var.database_sku_name
  storage_mb            = var.database_storage_mb
  backup_retention_days = local.is_prod ? 35 : 7

  enable_geo_redundant_backup = var.enable_dr
  enable_high_availability    = var.enable_high_availability

  enable_vnet_integration = var.enable_networking
  delegated_subnet_id     = var.enable_networking ? module.networking[0].subnet_ids["database"] : null
  virtual_network_id      = var.enable_networking ? module.networking[0].vnet_id : null
}

# =============================================================================
# Compute
# =============================================================================

module "compute" {
  source = "./modules/compute"
  count  = var.enable_compute ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  subnet_id            = try(module.networking[0].subnet_ids["compute"], null)
  vm_size              = var.vm_size
  vm_count             = var.vm_count
  admin_ssh_public_key = var.admin_ssh_public_key

  enable_high_availability = var.enable_high_availability

  enable_auto_shutdown = var.enable_auto_shutdown && !local.is_prod
  auto_shutdown_time   = var.auto_shutdown_time

  depends_on = [terraform_data.requirements]
}

# =============================================================================
# Integration
# =============================================================================

module "integration" {
  source = "./modules/integration"
  count  = var.enable_integration ? 1 : 0

  name                = var.name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group_primary.name
  tags                = local.common_tags

  service_bus_sku          = local.is_prod ? "Premium" : "Standard"
  enable_high_availability = var.enable_high_availability
}

# =============================================================================
# Governance
# =============================================================================

module "governance" {
  source = "./modules/governance"
  count  = var.enable_governance ? 1 : 0

  name              = var.name
  environment       = var.environment
  resource_group_id = module.resource_group_primary.id

  monthly_budget = var.monthly_budget
  required_tags  = ["Project", "Environment", "CostCenter"]
}
