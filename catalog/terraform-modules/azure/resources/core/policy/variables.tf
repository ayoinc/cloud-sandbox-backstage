#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------
variable "project_name" {
  description = "The name of the project. Used for resource naming and tagging."
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 64
    error_message = "Project name must be between 1 and 64 characters."
  }
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "development", "staging", "uat", "prod", "production"], lower(var.environment))
    error_message = "Environment must be one of: dev, development, staging, uat, prod, production."
  }
}

#------------------------------------------------------------------------------
# Custom Policy Definitions
#------------------------------------------------------------------------------
variable "custom_policies" {
  description = <<-EOT
    List of custom policy definitions to create.
    - name: Unique name for the policy definition
    - display_name: Display name shown in Azure Portal
    - description: Description of what the policy does
    - mode: Policy mode (All, Indexed, Microsoft.Kubernetes.Data, etc.)
    - policy_rule: The policy rule definition (if/then structure)
    - parameters: Optional parameter definitions for the policy
    - metadata: Optional metadata for the policy
  EOT
  type = list(object({
    name         = string
    display_name = string
    description  = string
    mode         = string
    policy_rule  = any
    parameters   = optional(any)
    metadata     = optional(any)
  }))
  default = []

  validation {
    condition = alltrue([
      for policy in var.custom_policies :
      contains(["All", "Indexed", "Microsoft.Kubernetes.Data", "Microsoft.KeyVault.Data", "Microsoft.Network.Data"], policy.mode)
    ])
    error_message = "Policy mode must be one of: All, Indexed, Microsoft.Kubernetes.Data, Microsoft.KeyVault.Data, Microsoft.Network.Data."
  }
}

#------------------------------------------------------------------------------
# Policy Set Definitions (Initiatives)
#------------------------------------------------------------------------------
variable "policy_set_definitions" {
  description = <<-EOT
    List of policy set definitions (initiatives) to create.
    - name: Unique name for the policy set
    - display_name: Display name shown in Azure Portal
    - description: Description of the initiative
    - policy_definition_references: List of policy definitions to include in the set
      - policy_definition_id: ID of the policy definition (can be built-in or custom)
      - parameter_values: Optional parameter values to pass to the policy
      - reference_id: Unique reference ID within the set
  EOT
  type = list(object({
    name         = string
    display_name = string
    description  = string
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = optional(any)
      reference_id         = string
    }))
  }))
  default = []
}

#------------------------------------------------------------------------------
# Policy Assignments
#------------------------------------------------------------------------------
variable "policy_assignments" {
  description = <<-EOT
    List of policy assignments to create.
    - name: Unique name for the assignment
    - policy_definition_id: ID of the policy or policy set to assign
    - scope: Scope for the assignment (subscription, resource group, or management group ID)
    - parameters: Optional parameters to pass to the policy
    - enforce: Whether to enforce the policy (true) or audit only (false)
    - identity_type: Type of managed identity (SystemAssigned, UserAssigned, or null)
    - location: Location for the managed identity (required if identity_type is set)
  EOT
  type = list(object({
    name                 = string
    policy_definition_id = string
    scope                = string
    parameters           = optional(map(any))
    enforce              = optional(bool, true)
    identity_type        = optional(string)
    location             = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for assignment in var.policy_assignments :
      assignment.identity_type == null || contains(["SystemAssigned", "UserAssigned"], assignment.identity_type)
    ])
    error_message = "Identity type must be either 'SystemAssigned', 'UserAssigned', or null."
  }

  validation {
    condition = alltrue([
      for assignment in var.policy_assignments :
      assignment.identity_type == null || assignment.location != null
    ])
    error_message = "Location must be specified when identity_type is set."
  }
}

#------------------------------------------------------------------------------
# Remediation Settings
#------------------------------------------------------------------------------
variable "enable_remediation" {
  description = "Enable automatic remediation for non-compliant resources. Only applicable for policies with deployIfNotExists or modify effects."
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------
variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
