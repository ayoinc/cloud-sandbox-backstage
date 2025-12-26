# Azure Infrastructure Module
# This module provisions Azure resources for the infrastructure stack

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg-${var.environment}"
  location = var.location

  tags = var.common_tags
}

{% if values.enable_networking %}
# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.common_tags
}

resource "azurerm_subnet" "private" {
  name                 = "${var.name_prefix}-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 0)]
}

resource "azurerm_subnet" "public" {
  name                 = "${var.name_prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 1)]
}
{% endif %}

{% if values.enable_kubernetes %}
# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.name_prefix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.name_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.min_nodes
    vm_size             = var.node_instance_type
    enable_auto_scaling = var.enable_autoscaling
    min_count           = var.enable_autoscaling ? var.min_nodes : null
    max_count           = var.enable_autoscaling ? var.max_nodes : null
    vnet_subnet_id      = azurerm_subnet.private.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = var.common_tags
}
{% endif %}

{% if values.enable_database %}
# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.name_prefix}-psql"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = "psqladmin"
  administrator_password = var.database_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = var.environment == "production" ? "GP_Standard_D4s_v3" : "B_Standard_B1ms"

  tags = var.common_tags
}
{% endif %}

{% if values.enable_storage %}
# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = replace("${var.name_prefix}${var.environment}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"

  tags = var.common_tags
}

resource "azurerm_storage_container" "main" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
{% endif %}

{% if values.enable_secrets_manager %}
# Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.name_prefix}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = var.environment == "production"

  tags = var.common_tags
}
{% endif %}

{% if values.enable_monitoring %}
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.common_tags
}
{% endif %}
