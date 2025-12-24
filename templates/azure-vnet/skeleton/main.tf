# =============================================================================
# Azure VNet - Root Module
# =============================================================================
# This is the root module that instantiates the VNet child module.
# All environment-specific values are passed via -var-file.
# =============================================================================

module "vnet" {
  source = "./modules/vnet"

  # Required variables
  name        = var.name
  environment = var.environment
  location    = var.location
  description = var.description
  owner       = var.owner

  # Network configuration
  address_space        = var.address_space
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr
  aks_subnet_cidr      = var.aks_subnet_cidr

  # Optional configuration
  dns_servers            = var.dns_servers
  enable_nat_gateway     = var.enable_nat_gateway
  nat_idle_timeout       = var.nat_idle_timeout
  availability_zones     = var.availability_zones
  enable_ddos_protection = var.enable_ddos_protection
  tags                   = var.tags
}
