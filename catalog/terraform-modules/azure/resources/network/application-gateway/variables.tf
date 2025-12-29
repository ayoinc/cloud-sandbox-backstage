variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "name" {
  description = "The name of the Application Gateway"
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the Application Gateway"
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  description = "The SKU tier of the Application Gateway"
  type        = string
  default     = "WAF_v2"
}

variable "capacity" {
  description = "The capacity (number of instances) of the Application Gateway when autoscaling is disabled"
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the Application Gateway"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 10
}

variable "subnet_id" {
  description = "The ID of the subnet for the Application Gateway"
  type        = string
}

variable "public_ip_address_id" {
  description = "The ID of the public IP address for the Application Gateway"
  type        = string
}

variable "frontend_ports" {
  description = "List of frontend ports for the Application Gateway"
  type = list(object({
    name = string
    port = number
  }))
}

variable "backend_address_pools" {
  description = "List of backend address pools"
  type = list(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "List of backend HTTP settings"
  type = list(object({
    name            = string
    port            = number
    protocol        = string
    cookie_affinity = optional(string, "Disabled")
    request_timeout = optional(number, 30)
    probe_name      = optional(string)
  }))
}

variable "http_listeners" {
  description = "List of HTTP listeners"
  type = list(object({
    name                           = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    ssl_certificate_name           = optional(string)
  }))
}

variable "request_routing_rules" {
  description = "List of request routing rules"
  type = list(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    priority                    = number
    url_path_map_name           = optional(string)
    redirect_configuration_name = optional(string)
  }))
}

variable "probes" {
  description = "List of health probes"
  type = list(object({
    name                = string
    protocol            = string
    path                = string
    host                = optional(string)
    interval            = optional(number, 30)
    timeout             = optional(number, 30)
    unhealthy_threshold = optional(number, 3)
  }))
  default = []
}

variable "ssl_certificates" {
  description = "List of SSL certificates"
  type = list(object({
    name     = string
    data     = optional(string)
    password = optional(string)
  }))
  default   = []
  sensitive = true
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Detection or Prevention)"
  type        = string
  default     = "Prevention"
}

variable "waf_rule_set_type" {
  description = "WAF rule set type"
  type        = string
  default     = "OWASP"
}

variable "waf_rule_set_version" {
  description = "WAF rule set version"
  type        = string
  default     = "3.2"
}

variable "url_path_maps" {
  description = "List of URL path maps for path-based routing"
  type = list(object({
    name                                = string
    default_backend_address_pool_name   = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_redirect_configuration_name = optional(string)
    path_rules = optional(list(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
    })), [])
  }))
  default = []
}

variable "redirect_configurations" {
  description = "List of redirect configurations"
  type = list(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool, true)
    include_query_string = optional(bool, true)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
  default     = {}
}
