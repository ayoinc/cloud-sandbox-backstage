# =============================================================================
# Azure VNet - Root Module
# =============================================================================
# This is the root module that instantiates the VNet child module.
# All environment-specific values are passed via -var-file.
# =============================================================================

locals {
  # Default subnet layout: public, private and database take the first three
  # sixteenths of the address space, AKS takes its second quarter.
  public_subnet_cidr   = coalesce(var.public_subnet_cidr, cidrsubnet(var.address_space, 4, 0))
  private_subnet_cidr  = coalesce(var.private_subnet_cidr, cidrsubnet(var.address_space, 4, 1))
  database_subnet_cidr = coalesce(var.database_subnet_cidr, cidrsubnet(var.address_space, 4, 2))
  aks_subnet_cidr      = coalesce(var.aks_subnet_cidr, cidrsubnet(var.address_space, 2, 1))
}

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
  public_subnet_cidr   = local.public_subnet_cidr
  private_subnet_cidr  = local.private_subnet_cidr
  database_subnet_cidr = local.database_subnet_cidr
  aks_subnet_cidr      = local.aks_subnet_cidr

  # Optional configuration
  dns_servers            = var.dns_servers
  enable_nat_gateway     = var.enable_nat_gateway
  nat_idle_timeout       = var.nat_idle_timeout
  availability_zones     = var.availability_zones
  enable_ddos_protection = var.enable_ddos_protection
  tags                   = var.tags
}
