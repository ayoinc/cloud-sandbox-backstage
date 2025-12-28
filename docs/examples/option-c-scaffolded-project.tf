# Example: What a scaffolded Azure VNet project looks like with Option C
# The template generates THIS - lightweight orchestration referencing external modules

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate${var.project}"
    container_name       = "tfstate"
    key                  = "${var.project}-vnet.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# =============================================================================
# SHARED MODULES (from central registry)
# =============================================================================
module "naming" {
  source = "git::https://github.com/your-org/terraform-modules.git//shared/naming?ref=v1.0.0"

  project       = var.project
  environment   = var.environment
  component     = "network"
  provider_type = "azure"
}

module "tagging" {
  source = "git::https://github.com/your-org/terraform-modules.git//shared/tagging?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  managed_by  = "terraform"
  extra_tags  = var.tags
}

# =============================================================================
# INFRASTRUCTURE MODULES (from central registry)
# =============================================================================

# Virtual Network
module "vnet" {
  source = "git::https://github.com/your-org/terraform-modules.git//azure/vnet?ref=v1.0.0"

  name                = module.naming.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  
  subnets = var.subnets
  
  tags = module.tagging.tags
}

# Network Security Groups (optional)
module "nsg" {
  source = "git::https://github.com/your-org/terraform-modules.git//azure/nsg?ref=v1.0.0"
  count  = var.enable_nsg ? 1 : 0

  name                = "${module.naming.name}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  security_rules = var.security_rules
  
  tags = module.tagging.tags
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "vnet_id" {
  value = module.vnet.id
}

output "vnet_name" {
  value = module.vnet.name
}

output "subnet_ids" {
  value = module.vnet.subnet_ids
}
