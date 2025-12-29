variable "feature_set" {
  description = "Feature set of the organization. Valid values are ALL or CONSOLIDATED_BILLING."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "Feature set must be either ALL or CONSOLIDATED_BILLING."
  }
}

variable "enabled_policy_types" {
  description = "List of Organizations policy types to enable. Valid values are AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, and TAG_POLICY."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]

  validation {
    condition = alltrue([
      for policy_type in var.enabled_policy_types : contains([
        "AISERVICES_OPT_OUT_POLICY",
        "BACKUP_POLICY",
        "SERVICE_CONTROL_POLICY",
        "TAG_POLICY"
      ], policy_type)
    ])
    error_message = "Invalid policy type. Valid values are AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, and TAG_POLICY."
  }
}

variable "aws_service_access_principals" {
  description = "List of AWS service principal names for which you want to enable integration with your organization."
  type        = list(string)
  default     = []
}

variable "organizational_units" {
  description = "List of organizational units to create."
  type = list(object({
    name      = string
    parent_id = optional(string)
  }))
  default = []
}

variable "accounts" {
  description = "List of member accounts to create or invite."
  type = list(object({
    name                       = string
    email                      = string
    parent_id                  = optional(string)
    iam_user_access_to_billing = optional(string, "ALLOW")
    role_name                  = optional(string, "OrganizationAccountAccessRole")
  }))
  default = []

  validation {
    condition = alltrue([
      for account in var.accounts : contains(["ALLOW", "DENY"], account.iam_user_access_to_billing)
    ])
    error_message = "iam_user_access_to_billing must be either ALLOW or DENY."
  }
}

variable "service_control_policies" {
  description = "List of service control policies to create and attach."
  type = list(object({
    name        = string
    description = optional(string, "")
    content     = string
    target_ids  = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
