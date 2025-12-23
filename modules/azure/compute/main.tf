# Azure Compute Module
# Reusable module for creating Azure Virtual Machines, VM Scale Sets, and Azure Virtual Desktop

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

# Proximity Placement Groups
resource "azurerm_proximity_placement_group" "this" {
  for_each = var.proximity_placement_groups

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  allowed_vm_sizes    = each.value.allowed_vm_sizes
  zone                = each.value.zone
  tags                = var.tags
}

# Dedicated Host Groups
resource "azurerm_dedicated_host_group" "this" {
  for_each = var.dedicated_host_groups

  name                        = each.key
  location                    = var.location
  resource_group_name         = var.resource_group_name
  platform_fault_domain_count = each.value.platform_fault_domain_count
  automatic_placement_enabled = each.value.automatic_placement_enabled
  zone                        = each.value.zone
  tags                        = var.tags
}

# Dedicated Hosts
resource "azurerm_dedicated_host" "this" {
  for_each = var.dedicated_hosts

  name                    = each.key
  location                = var.location
  dedicated_host_group_id = azurerm_dedicated_host_group.this[each.value.host_group_key].id
  sku_name                = each.value.sku_name
  platform_fault_domain   = each.value.platform_fault_domain
  auto_replace_on_failure = each.value.auto_replace_on_failure
  license_type            = each.value.license_type
  tags                    = var.tags
}

# Availability Sets
resource "azurerm_availability_set" "this" {
  for_each = var.availability_sets

  name                         = each.key
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = each.value.platform_fault_domain_count
  platform_update_domain_count = each.value.platform_update_domain_count
  proximity_placement_group_id = each.value.proximity_placement_group_key != null ? azurerm_proximity_placement_group.this[each.value.proximity_placement_group_key].id : null
  managed                      = true
  tags                         = var.tags
}

# Capacity Reservation Groups
resource "azurerm_capacity_reservation_group" "this" {
  for_each = var.capacity_reservation_groups

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = each.value.zones
  tags                = var.tags
}

# Capacity Reservations
resource "azurerm_capacity_reservation" "this" {
  for_each = var.capacity_reservations

  name                          = each.key
  capacity_reservation_group_id = azurerm_capacity_reservation_group.this[each.value.capacity_reservation_group_key].id
  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
  zone = each.value.zone
  tags = var.tags
}

# Virtual Machine Scale Set (Linux)
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  for_each = var.linux_vmss

  name                            = each.key
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = each.value.sku
  instances                       = each.value.instances
  admin_username                  = each.value.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  os_disk {
    storage_account_type = each.value.os_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = each.value.os_disk_size_gb
  }

  network_interface {
    name    = "${each.key}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = each.value.subnet_id

      dynamic "public_ip_address" {
        for_each = each.value.enable_public_ip ? [1] : []
        content {
          name = "${each.key}-pip"
        }
      }

      load_balancer_backend_address_pool_ids = each.value.lb_backend_pool_ids
    }
  }

  dynamic "identity" {
    for_each = each.value.enable_managed_identity ? [1] : []
    content {
      type         = each.value.user_assigned_identity_ids != null ? "UserAssigned" : "SystemAssigned"
      identity_ids = each.value.user_assigned_identity_ids
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics_storage_uri
  }

  custom_data = each.value.custom_data

  zones = each.value.zones

  tags = var.tags

  lifecycle {
    ignore_changes = [instances]
  }
}

# Virtual Machine Scale Set (Windows)
resource "azurerm_windows_virtual_machine_scale_set" "this" {
  for_each = var.windows_vmss

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = each.value.sku
  instances           = each.value.instances
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  os_disk {
    storage_account_type = each.value.os_disk_type
    caching              = "ReadWrite"
    disk_size_gb         = each.value.os_disk_size_gb
  }

  network_interface {
    name    = "${each.key}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = each.value.subnet_id

      load_balancer_backend_address_pool_ids = each.value.lb_backend_pool_ids
    }
  }

  dynamic "identity" {
    for_each = each.value.enable_managed_identity ? [1] : []
    content {
      type         = each.value.user_assigned_identity_ids != null ? "UserAssigned" : "SystemAssigned"
      identity_ids = each.value.user_assigned_identity_ids
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics_storage_uri
  }

  zones = each.value.zones

  tags = var.tags

  lifecycle {
    ignore_changes = [instances]
  }
}

# Single Linux VM
resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.linux_vms

  name                            = each.key
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.linux[each.key].id]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  dynamic "identity" {
    for_each = each.value.enable_managed_identity ? [1] : []
    content {
      type         = each.value.user_assigned_identity_ids != null ? "UserAssigned" : "SystemAssigned"
      identity_ids = each.value.user_assigned_identity_ids
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics_storage_uri
  }

  custom_data = each.value.custom_data

  zone = each.value.zone

  tags = var.tags
}

# Network Interface for Linux VMs
resource "azurerm_network_interface" "linux" {
  for_each = var.linux_vms

  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip
    public_ip_address_id          = each.value.public_ip_id
  }

  tags = var.tags
}

# Single Windows VM
resource "azurerm_windows_virtual_machine" "this" {
  for_each = var.windows_vms

  name                  = each.key
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = each.value.size
  admin_username        = each.value.admin_username
  admin_password        = each.value.admin_password
  network_interface_ids = [azurerm_network_interface.windows[each.key].id]

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  dynamic "identity" {
    for_each = each.value.enable_managed_identity ? [1] : []
    content {
      type         = each.value.user_assigned_identity_ids != null ? "UserAssigned" : "SystemAssigned"
      identity_ids = each.value.user_assigned_identity_ids
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics_storage_uri
  }

  zone = each.value.zone

  tags = var.tags
}

# Network Interface for Windows VMs
resource "azurerm_network_interface" "windows" {
  for_each = var.windows_vms

  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip
    public_ip_address_id          = each.value.public_ip_id
  }

  tags = var.tags
}

# Autoscale Settings for VMSS
resource "azurerm_monitor_autoscale_setting" "linux" {
  for_each = { for k, v in var.linux_vmss : k => v if v.autoscale != null }

  name                = "${each.key}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this[each.key].id

  profile {
    name = "default"

    capacity {
      default = each.value.autoscale.default_instances
      minimum = each.value.autoscale.min_instances
      maximum = each.value.autoscale.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this[each.key].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = each.value.autoscale.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = each.value.autoscale.scale_out_count
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this[each.key].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = each.value.autoscale.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = each.value.autoscale.scale_in_count
        cooldown  = "PT5M"
      }
    }
  }
}

# NIC to Application Security Group Associations
resource "azurerm_network_interface_application_security_group_association" "linux" {
  for_each = var.linux_vm_asg_associations

  network_interface_id          = azurerm_network_interface.linux[each.value.vm_key].id
  application_security_group_id = each.value.application_security_group_id
}

resource "azurerm_network_interface_application_security_group_association" "windows" {
  for_each = var.windows_vm_asg_associations

  network_interface_id          = azurerm_network_interface.windows[each.value.vm_key].id
  application_security_group_id = each.value.application_security_group_id
}

# Azure Virtual Desktop Host Pool
resource "azurerm_virtual_desktop_host_pool" "this" {
  for_each = var.avd_host_pools

  name                             = each.key
  location                         = var.location
  resource_group_name              = var.resource_group_name
  type                             = each.value.type
  load_balancer_type               = each.value.load_balancer_type
  friendly_name                    = each.value.friendly_name
  description                      = each.value.description
  validate_environment             = each.value.validate_environment
  start_vm_on_connect              = each.value.start_vm_on_connect
  custom_rdp_properties            = each.value.custom_rdp_properties
  personal_desktop_assignment_type = each.value.personal_desktop_assignment_type
  maximum_sessions_allowed         = each.value.maximum_sessions_allowed
  preferred_app_group_type         = each.value.preferred_app_group_type

  dynamic "scheduled_agent_updates" {
    for_each = each.value.scheduled_agent_updates != null ? [each.value.scheduled_agent_updates] : []
    content {
      enabled                   = scheduled_agent_updates.value.enabled
      timezone                  = scheduled_agent_updates.value.timezone
      use_session_host_timezone = scheduled_agent_updates.value.use_session_host_timezone

      dynamic "schedule" {
        for_each = scheduled_agent_updates.value.schedules
        content {
          day_of_week = schedule.value.day_of_week
          hour_of_day = schedule.value.hour_of_day
        }
      }
    }
  }

  tags = var.tags
}

# AVD Host Pool Registration Token
resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  for_each = var.avd_host_pools

  hostpool_id     = azurerm_virtual_desktop_host_pool.this[each.key].id
  expiration_date = each.value.registration_expiration_date
}

# Azure Virtual Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "this" {
  for_each = var.avd_application_groups

  name                         = each.key
  location                     = var.location
  resource_group_name          = var.resource_group_name
  type                         = each.value.type
  host_pool_id                 = azurerm_virtual_desktop_host_pool.this[each.value.host_pool_key].id
  friendly_name                = each.value.friendly_name
  description                  = each.value.description
  default_desktop_display_name = each.value.default_desktop_display_name
  tags                         = var.tags
}

# Azure Virtual Desktop Workspace
resource "azurerm_virtual_desktop_workspace" "this" {
  for_each = var.avd_workspaces

  name                          = each.key
  location                      = var.location
  resource_group_name           = var.resource_group_name
  friendly_name                 = each.value.friendly_name
  description                   = each.value.description
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = var.tags
}

# AVD Workspace to Application Group Association
resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  for_each = var.avd_workspace_app_group_associations

  workspace_id         = azurerm_virtual_desktop_workspace.this[each.value.workspace_key].id
  application_group_id = azurerm_virtual_desktop_application_group.this[each.value.application_group_key].id
}

# Azure Virtual Desktop Application (RemoteApp)
resource "azurerm_virtual_desktop_application" "this" {
  for_each = var.avd_applications

  name                         = each.key
  application_group_id         = azurerm_virtual_desktop_application_group.this[each.value.application_group_key].id
  friendly_name                = each.value.friendly_name
  description                  = each.value.description
  path                         = each.value.path
  command_line_argument_policy = each.value.command_line_argument_policy
  command_line_arguments       = each.value.command_line_arguments
  show_in_portal               = each.value.show_in_portal
  icon_path                    = each.value.icon_path
  icon_index                   = each.value.icon_index
}

# AVD Scaling Plan
resource "azurerm_virtual_desktop_scaling_plan" "this" {
  for_each = var.avd_scaling_plans

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = each.value.friendly_name
  description         = each.value.description
  time_zone           = each.value.time_zone
  exclusion_tag       = each.value.exclusion_tag

  dynamic "schedule" {
    for_each = each.value.schedules
    content {
      name                                 = schedule.value.name
      days_of_week                         = schedule.value.days_of_week
      ramp_up_start_time                   = schedule.value.ramp_up_start_time
      ramp_up_load_balancing_algorithm     = schedule.value.ramp_up_load_balancing_algorithm
      ramp_up_minimum_hosts_percent        = schedule.value.ramp_up_minimum_hosts_percent
      ramp_up_capacity_threshold_percent   = schedule.value.ramp_up_capacity_threshold_percent
      peak_start_time                      = schedule.value.peak_start_time
      peak_load_balancing_algorithm        = schedule.value.peak_load_balancing_algorithm
      ramp_down_start_time                 = schedule.value.ramp_down_start_time
      ramp_down_load_balancing_algorithm   = schedule.value.ramp_down_load_balancing_algorithm
      ramp_down_minimum_hosts_percent      = schedule.value.ramp_down_minimum_hosts_percent
      ramp_down_force_logoff_users         = schedule.value.ramp_down_force_logoff_users
      ramp_down_wait_time_minutes          = schedule.value.ramp_down_wait_time_minutes
      ramp_down_notification_message       = schedule.value.ramp_down_notification_message
      ramp_down_capacity_threshold_percent = schedule.value.ramp_down_capacity_threshold_percent
      ramp_down_stop_hosts_when            = schedule.value.ramp_down_stop_hosts_when
      off_peak_start_time                  = schedule.value.off_peak_start_time
      off_peak_load_balancing_algorithm    = schedule.value.off_peak_load_balancing_algorithm
    }
  }

  dynamic "host_pool" {
    for_each = each.value.host_pool_keys
    content {
      hostpool_id          = azurerm_virtual_desktop_host_pool.this[host_pool.value].id
      scaling_plan_enabled = true
    }
  }

  tags = var.tags
}

# Shared Image Gallery
resource "azurerm_shared_image_gallery" "this" {
  for_each = var.shared_image_galleries

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = each.value.description

  dynamic "sharing" {
    for_each = each.value.sharing != null ? [each.value.sharing] : []
    content {
      permission = sharing.value.permission
      dynamic "community_gallery" {
        for_each = sharing.value.community_gallery != null ? [sharing.value.community_gallery] : []
        content {
          eula            = community_gallery.value.eula
          prefix          = community_gallery.value.prefix
          publisher_email = community_gallery.value.publisher_email
          publisher_uri   = community_gallery.value.publisher_uri
        }
      }
    }
  }

  tags = var.tags
}

# Shared Image Definition
resource "azurerm_shared_image" "this" {
  for_each = var.shared_images

  name                                = each.key
  gallery_name                        = azurerm_shared_image_gallery.this[each.value.gallery_key].name
  resource_group_name                 = var.resource_group_name
  location                            = var.location
  os_type                             = each.value.os_type
  hyper_v_generation                  = each.value.hyper_v_generation
  architecture                        = each.value.architecture
  description                         = each.value.description
  eula                                = each.value.eula
  privacy_statement_uri               = each.value.privacy_statement_uri
  release_note_uri                    = each.value.release_note_uri
  trusted_launch_supported            = each.value.trusted_launch_supported
  trusted_launch_enabled              = each.value.trusted_launch_enabled
  confidential_vm_supported           = each.value.confidential_vm_supported
  confidential_vm_enabled             = each.value.confidential_vm_enabled
  accelerated_network_support_enabled = each.value.accelerated_network_support_enabled
  specialized                         = each.value.specialized

  identifier {
    publisher = each.value.identifier.publisher
    offer     = each.value.identifier.offer
    sku       = each.value.identifier.sku
  }

  tags = var.tags
}

# VM Extensions
resource "azurerm_virtual_machine_extension" "linux" {
  for_each = var.linux_vm_extensions

  name                       = each.key
  virtual_machine_id         = azurerm_linux_virtual_machine.this[each.value.vm_key].id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = each.value.auto_upgrade_minor_version
  automatic_upgrade_enabled  = each.value.automatic_upgrade_enabled
  settings                   = each.value.settings
  protected_settings         = each.value.protected_settings
  tags                       = var.tags
}

resource "azurerm_virtual_machine_extension" "windows" {
  for_each = var.windows_vm_extensions

  name                       = each.key
  virtual_machine_id         = azurerm_windows_virtual_machine.this[each.value.vm_key].id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = each.value.auto_upgrade_minor_version
  automatic_upgrade_enabled  = each.value.automatic_upgrade_enabled
  settings                   = each.value.settings
  protected_settings         = each.value.protected_settings
  tags                       = var.tags
}

# Data Disks
resource "azurerm_managed_disk" "this" {
  for_each = var.managed_disks

  name                          = each.key
  location                      = var.location
  resource_group_name           = var.resource_group_name
  storage_account_type          = each.value.storage_account_type
  create_option                 = each.value.create_option
  disk_size_gb                  = each.value.disk_size_gb
  source_resource_id            = each.value.source_resource_id
  image_reference_id            = each.value.image_reference_id
  zone                          = each.value.zone
  tier                          = each.value.tier
  max_shares                    = each.value.max_shares
  trusted_launch_enabled        = each.value.trusted_launch_enabled
  on_demand_bursting_enabled    = each.value.on_demand_bursting_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  network_access_policy         = each.value.network_access_policy
  disk_access_id                = each.value.disk_access_id
  disk_encryption_set_id        = each.value.disk_encryption_set_id

  dynamic "encryption_settings" {
    for_each = each.value.encryption_settings != null ? [each.value.encryption_settings] : []
    content {
      dynamic "disk_encryption_key" {
        for_each = encryption_settings.value.disk_encryption_key != null ? [encryption_settings.value.disk_encryption_key] : []
        content {
          secret_url      = disk_encryption_key.value.secret_url
          source_vault_id = disk_encryption_key.value.source_vault_id
        }
      }
      dynamic "key_encryption_key" {
        for_each = encryption_settings.value.key_encryption_key != null ? [encryption_settings.value.key_encryption_key] : []
        content {
          key_url         = key_encryption_key.value.key_url
          source_vault_id = key_encryption_key.value.source_vault_id
        }
      }
    }
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "linux" {
  for_each = var.linux_data_disk_attachments

  managed_disk_id           = azurerm_managed_disk.this[each.value.disk_key].id
  virtual_machine_id        = azurerm_linux_virtual_machine.this[each.value.vm_key].id
  lun                       = each.value.lun
  caching                   = each.value.caching
  create_option             = each.value.create_option
  write_accelerator_enabled = each.value.write_accelerator_enabled
}

resource "azurerm_virtual_machine_data_disk_attachment" "windows" {
  for_each = var.windows_data_disk_attachments

  managed_disk_id           = azurerm_managed_disk.this[each.value.disk_key].id
  virtual_machine_id        = azurerm_windows_virtual_machine.this[each.value.vm_key].id
  lun                       = each.value.lun
  caching                   = each.value.caching
  create_option             = each.value.create_option
  write_accelerator_enabled = each.value.write_accelerator_enabled
}

# Disk Access (for Private Endpoints to Managed Disks)
resource "azurerm_disk_access" "this" {
  for_each = var.disk_accesses

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Disk Encryption Set
resource "azurerm_disk_encryption_set" "this" {
  for_each = var.disk_encryption_sets

  name                      = each.key
  location                  = var.location
  resource_group_name       = var.resource_group_name
  key_vault_key_id          = each.value.key_vault_key_id
  auto_key_rotation_enabled = each.value.auto_key_rotation_enabled
  encryption_type           = each.value.encryption_type

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }

  tags = var.tags
}
