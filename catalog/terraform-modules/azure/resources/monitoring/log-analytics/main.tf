# =============================================================================
# AZURE LOG ANALYTICS WORKSPACE MODULE
# =============================================================================
# Creates Log Analytics workspace with solutions and data collection
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "sku" {
  description = "SKU (Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018)"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily data ingestion quota in GB (-1 for unlimited)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Allow internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow internet queries"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation (CapacityReservation SKU only)"
  type        = number
  default     = null
}

variable "solutions" {
  description = "Solutions to deploy"
  type = list(object({
    solution_name = string
    publisher     = optional(string, "Microsoft")
    product       = string
  }))
  default = []
}

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = false
}

variable "enable_vm_insights" {
  description = "Enable VM Insights solution"
  type        = bool
  default     = false
}

variable "enable_security_center" {
  description = "Enable Security Center solution"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  workspace_name = "log-${var.project}-${var.environment}-${var.location}"

  # Environment-specific retention
  env_retention = {
    dev     = 30
    staging = 60
    prod    = 90
  }

  retention = lookup(local.env_retention, var.environment, 30)

  # Built-in solutions
  builtin_solutions = concat(
    var.enable_container_insights ? [{
      solution_name = "ContainerInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/ContainerInsights"
    }] : [],
    var.enable_vm_insights ? [{
      solution_name = "VMInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/VMInsights"
    }] : [],
    var.enable_security_center ? [{
      solution_name = "Security"
      publisher     = "Microsoft"
      product       = "OMSGallery/Security"
    }] : []
  )

  all_solutions = concat(local.builtin_solutions, var.solutions)
}

# -----------------------------------------------------------------------------
# Log Analytics Workspace
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                               = local.workspace_name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  sku                                = var.sku
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Solutions
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "solutions" {
  for_each = { for s in local.all_solutions : s.solution_name => s }

  solution_name         = each.value.solution_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_resource_id" {
  description = "Log Analytics Workspace resource ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "primary_shared_key" {
  description = "Primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "workspace_customer_id" {
  description = "Workspace customer ID (for agents)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}
