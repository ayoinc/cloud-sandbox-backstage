# -----------------------------------------------------------------------------
# Azure Compute Module - Main Resources
# -----------------------------------------------------------------------------

# Data source for latest Ubuntu 22.04 LTS image
data "azurerm_platform_image" "ubuntu" {
  location  = var.location
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
}

# User Assigned Managed Identity for VMSS
resource "azurerm_user_assigned_identity" "vmss" {
  name                = "${var.project}-${var.environment}-vmss-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Role Assignment for Managed Identity (Reader on Resource Group)
resource "azurerm_role_assignment" "vmss_reader" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.vmss.principal_id
}

# Data source for current subscription
data "azurerm_subscription" "current" {}

# Network Security Group for Virtual Machines
resource "azurerm_network_security_group" "vmss" {
  name                = "${var.project}-${var.environment}-vmss-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Allow SSH from internal networks
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
    description                = "Allow SSH access from internal networks"
  }

  # Allow HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTP traffic"
  }

  # Allow HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS traffic"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound traffic"
  }

  tags = var.tags
}

# Linux Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "${var.project}-${var.environment}-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.instances_default

  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb
  }

  network_interface {
    name                      = "${var.project}-${var.environment}-vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      dynamic "public_ip_address" {
        for_each = var.enable_public_ip ? [1] : []
        content {
          name = "${var.project}-${var.environment}-vmss-pip"
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vmss.id]
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
    project     = var.project
    environment = var.environment
  }))

  # Enable boot diagnostics with managed storage
  boot_diagnostics {
    storage_account_uri = null # Uses managed storage account
  }

  # Automatic OS upgrades
  automatic_os_upgrade_policy {
    disable_automatic_rollback  = false
    enable_automatic_os_upgrade = var.enable_automatic_os_upgrade
  }

  upgrade_mode = var.enable_automatic_os_upgrade ? "Automatic" : "Manual"

  # Rolling upgrade policy (required when upgrade_mode is Automatic)
  dynamic "rolling_upgrade_policy" {
    for_each = var.enable_automatic_os_upgrade ? [1] : []
    content {
      max_batch_instance_percent              = 20
      max_unhealthy_instance_percent          = 20
      max_unhealthy_upgraded_instance_percent = 20
      pause_time_between_batches              = "PT0S"
    }
  }

  # Health probe for rolling upgrades
  dynamic "extension" {
    for_each = var.enable_automatic_os_upgrade ? [1] : []
    content {
      name                       = "HealthExtension"
      publisher                  = "Microsoft.ManagedServices"
      type                       = "ApplicationHealthLinux"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true

      settings = jsonencode({
        protocol = "http"
        port     = 80
        path     = "/health"
      })
    }
  }

  # Azure Monitor Agent extension
  extension {
    name                       = "AzureMonitorLinuxAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type                       = "AzureMonitorLinuxAgent"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vmss"
  })

  lifecycle {
    ignore_changes = [instances]
  }
}

# Autoscale Settings for VMSS
resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${var.project}-${var.environment}-vmss-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "default"

    capacity {
      default = var.instances_default
      minimum = var.instances_min
      maximum = var.instances_max
    }

    # Scale out rule - High CPU
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in rule - Low CPU
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale out rule - High Memory
    rule {
      metric_trigger {
        metric_name        = "Available Memory Bytes"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_out_memory_threshold_bytes
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = false
      custom_emails                         = var.autoscale_notification_emails
    }
  }

  tags = var.tags
}
