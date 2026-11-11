# -----------------------------------------------------------------------------
# Azure Compute Module - Main Resources
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  generate_ssh_key = var.ssh_public_key == null || var.ssh_public_key == ""
  ssh_public_key   = local.generate_ssh_key ? tls_private_key.ssh[0].public_key_openssh : var.ssh_public_key

  nsg_rules = merge(
    {
      for name, rule in {
        AllowSSH = {
          priority = 100
          ports    = ["22"]
          sources  = var.ssh_allowed_cidrs
        }
      } : name => rule if length(var.ssh_allowed_cidrs) > 0
    },
    {
      for name, rule in {
        AllowApplication = {
          priority = 200
          ports    = [for port in var.ingress_ports : tostring(port)]
          sources  = var.ingress_allowed_cidrs
        }
      } : name => rule if length(var.ingress_allowed_cidrs) > 0 && length(var.ingress_ports) > 0
    }
  )
}

# -----------------------------------------------------------------------------
# SSH key pair (generated when no public key is supplied)
# -----------------------------------------------------------------------------

resource "tls_private_key" "ssh" {
  count = local.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# -----------------------------------------------------------------------------
# Managed Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "vmss" {
  name                = "${local.name_prefix}-vmss-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Instances may read (not change) the resources of their own resource group.
resource "azurerm_role_assignment" "vmss_reader" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.vmss.principal_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Network Security Group
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "vmss" {
  name                = "${local.name_prefix}-vmss-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_network_security_rule" "allow" {
  for_each = local.nsg_rules

  name                        = each.key
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vmss.name

  priority                   = each.value.priority
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = each.value.ports
  source_address_prefixes    = each.value.sources
  destination_address_prefix = "*"
}

# Load balancer health probes originate from the AzureLoadBalancer tag.
resource "azurerm_network_security_rule" "allow_load_balancer" {
  name                        = "AllowAzureLoadBalancer"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vmss.name

  priority                   = 300
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "DenyAllInbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.vmss.name

  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# -----------------------------------------------------------------------------
# Linux Virtual Machine Scale Set
# -----------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                 = "${local.name_prefix}-vmss"
  computer_name_prefix = trimsuffix(substr(local.name_prefix, 0, 40), "-")
  resource_group_name  = var.resource_group_name
  location             = var.location
  sku                  = var.vm_size
  instances            = var.instances_default
  zones                = length(var.zones) > 0 ? var.zones : null

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  # Trusted launch protects the boot chain of generation 2 images.
  secure_boot_enabled        = var.enable_trusted_launch
  vtpm_enabled               = var.enable_trusted_launch
  encryption_at_host_enabled = var.enable_encryption_at_host

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb
  }

  network_interface {
    name                      = "${local.name_prefix}-vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      dynamic "public_ip_address" {
        for_each = var.enable_public_ip ? [1] : []

        content {
          name = "${local.name_prefix}-vmss-pip"
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vmss.id]
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
    project     = var.project_name
    environment = var.environment
    health_port = var.health_check_port
  }))

  # Boot diagnostics in a platform-managed storage account.
  boot_diagnostics {}

  upgrade_mode = var.enable_automatic_os_upgrade ? "Automatic" : "Manual"

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.enable_automatic_os_upgrade ? [1] : []

    content {
      disable_automatic_rollback  = false
      enable_automatic_os_upgrade = true
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = var.enable_automatic_os_upgrade ? [1] : []

    content {
      max_batch_instance_percent              = 20
      max_unhealthy_instance_percent          = 20
      max_unhealthy_upgraded_instance_percent = 20
      pause_time_between_batches              = "PT0S"
    }
  }

  # Reports instance health from the endpoint served by cloud-init; automatic
  # OS upgrades and instance repair rely on it.
  extension {
    name                       = "HealthExtension"
    publisher                  = "Microsoft.ManagedServices"
    type                       = "ApplicationHealthLinux"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true

    settings = jsonencode({
      protocol    = "http"
      port        = var.health_check_port
      requestPath = "/health"
    })
  }

  # The agent authenticates with the scale set's user-assigned identity.
  extension {
    name                       = "AzureMonitorLinuxAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type                       = "AzureMonitorLinuxAgent"
    type_handler_version       = "1.33"
    auto_upgrade_minor_version = true
    automatic_upgrade_enabled  = true

    settings = jsonencode({
      authentication = {
        managedIdentity = {
          "identifier-name"  = "mi_res_id"
          "identifier-value" = azurerm_user_assigned_identity.vmss.id
        }
      }
    })
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vmss"
  })

  lifecycle {
    # The autoscale setting owns the instance count after creation.
    ignore_changes = [instances]

    precondition {
      condition     = var.instances_min <= var.instances_default && var.instances_default <= var.instances_max
      error_message = "Instance counts must satisfy instances_min <= instances_default <= instances_max."
    }
    precondition {
      condition     = var.scale_in_cpu_threshold < var.scale_out_cpu_threshold
      error_message = "scale_in_cpu_threshold must be lower than scale_out_cpu_threshold."
    }
  }

  depends_on = [
    azurerm_network_security_rule.allow,
    azurerm_network_security_rule.allow_load_balancer,
    azurerm_network_security_rule.deny_all_inbound,
  ]
}

# Sends the data selected by a data collection rule through the monitor agent.
resource "azurerm_monitor_data_collection_rule_association" "vmss" {
  count = var.data_collection_rule_id != null ? 1 : 0

  name                    = "${local.name_prefix}-vmss-dcra"
  target_resource_id      = azurerm_linux_virtual_machine_scale_set.main.id
  data_collection_rule_id = var.data_collection_rule_id
}

# -----------------------------------------------------------------------------
# Autoscale Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${local.name_prefix}-vmss-autoscale"
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

  dynamic "notification" {
    for_each = length(var.autoscale_notification_emails) > 0 ? [1] : []

    content {
      email {
        custom_emails = var.autoscale_notification_emails
      }
    }
  }

  tags = var.tags
}
