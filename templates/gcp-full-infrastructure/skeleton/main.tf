# ${{ values.name }} - Azure Infrastructure

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
}

provider "azurerm" { features {} }

locals {
  name_prefix = "${{ values.name }}-${var.environment}"
  tags = {
    project     = "${{ values.name }}"
    environment = var.environment
    managed_by  = "terraform"
    owner       = "${{ values.owner }}"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

# External module references from central registry
{%- if values.enable_networking %}
module "networking" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/networking?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_aks %}
module "aks" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/aks?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.networking.subnet_ids["aks"]
  kubernetes_version  = var.kubernetes_version
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_acr %}
module "acr" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/acr?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_storage %}
module "storage" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/storage?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_keyvault %}
module "keyvault" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/keyvault?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_postgresql %}
module "postgresql" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/postgresql?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_redis %}
module "redis" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/redis?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}

{%- if values.enable_log_analytics %}
module "monitoring" {
  source  = "git::https://github.com/${{ values.module_registry }}/terraform-modules.git//azure/monitoring?ref=v1.0.0"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}
{%- endif %}
