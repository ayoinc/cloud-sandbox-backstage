# -----------------------------------------------------------------------------
# Virtual machine: Linux VM in the private subnet without a public IP
# address, stopped every day outside production
# -----------------------------------------------------------------------------

variable "vm_size" {
  description = "Size of the virtual machine."
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "auto_shutdown_schedule" {
  description = "Cron expression (minute hour * * weekdays, UTC) for stopping the virtual machine outside production. Azure stops the machine every day at that time and ignores the weekdays. Null disables it."
  type        = string
  default     = null

  validation {
    condition     = var.auto_shutdown_schedule == null || can(regex("^[0-5]?[0-9] ([01]?[0-9]|2[0-3]) \\* \\* (\\*|[0-6](-[0-6])?(,[0-6](-[0-6])?)*)$", var.auto_shutdown_schedule))
    error_message = "auto_shutdown_schedule must be a cron expression of the form \"minute hour * * weekdays\", for example \"0 19 * * 1-5\"."
  }
}

locals {
  # Azure's shutdown schedule runs daily at a fixed time, so only the minute
  # and the hour of the cron expression are used: "0 19 * * 1-5" becomes 1900.
  shutdown_fields = var.auto_shutdown_schedule == null ? [] : split(" ", var.auto_shutdown_schedule)
  shutdown_time   = length(local.shutdown_fields) == 0 ? null : format("%02d%02d", tonumber(local.shutdown_fields[1]), tonumber(local.shutdown_fields[0]))

  vm_auto_shutdown_enabled = var.environment != "production" && var.auto_shutdown_schedule != null
}

# The key pair lives in the Terraform state; read the private key with
# `terraform output -raw vm_ssh_private_key`.
resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "vm" {
  name                = "${module.naming.standard["vm"]}-nic"
  resource_group_name = local.resource_group_name
  location            = var.region

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = module.tagging.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = module.naming.standard["vm"]
  computer_name       = substr(replace(var.component_name, "-", ""), 0, 15)
  resource_group_name = local.resource_group_name
  location            = var.region
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.vm.id]

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = module.tagging.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  virtual_machine_id    = azurerm_linux_virtual_machine.this.id
  location              = var.region
  enabled               = true
  daily_recurrence_time = local.shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = module.tagging.tags
}

output "vm_id" {
  description = "Resource ID of the virtual machine."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_ssh_private_key" {
  description = "Private SSH key of the user `azureuser`."
  value       = tls_private_key.vm.private_key_openssh
  sensitive   = true
}
