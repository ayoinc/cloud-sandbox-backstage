variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "name" {
  description = "Name identifier for the firewall resources"
  type        = string
}

variable "sku_name" {
  description = "SKU name of the Firewall (AZFW_VNet or AZFW_Hub)"
  type        = string
  default     = "AZFW_VNet"

  validation {
    condition     = contains(["AZFW_VNet", "AZFW_Hub"], var.sku_name)
    error_message = "SKU name must be either AZFW_VNet or AZFW_Hub."
  }
}

variable "sku_tier" {
  description = "SKU tier of the Firewall (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be either Standard or Premium."
  }
}

variable "subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "zones" {
  description = "Availability zones for the firewall"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "threat_intel_mode" {
  description = "Threat intelligence mode (Alert, Deny, Off)"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.threat_intel_mode)
    error_message = "Threat intelligence mode must be Alert, Deny, or Off."
  }
}

variable "dns_servers" {
  description = "List of custom DNS servers"
  type        = list(string)
  default     = null
}

variable "dns_proxy_enabled" {
  description = "Enable DNS proxy on the firewall"
  type        = bool
  default     = false
}

variable "network_rule_collections" {
  description = "List of network rule collections"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      destination_addresses = optional(list(string))
      destination_ip_groups = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_ports     = list(string)
    }))
  }))
  default = []
}

variable "application_rule_collections" {
  description = "List of application rule collections"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name              = string
      source_addresses  = optional(list(string))
      source_ip_groups  = optional(list(string))
      destination_fqdns = optional(list(string))
      protocols = list(object({
        type = string
        port = number
      }))
    }))
  }))
  default = []
}

variable "nat_rule_collections" {
  description = "List of NAT rule collections"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                = string
      protocols           = list(string)
      source_addresses    = optional(list(string))
      source_ip_groups    = optional(list(string))
      destination_address = string
      destination_ports   = list(string)
      translated_address  = string
      translated_port     = number
    }))
  }))
  default = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
