variable "name" {
  description = "Prefix of the resource names: <project>-<environment>."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.name))
    error_message = "The name must be 3 to 30 lowercase letters, numbers and hyphens, starting with a letter."
  }
}
{%- if values.cloud == 'aws' %}

variable "key_deletion_window_days" {
  description = "Days a deleted key can still be restored."
  type        = number
  default     = 30

  validation {
    condition     = var.key_deletion_window_days >= 7 && var.key_deletion_window_days <= 30
    error_message = "The deletion window must be between 7 and 30 days."
  }
}
{%- elif values.cloud == 'azure' %}

variable "region" {
  description = "Region the resources are created in."
  type        = string
}

variable "tags" {
  description = "Tags recorded on every resource."
  type        = map(string)
  default     = {}
}
{%- else %}

variable "region" {
  description = "Region the resources are created in."
  type        = string
}

variable "key_rotation_period" {
  description = "Rotation period of the key, in seconds with an s suffix."
  type        = string
  default     = "7776000s"
}
{%- endif %}
