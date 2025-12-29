variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}

variable "source_image_reference" {
  description = "Source image reference for Marketplace images"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "custom_image_id" {
  description = "Resource ID of a custom image to use instead of Marketplace image"
  type        = string
  default     = null
}

variable "os_disk_storage_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 127
}

variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadWrite"
}

variable "subnet_id" {
  description = "Resource ID of the subnet for the network interface"
  type        = string
}

variable "private_ip_address_allocation" {
  description = "Private IP address allocation method (Dynamic or Static)"
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "Static private IP address (required when private_ip_address_allocation is Static)"
  type        = string
  default     = null
}

variable "public_ip_address_id" {
  description = "Resource ID of a public IP address to associate with the VM"
  type        = string
  default     = null
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the network interface"
  type        = bool
  default     = false
}

variable "zone" {
  description = "Availability zone for the VM"
  type        = string
  default     = null
}

variable "enable_boot_diagnostics" {
  description = "Enable boot diagnostics for the VM"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics (uses managed storage if not specified)"
  type        = string
  default     = null
}

variable "enable_system_identity" {
  description = "Enable system-assigned managed identity"
  type        = bool
  default     = true
}

variable "enable_antimalware" {
  description = "Enable Microsoft Antimalware extension"
  type        = bool
  default     = true
}

variable "data_disks" {
  description = "List of data disks to attach to the VM"
  type = list(object({
    name         = string
    size_gb      = number
    storage_type = string
    caching      = string
    lun          = number
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
