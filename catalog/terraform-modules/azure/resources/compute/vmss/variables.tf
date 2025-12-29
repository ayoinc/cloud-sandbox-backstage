variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "vmss_name" {
  description = "The name of the Virtual Machine Scale Set"
  type        = string
}

variable "sku" {
  description = "The SKU/size of the virtual machines in the scale set"
  type        = string
  default     = "Standard_B2s"
}

variable "instances" {
  description = "The initial number of instances in the scale set"
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "The admin username for the virtual machines"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "The SSH public key for admin authentication"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet where the VMSS will be deployed"
  type        = string
}

variable "source_image_reference" {
  description = "The source image reference for the virtual machines"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "os_disk_storage_type" {
  description = "The storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "The size of the OS disk in GB"
  type        = number
  default     = 30
}

variable "data_disks" {
  description = "List of data disks to attach to the virtual machines"
  type = list(object({
    lun          = number
    size_gb      = number
    storage_type = string
  }))
  default = []
}

variable "enable_autoscale" {
  description = "Enable autoscaling for the VMSS"
  type        = bool
  default     = true
}

variable "min_instances" {
  description = "The minimum number of instances for autoscaling"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "The maximum number of instances for autoscaling"
  type        = number
  default     = 10
}

variable "scale_out_cpu_threshold" {
  description = "The CPU percentage threshold to trigger scale out"
  type        = number
  default     = 75
}

variable "scale_in_cpu_threshold" {
  description = "The CPU percentage threshold to trigger scale in"
  type        = number
  default     = 25
}

variable "health_probe_id" {
  description = "The ID of the load balancer health probe for health monitoring"
  type        = string
  default     = null
}

variable "enable_automatic_instance_repair" {
  description = "Enable automatic instance repair when instances are unhealthy"
  type        = bool
  default     = false
}

variable "enable_system_identity" {
  description = "Enable system-assigned managed identity for the VMSS"
  type        = bool
  default     = true
}

variable "custom_data" {
  description = "Custom data script to run on instance initialization"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
