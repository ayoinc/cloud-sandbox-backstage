variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where Front Door will be created"
  type        = string
}

variable "profile_name" {
  description = "The name of the Front Door profile"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the Front Door profile. Valid values are Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "The sku_name must be either Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "endpoints" {
  description = "List of Front Door endpoints to create"
  type = list(object({
    name    = string
    enabled = bool
  }))
}

variable "origin_groups" {
  description = "List of origin groups with health probe and load balancing configuration"
  type = list(object({
    name                     = string
    session_affinity_enabled = bool
    health_probe = object({
      interval_in_seconds = number
      path                = string
      protocol            = string
      request_type        = string
    })
    load_balancing = object({
      additional_latency_in_milliseconds = number
      sample_size                        = number
      successful_samples_required        = number
    })
  }))
}

variable "origins" {
  description = "List of origins to create within origin groups"
  type = list(object({
    name                           = string
    origin_group_name              = string
    host_name                      = string
    http_port                      = number
    https_port                     = number
    certificate_name_check_enabled = bool
    enabled                        = bool
    priority                       = number
    weight                         = number
  }))
}

variable "routes" {
  description = "List of routes to create"
  type = list(object({
    name                   = string
    endpoint_name          = string
    origin_group_name      = string
    origin_names           = list(string)
    patterns_to_match      = list(string)
    supported_protocols    = list(string)
    forwarding_protocol    = string
    https_redirect_enabled = bool
    cache_enabled          = bool
  }))
}

variable "custom_domains" {
  description = "List of custom domains to associate with Front Door"
  type = list(object({
    name        = string
    host_name   = string
    dns_zone_id = string
  }))
  default = []
}

variable "waf_policy_id" {
  description = "The ID of the WAF policy to associate with the Front Door profile"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
