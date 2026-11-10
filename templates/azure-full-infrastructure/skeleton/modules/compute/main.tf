# =============================================================================
# Compute Module
# =============================================================================
# Linux virtual machines with private addresses only, SSH key sign-in and an
# optional daily shutdown.
# =============================================================================

locals {
  prefix = "${var.name}-${var.environment}"
  zones  = ["1", "2", "3"]

  ssh_public_key = coalesce(var.admin_ssh_public_key, tls_private_key.ssh.public_key_openssh)
}

# Used when no public key is supplied; the private key is a sensitive output.
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#trivy:ignore:AZU-0068 The compute subnet carries the network security group, which covers every interface in it
resource "azurerm_network_interface" "main" {
  count = var.vm_count

  name                = "nic-${local.prefix}-${count.index}"
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
  #checkov:skip=CKV2_AZURE_12:The machines hold no data of their own; keep state in the Storage and Database modules
  count = var.vm_count

  name                = "vm-${local.prefix}-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  zone                = var.enable_high_availability ? local.zones[count.index % length(local.zones)] : null

  network_interface_ids = [azurerm_network_interface.main[count.index].id]

  # SSH keys only, and no VM extensions
  admin_username                  = var.admin_username
  disable_password_authentication = true
  allow_extension_operations      = false
  encryption_at_host_enabled      = var.enable_host_encryption

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Serial console and boot logs in a storage account managed by Azure
  boot_diagnostics {}

  tags = var.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "main" {
  count = var.enable_auto_shutdown ? var.vm_count : 0

  virtual_machine_id    = azurerm_linux_virtual_machine.main[count.index].id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}
