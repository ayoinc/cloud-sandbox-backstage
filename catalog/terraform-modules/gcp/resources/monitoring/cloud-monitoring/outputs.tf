output "notification_channel_ids" {
  description = "Map of notification channel display names to their IDs"
  value = {
    for name, channel in google_monitoring_notification_channel.channels :
    name => channel.id
  }
}

output "notification_channel_names" {
  description = "Map of notification channel display names to their full resource names"
  value = {
    for name, channel in google_monitoring_notification_channel.channels :
    name => channel.name
  }
}

output "alert_policy_ids" {
  description = "Map of alert policy display names to their IDs"
  value = {
    for name, policy in google_monitoring_alert_policy.policies :
    name => policy.id
  }
}

output "alert_policy_names" {
  description = "Map of alert policy display names to their full resource names"
  value = {
    for name, policy in google_monitoring_alert_policy.policies :
    name => policy.name
  }
}

output "uptime_check_ids" {
  description = "Map of uptime check display names to their IDs"
  value = {
    for name, check in google_monitoring_uptime_check_config.checks :
    name => check.id
  }
}

output "uptime_check_names" {
  description = "Map of uptime check display names to their full resource names"
  value = {
    for name, check in google_monitoring_uptime_check_config.checks :
    name => check.name
  }
}

output "dashboard_ids" {
  description = "Map of dashboard display names to their IDs"
  value = {
    for name, dashboard in google_monitoring_dashboard.dashboards :
    name => dashboard.id
  }
}

output "group_ids" {
  description = "Map of resource group display names to their IDs"
  value = {
    for name, group in google_monitoring_group.groups :
    name => group.id
  }
}

output "group_names" {
  description = "Map of resource group display names to their full resource names"
  value = {
    for name, group in google_monitoring_group.groups :
    name => group.name
  }
}

output "custom_service_ids" {
  description = "Map of custom service display names to their IDs"
  value = {
    for name, service in google_monitoring_custom_service.services :
    name => service.id
  }
}

output "custom_service_names" {
  description = "Map of custom service display names to their full resource names"
  value = {
    for name, service in google_monitoring_custom_service.services :
    name => service.name
  }
}

output "slo_ids" {
  description = "Map of SLO display names to their IDs"
  value = {
    for name, slo in google_monitoring_slo.slos :
    name => slo.id
  }
}

output "slo_names" {
  description = "Map of SLO display names to their full resource names"
  value = {
    for name, slo in google_monitoring_slo.slos :
    name => slo.name
  }
}
