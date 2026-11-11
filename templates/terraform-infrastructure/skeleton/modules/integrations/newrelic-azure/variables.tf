variable "name_prefix" {
  description = "Prefix for the names of all resources: up to 24 lowercase letters, digits and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,24}$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 characters of lowercase letters, digits and hyphens."
  }
}

variable "tags" {
  description = "Tags of the stack. Entra ID objects have no key/value tags, so they are recorded in the notes of the app registration."
  type        = map(string)
}

variable "newrelic_account_id" {
  description = "ID of the New Relic account to link. null uses the account the newrelic provider is configured for (NEW_RELIC_ACCOUNT_ID)."
  type        = number
  default     = null
}
