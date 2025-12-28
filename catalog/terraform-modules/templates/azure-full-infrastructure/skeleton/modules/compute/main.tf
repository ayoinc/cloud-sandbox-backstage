# =============================================================================
# COMPUTE MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "vm_size" { type = string; default = "Standard_D2s_v3" }
variable "vm_count" { type = number; default = 1 }
variable "os_type" { type = string; default = "linux" }
variable "subnet_id" { type = string; default = null }
variable "enable_auto_shutdown" { type = bool; default = false }
variable "auto_shutdown_schedule" { type = string; default = "0 19 * * 1-5" }

locals {
  vm_prefix = "vm-${var.project}-${var.environment}"
}

resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${local.vm_prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "main" {
  count               = var.os_type == "linux" ? var.vm_count : 0
  name                = "${local.vm_prefix}-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureadmin"

  network_interface_ids = [azurerm_network_interface.main[count.index].id]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

output "vm_ids" {
  value = var.os_type == "linux" ? azurerm_linux_virtual_machine.main[*].id : []
}

output "vm_private_ips" {
  value = azurerm_network_interface.main[*].private_ip_address
}
