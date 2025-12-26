# -----------------------------------------------------------------------------
# Azure Compute Module - Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VMSS instances"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID"
  type        = string
}

variable "vm_size" {
  description = "Virtual machine size/SKU"
  type        = string
  default     = "Standard_B2s"
}

variable "instances_min" {
  description = "Minimum number of VMSS instances"
  type        = number
  default     = 1
}

variable "instances_max" {
  description = "Maximum number of VMSS instances"
  type        = number
  default     = 5
}

variable "instances_default" {
  description = "Default number of VMSS instances"
  type        = number
  default     = 2
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key content (takes precedence over ssh_public_key_path)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (used if ssh_public_key is empty)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_public_ip" {
  description = "Enable public IP addresses for VMSS instances"
  type        = bool
  default     = false
}

variable "enable_automatic_os_upgrade" {
  description = "Enable automatic OS upgrades"
  type        = bool
  default     = false
}

variable "scale_out_cpu_threshold" {
  description = "CPU percentage threshold for scaling out"
  type        = number
  default     = 75
}

variable "scale_in_cpu_threshold" {
  description = "CPU percentage threshold for scaling in"
  type        = number
  default     = 25
}

variable "scale_out_memory_threshold_bytes" {
  description = "Available memory bytes threshold for scaling out (scales when memory drops below this)"
  type        = number
  default     = 1073741824 # 1 GB
}

variable "autoscale_notification_emails" {
  description = "Email addresses for autoscale notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
