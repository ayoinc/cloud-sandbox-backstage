# -----------------------------------------------------------------------------
# Azure Compute Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
  }
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
  description = "ID of the subnet the scale set instances join"
  type        = string

  validation {
    condition     = var.subnet_id != null
    error_message = "subnet_id is required: enable the network module or pass the ID of an existing subnet."
  }
}

# -----------------------------------------------------------------------------
# Virtual Machines
# -----------------------------------------------------------------------------

variable "vm_size" {
  description = "Virtual machine size/SKU"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "source_image" {
  description = "Marketplace image for the instances. cloud-init expects an Ubuntu or Debian based generation 2 image"
  type = object({
    publisher = optional(string, "Canonical")
    offer     = optional(string, "ubuntu-24_04-lts")
    sku       = optional(string, "server")
    version   = optional(string, "latest")
  })
  nullable = false
  default  = {}
}

variable "zones" {
  description = "Availability zones to spread instances across. Empty deploys regionally, which works in every region"
  type        = list(string)
  nullable    = false
  default     = []
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
  description = "Initial number of VMSS instances and autoscale fallback when metrics are unavailable"
  type        = number
  default     = 2
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 4095
    error_message = "OS disk size must be between 30 and 4095 GB."
  }
}

variable "os_disk_storage_account_type" {
  description = "OS disk type. Premium_LRS needs a VM size with premium storage support"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS"], var.os_disk_storage_account_type)
    error_message = "OS disk type must be one of: Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_LRS, Premium_ZRS."
  }
}

variable "enable_trusted_launch" {
  description = "Enable secure boot and a virtual TPM (the image and VM size must support trusted launch)"
  type        = bool
  default     = true
}

variable "enable_encryption_at_host" {
  description = "Encrypt temp disks and caches on the VM host. Requires the Microsoft.Compute/EncryptionAtHost feature to be registered on the subscription"
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_username)) && !contains(["admin", "administrator", "root", "user", "guest", "test"], var.admin_username)
    error_message = "Admin username must be a valid Linux user name and not a reserved name such as admin or root."
  }
}

variable "ssh_public_key" {
  description = "SSH public key (OpenSSH format) for the admin user. When null or empty, a 4096-bit RSA key pair is generated and its private key is returned in the ssh_private_key output and stored in the Terraform state"
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_key == null || var.ssh_public_key == "" || can(regex("^ssh-rsa AAAA", var.ssh_public_key))
    error_message = "Azure accepts only RSA public keys in OpenSSH format (ssh-rsa AAAA...)."
  }
}

# -----------------------------------------------------------------------------
# Network Access
# -----------------------------------------------------------------------------

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access. Empty closes SSH"
  type        = list(string)
  nullable    = false
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "Each SSH entry must be a valid CIDR block and must not be a /0 range."
  }
}

variable "ingress_allowed_cidrs" {
  description = "CIDR blocks allowed to reach ingress_ports. Empty closes the application ports"
  type        = list(string)
  nullable    = false
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition     = alltrue([for cidr in var.ingress_allowed_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "Each ingress entry must be a valid CIDR block and must not be a /0 range."
  }
}

variable "ingress_ports" {
  description = "TCP ports opened to ingress_allowed_cidrs"
  type        = list(number)
  nullable    = false
  default     = [80, 443]

  validation {
    condition     = alltrue([for port in var.ingress_ports : port >= 1 && port <= 65535])
    error_message = "Ports must be between 1 and 65535."
  }
}

variable "health_check_port" {
  description = "Port of the HTTP health endpoint that cloud-init starts and the health extension probes at /health"
  type        = number
  default     = 80

  validation {
    condition     = var.health_check_port >= 1 && var.health_check_port <= 65535
    error_message = "Health check port must be between 1 and 65535."
  }
}

variable "enable_public_ip" {
  description = "Enable public IP addresses for VMSS instances"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Upgrades, Scaling and Monitoring
# -----------------------------------------------------------------------------

variable "enable_automatic_os_upgrade" {
  description = "Roll new OS image versions out automatically, guided by instance health"
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
  default     = 1073741824
}

variable "autoscale_notification_emails" {
  description = "Email addresses for autoscale notifications"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "data_collection_rule_id" {
  description = "ID of an Azure Monitor data collection rule to associate with the scale set. Null installs the monitor agent without a rule"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
