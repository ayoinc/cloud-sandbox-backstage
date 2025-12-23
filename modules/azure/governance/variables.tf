variable "management_groups" {
  type = map(object({
    display_name               = string
    parent_management_group_id = optional(string)
  }))
  default = {}
}

variable "policy_definitions" {
  type = map(object({
    mode                = optional(string, "All")
    display_name        = string
    description         = optional(string)
    management_group_id = optional(string)
    policy_rule         = string
    parameters          = optional(string)
    metadata            = optional(string)
  }))
  default = {}
}

variable "policy_set_definitions" {
  type = map(object({
    display_name        = string
    description         = optional(string)
    management_group_id = optional(string)
    parameters          = optional(string)
    metadata            = optional(string)
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = optional(string)
      reference_id         = optional(string)
    }))
  }))
  default = {}
}

variable "management_group_policy_assignments" {
  type = map(object({
    management_group_id  = string
    policy_definition_id = string
    display_name         = optional(string)
    description          = optional(string)
    enforce              = optional(bool, true)
    location             = optional(string)
    parameters           = optional(string)
    not_scopes           = optional(list(string), [])
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    non_compliance_messages = optional(list(object({
      content                        = string
      policy_definition_reference_id = optional(string)
    })), [])
  }))
  default = {}
}

variable "subscription_policy_assignments" {
  type = map(object({
    subscription_id      = string
    policy_definition_id = string
    display_name         = optional(string)
    description          = optional(string)
    enforce              = optional(bool, true)
    location             = optional(string)
    parameters           = optional(string)
    not_scopes           = optional(list(string), [])
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    non_compliance_messages = optional(list(object({
      content                        = string
      policy_definition_reference_id = optional(string)
    })), [])
  }))
  default = {}
}

variable "resource_group_policy_assignments" {
  type = map(object({
    resource_group_id    = string
    policy_definition_id = string
    display_name         = optional(string)
    description          = optional(string)
    enforce              = optional(bool, true)
    location             = optional(string)
    parameters           = optional(string)
    not_scopes           = optional(list(string), [])
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    non_compliance_messages = optional(list(object({
      content                        = string
      policy_definition_reference_id = optional(string)
    })), [])
  }))
  default = {}
}

variable "management_group_remediations" {
  type = map(object({
    management_group_id     = string
    policy_assignment_id    = string
    policy_definition_id    = optional(string)
    location_filters        = optional(list(string))
    resource_discovery_mode = optional(string, "ExistingNonCompliant")
  }))
  default = {}
}

variable "subscription_remediations" {
  type = map(object({
    subscription_id                = string
    policy_assignment_id           = string
    policy_definition_reference_id = optional(string)
    location_filters               = optional(list(string))
    resource_discovery_mode        = optional(string, "ExistingNonCompliant")
  }))
  default = {}
}

variable "resource_group_remediations" {
  type = map(object({
    resource_group_id              = string
    policy_assignment_id           = string
    policy_definition_reference_id = optional(string)
    location_filters               = optional(list(string))
    resource_discovery_mode        = optional(string, "ExistingNonCompliant")
  }))
  default = {}
}

variable "subscription_associations" {
  type = map(object({
    management_group_id = string
    subscription_id     = string
  }))
  default = {}
}

variable "management_group_role_assignments" {
  type = map(object({
    management_group_id  = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    principal_id         = string
    principal_type       = optional(string)
  }))
  default = {}
}
