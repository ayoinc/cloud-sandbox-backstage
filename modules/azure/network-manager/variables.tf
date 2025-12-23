variable "tags" {
  type    = map(string)
  default = {}
}

variable "network_managers" {
  type = map(object({
    location            = string
    resource_group_name = string
    description         = optional(string)
    scope_accesses      = list(string)
    scope = object({
      management_group_ids = optional(list(string))
      subscription_ids     = optional(list(string))
    })
  }))
  default = {}
}

variable "network_groups" {
  type = map(object({
    network_manager_key = optional(string)
    network_manager_id  = optional(string)
    description         = optional(string)
  }))
  default = {}
}

variable "static_members" {
  type = map(object({
    network_group_key         = optional(string)
    network_group_id          = optional(string)
    target_virtual_network_id = string
  }))
  default = {}
}

variable "connectivity_configurations" {
  type = map(object({
    network_manager_key   = optional(string)
    network_manager_id    = optional(string)
    connectivity_topology = string
    description           = optional(string)
    global_mesh_enabled   = optional(bool, false)
    applies_to_groups = list(object({
      network_group_key   = optional(string)
      network_group_id    = optional(string)
      group_connectivity  = optional(string, "None")
      global_mesh_enabled = optional(bool, false)
      use_hub_gateway     = optional(bool, false)
    }))
    hub = optional(object({
      resource_id   = string
      resource_type = optional(string, "Microsoft.Network/virtualNetworks")
    }))
  }))
  default = {}
}

variable "security_admin_configurations" {
  type = map(object({
    network_manager_key                           = optional(string)
    network_manager_id                            = optional(string)
    description                                   = optional(string)
    apply_on_network_intent_policy_based_services = optional(list(string))
  }))
  default = {}
}

variable "admin_rule_collections" {
  type = map(object({
    security_admin_configuration_key = optional(string)
    security_admin_configuration_id  = optional(string)
    description                      = optional(string)
    network_group_keys               = list(string)
  }))
  default = {}
}

variable "admin_rules" {
  type = map(object({
    admin_rule_collection_key = optional(string)
    admin_rule_collection_id  = optional(string)
    action                    = string
    direction                 = string
    priority                  = number
    protocol                  = string
    description               = optional(string)
    source_port_ranges        = optional(list(string))
    destination_port_ranges   = optional(list(string))
    sources = optional(list(object({
      address_prefix_type = string
      address_prefix      = optional(string)
    })), [])
    destinations = optional(list(object({
      address_prefix_type = string
      address_prefix      = optional(string)
    })), [])
  }))
  default = {}
}

variable "connectivity_deployments" {
  type = map(object({
    network_manager_key = optional(string)
    network_manager_id  = optional(string)
    location            = string
    configuration_keys  = optional(list(string))
    configuration_ids   = optional(list(string))
  }))
  default = {}
}

variable "security_admin_deployments" {
  type = map(object({
    network_manager_key = optional(string)
    network_manager_id  = optional(string)
    location            = string
    configuration_keys  = optional(list(string))
    configuration_ids   = optional(list(string))
  }))
  default = {}
}
