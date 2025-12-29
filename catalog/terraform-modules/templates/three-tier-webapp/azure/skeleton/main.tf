terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "${{ values.projectName }}-tfstate-rg"
    storage_account_name = "${{ values.projectName | replace("-", "") }}tfstate"
    container_name       = "tfstate"
    key                  = "${{ values.environment }}/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

locals {
  name_prefix = "${{ values.projectName }}-${{ values.environment }}"
  
  common_tags = {
    Project     = "${{ values.projectName }}"
    Environment = "${{ values.environment }}"
    ManagedBy   = "terraform"
  }
}

# Resource Group
module "resource_group" {
  source = "../../azure/resources/core/resource-group"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  tags         = local.common_tags
}

# Virtual Network
module "virtual_network" {
  source = "../../azure/resources/network/virtual-network"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = [var.vnet_address_space]

  subnets = [
    { name = "app-gateway", address_prefix = cidrsubnet(var.vnet_address_space, 8, 0) },
    { name = "app", address_prefix = cidrsubnet(var.vnet_address_space, 8, 1) },
    { name = "database", address_prefix = cidrsubnet(var.vnet_address_space, 8, 2) }
  ]

  tags = local.common_tags
}

# Application Gateway
module "application_gateway" {
  source = "../../azure/resources/network/application-gateway"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  name                = "${local.name_prefix}-appgw"

  subnet_id            = module.virtual_network.subnet_ids["app-gateway"]
  public_ip_address_id = azurerm_public_ip.appgw.id

  sku_name = "WAF_v2"
  sku_tier = "WAF_v2"

  enable_waf  = ${{ values.enableWaf }}
  waf_mode    = "Prevention"

  frontend_ports = [
    { name = "http", port = 80 },
    { name = "https", port = 443 }
  ]

  backend_address_pools = [
    { name = "app-pool", fqdns = [], ip_addresses = [] }
  ]

  backend_http_settings = [
    { name = "http-settings", port = 80, protocol = "Http", cookie_affinity = "Disabled", request_timeout = 60 }
  ]

  http_listeners = [
    { name = "http-listener", frontend_ip_configuration_name = "frontend-ip", frontend_port_name = "http", protocol = "Http" }
  ]

  request_routing_rules = [
    { name = "rule-1", rule_type = "Basic", http_listener_name = "http-listener", backend_address_pool_name = "app-pool", backend_http_settings_name = "http-settings", priority = 100 }
  ]

  tags = local.common_tags
}

resource "azurerm_public_ip" "appgw" {
  name                = "${local.name_prefix}-appgw-pip"
  resource_group_name = module.resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

{%- if values.computeType == "aks" %}
# AKS Cluster
module "aks" {
  source = "../../azure/resources/kubernetes/aks"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  cluster_name        = "${local.name_prefix}-aks"

  kubernetes_version = var.kubernetes_version
  
  default_node_pool_vm_size   = var.vm_size
  default_node_pool_min_count = var.min_nodes
  default_node_pool_max_count = var.max_nodes
  default_node_pool_subnet_id = module.virtual_network.subnet_ids["app"]

  network_plugin = "azure"
  network_policy = "azure"

  tags = local.common_tags
}
{%- endif %}

{%- if values.computeType == "vmss" %}
# VM Scale Set
module "vmss" {
  source = "../../azure/resources/compute/vmss"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  vmss_name           = "${local.name_prefix}-vmss"

  sku          = var.vm_size
  instances    = var.min_nodes
  admin_username = var.admin_username

  subnet_id = module.virtual_network.subnet_ids["app"]

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  enable_autoscale    = true
  min_instances       = var.min_nodes
  max_instances       = var.max_nodes
  scale_out_cpu_threshold = 75
  scale_in_cpu_threshold  = 25

  tags = local.common_tags
}
{%- endif %}

{%- if values.computeType == "container-apps" %}
# Container Apps
module "container_app" {
  source = "../../azure/resources/compute/container-app"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location

  container_app_environment_name = "${local.name_prefix}-env"
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  container_app_name = "${local.name_prefix}-app"
  container_name     = "app"
  image              = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

  min_replicas = var.min_nodes
  max_replicas = var.max_nodes

  tags = local.common_tags
}
{%- endif %}

# Key Vault for secrets
module "key_vault" {
  source = "../../azure/resources/security/key-vault"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  tags = local.common_tags
}

data "azurerm_client_config" "current" {}

{%- if values.databaseType == "postgresql" %}
# PostgreSQL Flexible Server
module "postgresql" {
  source = "../../azure/resources/database/postgresql"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  server_name         = "${local.name_prefix}-psql"

  administrator_login    = var.database_admin_username
  administrator_password = var.database_admin_password

  sku_name   = var.database_sku
  storage_mb = 32768
  version    = "15"

  delegated_subnet_id = module.virtual_network.subnet_ids["database"]

  tags = local.common_tags
}
{%- endif %}

{%- if values.databaseType == "sql-database" %}
# Azure SQL Database
module "sql_database" {
  source = "../../azure/resources/database/sql-database"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location

  server_name              = "${local.name_prefix}-sql"
  administrator_login      = var.database_admin_username
  administrator_password   = var.database_admin_password

  database_name = replace(var.project_name, "-", "_")
  sku_name      = var.database_sku

  tags = local.common_tags
}
{%- endif %}

{%- if values.databaseType == "cosmos-db" %}
# Cosmos DB
module "cosmos_db" {
  source = "../../azure/resources/database/cosmos-db"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location
  account_name        = "${local.name_prefix}-cosmos"

  geo_locations = [
    { location = var.location, failover_priority = 0, zone_redundant = false }
  ]

  databases = [
    { name = replace(var.project_name, "-", "_"), throughput = 400, containers = [] }
  ]

  tags = local.common_tags
}
{%- endif %}

# Log Analytics
module "log_analytics" {
  source = "../../azure/resources/monitoring/log-analytics"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = local.common_tags
}

{%- if values.enableFrontDoor %}
# Azure Front Door
module "front_door" {
  source = "../../azure/resources/network/front-door"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name

  profile_name = "${local.name_prefix}-fd"
  sku_name     = "Standard_AzureFrontDoor"

  endpoints = [
    { name = "default", enabled = true }
  ]

  origin_groups = [
    { name = "app-origin", session_affinity_enabled = false }
  ]

  origins = [
    { name = "appgw", origin_group_name = "app-origin", host_name = azurerm_public_ip.appgw.ip_address, http_port = 80, https_port = 443, certificate_name_check_enabled = false, enabled = true, priority = 1, weight = 1000 }
  ]

  routes = [
    { name = "default-route", endpoint_name = "default", origin_group_name = "app-origin", origin_names = ["appgw"], patterns_to_match = ["/*"], supported_protocols = ["Http", "Https"], forwarding_protocol = "HttpOnly", https_redirect_enabled = true }
  ]

  tags = local.common_tags
}
{%- endif %}
