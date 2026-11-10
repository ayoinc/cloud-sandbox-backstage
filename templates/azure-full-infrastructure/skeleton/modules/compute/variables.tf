variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Subnet the virtual machines are attached to"
  type        = string
}

variable "vm_count" {
  description = "Number of virtual machines"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Administrator user name"
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the administrator (null generates a key pair)"
  type        = string
  default     = null
}

variable "enable_high_availability" {
  description = "Spread the virtual machines over three availability zones"
  type        = bool
  default     = false
}

variable "enable_auto_shutdown" {
  description = "Shut the virtual machines down every day at auto_shutdown_time"
  type        = bool
  default     = false
}

variable "auto_shutdown_time" {
  description = "Daily shutdown time in UTC, as HHMM"
  type        = string
  default     = "1900"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Shutdown time must be HHMM in 24-hour notation, for example 1900."
  }
}

variable "enable_host_encryption" {
  description = "Encrypt temp disks and caches on the VM host (needs the EncryptionAtHost subscription feature)"
  type        = bool
  default     = false
}
