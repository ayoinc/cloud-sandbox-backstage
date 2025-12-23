variable "tags" {
  type    = map(string)
  default = {}
}

variable "virtual_networks" {
  type = map(object({
    location                = string
    resource_group_name     = string
    address_space           = list(string)
    dns_servers             = optional(list(string))
    bgp_community           = optional(string)
    edge_zone               = optional(string)
    ddos_protection_plan_id = optional(string)
    encryption_enforcement  = optional(string)
  }))
  default = {}
}

variable "subnets" {
  type = map(object({
    resource_group_name                           = string
    virtual_network_name                          = optional(string)
    virtual_network_key                           = optional(string)
    address_prefixes                              = list(string)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    service_endpoints                             = optional(list(string))
    service_endpoint_policy_ids                   = optional(list(string))
    delegation = optional(object({
      name                       = string
      service_delegation_name    = string
      service_delegation_actions = optional(list(string))
    }))
  }))
  default = {}
}

variable "network_security_groups" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "network_security_rules" {
  type = map(object({
    priority                                   = number
    direction                                  = string
    access                                     = string
    protocol                                   = string
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
    resource_group_name                        = string
    network_security_group_name                = optional(string)
    network_security_group_key                 = optional(string)
    description                                = optional(string)
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  type = map(object({
    subnet_id                  = optional(string)
    subnet_key                 = optional(string)
    network_security_group_id  = optional(string)
    network_security_group_key = optional(string)
  }))
  default = {}
}

variable "application_security_groups" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "ddos_protection_plans" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "public_ips" {
  type = map(object({
    location                = string
    resource_group_name     = string
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    zones                   = optional(list(string))
    ip_version              = optional(string, "IPv4")
    idle_timeout_in_minutes = optional(number, 4)
    domain_name_label       = optional(string)
    reverse_fqdn            = optional(string)
    public_ip_prefix_id     = optional(string)
    edge_zone               = optional(string)
    ddos_protection_mode    = optional(string)
    ddos_protection_plan_id = optional(string)
  }))
  default = {}
}

variable "public_ip_prefixes" {
  type = map(object({
    location            = string
    resource_group_name = string
    prefix_length       = optional(number, 28)
    sku                 = optional(string, "Standard")
    zones               = optional(list(string))
    ip_version          = optional(string, "IPv4")
  }))
  default = {}
}

variable "nat_gateways" {
  type = map(object({
    location                = string
    resource_group_name     = string
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string))
  }))
  default = {}
}

variable "nat_gateway_public_ip_associations" {
  type = map(object({
    nat_gateway_id       = optional(string)
    nat_gateway_key      = optional(string)
    public_ip_address_id = optional(string)
    public_ip_key        = optional(string)
  }))
  default = {}
}

variable "nat_gateway_public_ip_prefix_associations" {
  type = map(object({
    nat_gateway_id       = optional(string)
    nat_gateway_key      = optional(string)
    public_ip_prefix_id  = optional(string)
    public_ip_prefix_key = optional(string)
  }))
  default = {}
}

variable "subnet_nat_gateway_associations" {
  type = map(object({
    subnet_id       = optional(string)
    subnet_key      = optional(string)
    nat_gateway_id  = optional(string)
    nat_gateway_key = optional(string)
  }))
  default = {}
}

variable "route_tables" {
  type = map(object({
    location                      = string
    resource_group_name           = string
    bgp_route_propagation_enabled = optional(bool, true)
  }))
  default = {}
}

variable "routes" {
  type = map(object({
    resource_group_name    = string
    route_table_name       = optional(string)
    route_table_key        = optional(string)
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}
}

variable "subnet_route_table_associations" {
  type = map(object({
    subnet_id       = optional(string)
    subnet_key      = optional(string)
    route_table_id  = optional(string)
    route_table_key = optional(string)
  }))
  default = {}
}

variable "network_watchers" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "flow_logs" {
  type = map(object({
    network_watcher_name       = optional(string)
    network_watcher_key        = optional(string)
    resource_group_name        = string
    network_security_group_id  = optional(string)
    network_security_group_key = optional(string)
    storage_account_id         = string
    enabled                    = optional(bool, true)
    version                    = optional(number, 2)
    retention_policy = object({
      enabled = bool
      days    = number
    })
    traffic_analytics = optional(object({
      enabled               = bool
      workspace_id          = string
      workspace_region      = string
      workspace_resource_id = string
      interval_in_minutes   = optional(number, 10)
    }))
  }))
  default = {}
}

variable "virtual_network_peerings" {
  type = map(object({
    resource_group_name          = string
    virtual_network_name         = optional(string)
    virtual_network_key          = optional(string)
    remote_virtual_network_id    = string
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    triggers                     = optional(map(string))
  }))
  default = {}
}

variable "ip_groups" {
  type = map(object({
    location            = string
    resource_group_name = string
    cidrs               = list(string)
  }))
  default = {}
}

variable "service_endpoint_policies" {
  type = map(object({
    location            = string
    resource_group_name = string
  }))
  default = {}
}

variable "service_endpoint_policy_definitions" {
  type = map(object({
    service_endpoint_policy_id  = optional(string)
    service_endpoint_policy_key = optional(string)
    service                     = string
    service_resources           = list(string)
    description                 = optional(string)
  }))
  default = {}
}
