# Azure Compute Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "linux_vmss" {
  description = "Map of Linux VM Scale Sets to create"
  type = map(object({
    sku            = string
    instances      = number
    admin_username = string
    ssh_public_key = string
    subnet_id      = string
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk_type                 = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number, 30)
    enable_public_ip             = optional(bool, false)
    lb_backend_pool_ids          = optional(list(string), [])
    enable_managed_identity      = optional(bool, true)
    user_assigned_identity_ids   = optional(list(string))
    boot_diagnostics_storage_uri = optional(string)
    custom_data                  = optional(string)
    zones                        = optional(list(string), ["1", "2", "3"])
    autoscale = optional(object({
      default_instances       = number
      min_instances           = number
      max_instances           = number
      scale_out_cpu_threshold = number
      scale_out_count         = number
      scale_in_cpu_threshold  = number
      scale_in_count          = number
    }))
  }))
  default = {}
}

variable "windows_vmss" {
  description = "Map of Windows VM Scale Sets to create"
  type = map(object({
    sku            = string
    instances      = number
    admin_username = string
    admin_password = string
    subnet_id      = string
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk_type                 = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number, 128)
    lb_backend_pool_ids          = optional(list(string), [])
    enable_managed_identity      = optional(bool, true)
    user_assigned_identity_ids   = optional(list(string))
    boot_diagnostics_storage_uri = optional(string)
    zones                        = optional(list(string), ["1", "2", "3"])
  }))
  default = {}
}

variable "linux_vms" {
  description = "Map of single Linux VMs to create"
  type = map(object({
    size           = string
    admin_username = string
    ssh_public_key = string
    subnet_id      = string
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk_type                 = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number, 30)
    private_ip                   = optional(string)
    public_ip_id                 = optional(string)
    enable_managed_identity      = optional(bool, true)
    user_assigned_identity_ids   = optional(list(string))
    boot_diagnostics_storage_uri = optional(string)
    custom_data                  = optional(string)
    zone                         = optional(string)
  }))
  default = {}
}

variable "windows_vms" {
  description = "Map of single Windows VMs to create"
  type = map(object({
    size           = string
    admin_username = string
    admin_password = string
    subnet_id      = string
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    os_disk_type                 = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number, 128)
    private_ip                   = optional(string)
    public_ip_id                 = optional(string)
    enable_managed_identity      = optional(bool, true)
    user_assigned_identity_ids   = optional(list(string))
    boot_diagnostics_storage_uri = optional(string)
    zone                         = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
