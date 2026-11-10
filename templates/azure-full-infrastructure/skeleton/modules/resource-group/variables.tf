variable "name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource group"
  type        = map(string)
  default     = {}
}

variable "enable_delete_lock" {
  description = "Protect the resource group and its resources against deletion"
  type        = bool
  default     = false
}
