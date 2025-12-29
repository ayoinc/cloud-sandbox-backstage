# -----------------------------------------------------------------------------
# Azure Linux Virtual Machine Module
# -----------------------------------------------------------------------------
# Creates Linux VMs with managed disks, extensions, and monitoring
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_key" {
  description = "SSH public key for authentication"
  type = object({
    username   = string
    public_key = string
  })
  default = null
}

variable "admin_password" {
  description = "Admin password (use SSH key instead if possible)"
  type        = string
  default     = null
  sensitive   = true
}

variable "disable_password_authentication" {
  description = "Disable password authentication"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for the network interface"
  type        = string
}

variable "private_ip_address_allocation" {
  description = "Private IP allocation method"
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "Static private IP address"
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Create a public IP address"
  type        = bool
  default     = false
}

variable "public_ip_sku" {
  description = "SKU for public IP"
  type        = string
  default     = "Standard"
}

variable "source_image_reference" {
  description = "Source image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "source_image_id" {
  description = "Custom image ID (overrides source_image_reference)"
  type        = string
  default     = null
}

variable "os_disk" {
  description = "OS disk configuration"
  type = object({
    caching                   = optional(string, "ReadWrite")
    storage_account_type      = optional(string, "Premium_LRS")
    disk_size_gb              = optional(number, 30)
    disk_encryption_set_id    = optional(string)
    write_accelerator_enabled = optional(bool, false)
  })
  default = {}
}

variable "data_disks" {
  description = "Additional data disks"
  type = list(object({
    name                      = string
    storage_account_type      = optional(string, "Premium_LRS")
    disk_size_gb              = number
    caching                   = optional(string, "ReadOnly")
    lun                       = number
    create_option             = optional(string, "Empty")
    disk_encryption_set_id    = optional(string)
    write_accelerator_enabled = optional(bool, false)
  }))
  default = []
}

variable "availability_set_id" {
  description = "Availability set ID"
  type        = string
  default     = null
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = null
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host"
  type        = bool
  default     = false
}

variable "secure_boot_enabled" {
  description = "Enable secure boot"
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Enable vTPM"
  type        = bool
  default     = true
}

variable "identity" {
  description = "Managed identity configuration"
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics"
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Custom data for cloud-init (base64 encoded)"
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "Network security group ID to associate with NIC"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Public IP (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.public_ip_sku
  zones               = var.zone != null ? [var.zone] : null

  tags = merge(var.tags, {
    Name = "${var.name}-pip"
  })
}

# -----------------------------------------------------------------------------
# Network Interface
# -----------------------------------------------------------------------------

resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nic"
  })
}

# -----------------------------------------------------------------------------
# NSG Association (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_network_interface_security_group_association" "this" {
  count = var.network_security_group_id != null ? 1 : 0

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

# -----------------------------------------------------------------------------
# Linux Virtual Machine
# -----------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.disable_password_authentication

  network_interface_ids = [azurerm_network_interface.this.id]
  availability_set_id   = var.availability_set_id
  zone                  = var.zone

  encryption_at_host_enabled = var.encryption_at_host_enabled
  secure_boot_enabled        = var.secure_boot_enabled
  vtpm_enabled               = var.vtpm_enabled

  custom_data = var.custom_data

  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key != null ? [var.admin_ssh_key] : []
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  os_disk {
    name                      = "${var.name}-osdisk"
    caching                   = var.os_disk.caching
    storage_account_type      = var.os_disk.storage_account_type
    disk_size_gb              = var.os_disk.disk_size_gb
    disk_encryption_set_id    = var.os_disk.disk_encryption_set_id
    write_accelerator_enabled = var.os_disk.write_accelerator_enabled
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [var.source_image_reference] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  source_image_id = var.source_image_id

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      admin_password,
      custom_data
    ]
  }
}

# -----------------------------------------------------------------------------
# Data Disks
# -----------------------------------------------------------------------------

resource "azurerm_managed_disk" "data" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zone                = var.zone

  storage_account_type   = each.value.storage_account_type
  disk_size_gb           = each.value.disk_size_gb
  create_option          = each.value.create_option
  disk_encryption_set_id = each.value.disk_encryption_set_id

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  managed_disk_id           = azurerm_managed_disk.data[each.key].id
  virtual_machine_id        = azurerm_linux_virtual_machine.this.id
  lun                       = each.value.lun
  caching                   = each.value.caching
  write_accelerator_enabled = each.value.write_accelerator_enabled
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address"
  value       = var.create_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "network_interface_id" {
  description = "Network interface ID"
  value       = azurerm_network_interface.this.id
}

output "identity" {
  description = "Managed identity information"
  value       = var.identity != null ? azurerm_linux_virtual_machine.this.identity : null
}
