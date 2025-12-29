terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  default_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_application_insights" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.workspace_id
  application_type    = var.application_type

  retention_in_days                     = var.retention_in_days
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  local_authentication_disabled         = var.local_authentication_disabled

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_application_insights_web_test" "this" {
  for_each = { for test in var.web_tests : test.name => test }

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.this.id
  kind                    = "ping"
  frequency               = each.value.frequency
  timeout                 = each.value.timeout
  enabled                 = each.value.enabled
  geo_locations           = each.value.geo_locations

  configuration = <<XML
<WebTest Name="${each.value.name}" Enabled="True" Timeout="${each.value.timeout}" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010">
  <Items>
    <Request Method="GET" Version="1.1" Url="${each.value.url}" ThinkTime="0" />
  </Items>
</WebTest>
XML

  tags = merge(local.default_tags, var.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_application_insights_smart_detection_rule" "slow_page_load" {
  name                    = "Slow page load time"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "slow_server_response" {
  name                    = "Slow server response time"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "degradation_dependency_duration" {
  name                    = "Degradation in dependency duration"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "degradation_response_time" {
  name                    = "Degradation in server response time"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "exception_volume" {
  name                    = "Abnormal rise in exception volume"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "memory_leak" {
  name                    = "Potential memory leak detected"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "security_issue" {
  name                    = "Potential security issue detected"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "failed_requests" {
  name                    = "Abnormal rise in daily data volume"
  application_insights_id = azurerm_application_insights.this.id
  enabled                 = true
}
