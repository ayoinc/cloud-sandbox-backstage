data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  role_name = "${var.name_prefix}-datadog-integration"
}

# Registers the AWS account in Datadog. Datadog generates the external ID that
# the integration role must require, so the role is created after this resource
# and is referenced here by name only.
resource "datadog_integration_aws_account" "this" {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  account_tags   = [for key, value in var.tags : "${key}:${value}"]

  aws_regions {
    include_all = true
  }

  auth_config {
    aws_auth_config_role {
      role_name = local.role_name
    }
  }

  # CloudWatch metrics, polled by Datadog through the role. The empty filter
  # keeps Datadog's default list of excluded high-volume namespaces.
  metrics_config {
    enabled                   = true
    automute_enabled          = true
    collect_cloudwatch_alarms = false
    collect_custom_metrics    = false

    namespace_filters {}
  }

  # Resource inventory (tags and configuration) used to enrich the metrics.
  resources_config {
    cloud_security_posture_management_collection = false
    extended_collection                          = true
  }

  # Log and trace collection need a Datadog Forwarder function and X-Ray, which
  # this stack does not deploy: both stay at the Datadog defaults (nothing subscribed).
  logs_config {
    lambda_forwarder {}
  }

  traces_config {
    xray_services {}
  }
}
