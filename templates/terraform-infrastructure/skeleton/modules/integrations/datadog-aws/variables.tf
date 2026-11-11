variable "name_prefix" {
  description = "Prefix for the names of all resources: up to 24 lowercase letters, digits and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,24}$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 characters of lowercase letters, digits and hyphens."
  }
}

variable "tags" {
  description = "Tags for the IAM resources. They are also sent to Datadog as account tags (key:value) on every metric of the account."
  type        = map(string)
}

variable "datadog_site" {
  description = "Datadog site of the organisation the provider is configured for. It selects the Datadog AWS account that is trusted to assume the integration role."
  type        = string
  default     = "datadoghq.com"

  validation {
    condition = contains([
      "datadoghq.com", "datadoghq.eu", "us3.datadoghq.com", "us5.datadoghq.com",
      "ap1.datadoghq.com", "ap2.datadoghq.com", "uk1.datadoghq.com",
      "ddog-gov.com", "us2.ddog-gov.com",
    ], var.datadog_site)
    error_message = "datadog_site must be one of datadoghq.com, datadoghq.eu, us3.datadoghq.com, us5.datadoghq.com, ap1.datadoghq.com, ap2.datadoghq.com, uk1.datadoghq.com, ddog-gov.com, us2.ddog-gov.com."
  }
}
