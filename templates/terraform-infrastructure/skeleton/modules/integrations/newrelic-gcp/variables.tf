variable "name_prefix" {
  description = "Prefix for the names of all resources: up to 24 lowercase letters, digits and hyphens, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 characters of lowercase letters, digits and hyphens and start with a letter."
  }
}

variable "tags" {
  description = "Tags of the stack. Service accounts carry no labels, so they are recorded in the description of the service account."
  type        = map(string)
}

variable "project_id" {
  description = "ID of the Google Cloud project to monitor. null uses the project of the google provider configuration."
  type        = string
  default     = null
}

variable "newrelic_account_id" {
  description = "ID of the New Relic account to link. null uses the account the newrelic provider is configured for (NEW_RELIC_ACCOUNT_ID)."
  type        = number
  default     = null
}

variable "newrelic_region" {
  description = "Data centre region of the New Relic account (the region of the newrelic provider): US, EU or JP. It selects the OpenID Connect issuer Google trusts."
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU", "JP"], var.newrelic_region)
    error_message = "newrelic_region must be US, EU or JP."
  }
}
