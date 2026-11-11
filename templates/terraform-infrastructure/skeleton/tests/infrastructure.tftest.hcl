{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
# Plan-only tests against mocked providers: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test
{%- if aws %}

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}
{%- endif %}
{%- if azure %}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      object_id       = "44444444-4444-4444-4444-444444444444"
    }
  }

  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/22222222-2222-2222-2222-222222222222"
      subscription_id = "22222222-2222-2222-2222-222222222222"
      tenant_id       = "11111111-1111-1111-1111-111111111111"
    }
  }
}
{%- if datadog or newrelic %}

mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = {
      object_id = "44444444-4444-4444-4444-444444444444"
      tenant_id = "11111111-1111-1111-1111-111111111111"
    }
  }

  mock_resource "azuread_application" {
    override_during = plan
    defaults = {
      id        = "/applications/55555555-5555-5555-5555-555555555555"
      client_id = "66666666-6666-6666-6666-666666666666"
    }
  }

  mock_resource "azuread_service_principal" {
    override_during = plan
    defaults = {
      object_id = "77777777-7777-7777-7777-777777777777"
    }
  }
}
{%- endif %}
{%- endif %}
{%- if gcp %}

mock_provider "google" {
  mock_data "google_project" {
    defaults = {
      number = "123456789012"
    }
  }

  mock_data "google_client_config" {
    defaults = {
      project = "test-project"
    }
  }

  mock_data "google_compute_zones" {
    defaults = {
      names = ["us-central1-a", "us-central1-b", "us-central1-c"]
    }
  }

  mock_data "google_storage_project_service_account" {
    defaults = {
      email_address = "service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
      member        = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
    }
  }

  mock_data "google_storage_transfer_project_service_account" {
    defaults = {
      email  = "project-123456789012@storage-transfer-service.iam.gserviceaccount.com"
      member = "serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com"
    }
  }

  mock_data "google_logging_project_cmek_settings" {
    defaults = {
      service_account_id = "cmek-p123456789012@gcp-sa-logging.iam.gserviceaccount.com"
    }
  }
}

mock_provider "google-beta" {}

mock_provider "tls" {}
{%- endif %}
{%- if datadog %}

mock_provider "datadog" {
  mock_data "datadog_integration_aws_iam_permissions" {
    defaults = {
      iam_permissions = [
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics",
        "ec2:DescribeInstances",
        "tag:GetResources",
      ]
    }
  }
}
{%- endif %}
{%- if newrelic %}

mock_provider "newrelic" {
  mock_data "newrelic_account" {
    defaults = {
      id = "7654321"
    }
  }
}
{%- endif %}
{%- if elastic %}

mock_provider "ec" {
  mock_data "ec_stack" {
    defaults = {
      version = "9.1.0"
    }
  }
}
{%- endif %}

mock_provider "random" {
  mock_resource "random_id" {
    override_during = plan
    defaults = {
      hex = "a1b2"
    }
  }
}
{%- if azure or gcp %}

mock_provider "time" {}
{%- endif %}

# Every variable is set here so that the tests do not depend on the tfvars
# files. This is a small stack: a network and object storage.
variables {
  name                = "test-stack"
  environment         = "staging"
  owner               = "group:default/platform-team"
  infrastructure_type = "web-application"
{%- if aws %}

  aws_region           = "us-east-1"
  aws_secondary_region = "us-west-2"
{%- endif %}
{%- if azure %}

  azure_location           = "eastus2"
  azure_secondary_location = "centralus"
{%- endif %}
{%- if gcp %}

  gcp_project_id       = "test-project"
  gcp_region           = "us-central1"
  gcp_secondary_region = "us-east1"
{%- endif %}

  enable_networking           = true
  enable_security_group_rules = true

  enable_kubernetes  = false
  kubernetes_version = null
  node_size          = "medium"
  enable_autoscaling = true
  min_nodes          = 2
  max_nodes          = 5

  enable_database = false
  database_type   = "postgresql"
  enable_storage  = true
  enable_cdn      = false

  enable_waf             = false
  enable_secrets_manager = false
  enable_kms             = false
  enable_backup          = false
  compliance_framework   = "none"

  enable_monitoring   = false
  monitoring_solution = "${{ values.monitoring_solution }}"
  enable_alerting     = false
  log_retention_days  = 30

  enable_disaster_recovery = false
  enable_cost_optimization = false
}

run "small_stack" {
  command = plan

  assert {
    condition     = output.name_prefix == "test-stack-stg"
    error_message = "Names are prefixed with the stack name and the short environment."
  }

  assert {
    condition     = output.effective_settings.log_retention_days == 30 && !output.effective_settings.enable_kms && !output.effective_settings.require_deletion_protection
    error_message = "Without a compliance framework the settings are used as given."
  }
}

run "long_names_are_shortened" {
  command = plan

  variables {
    name        = "a-very-long-stack-name-for-testing"
    environment = "production"
  }

  assert {
    condition     = output.name_prefix == "a-very-long-stack-n-prod" && length(output.name_prefix) <= 24
    error_message = "The name prefix must fit in 24 characters."
  }

  assert {
    condition     = output.effective_settings.require_deletion_protection
    error_message = "Production is protected from deletion."
  }
}

run "hipaa_baseline" {
  command = plan

  variables {
    compliance_framework = "hipaa"
    enable_monitoring    = true
    enable_database      = true
  }

  assert {
    condition     = output.effective_settings.log_retention_days == 2192
    error_message = "HIPAA keeps logs for six years."
  }

  assert {
    condition     = output.effective_settings.enable_kms && output.effective_settings.enable_backup && output.effective_settings.require_deletion_protection && output.effective_settings.require_flow_logs
    error_message = "HIPAA switches on customer-managed keys, backups, deletion protection and flow logs."
  }
}

run "cis_baseline_keeps_longer_retention" {
  command = plan

  variables {
    compliance_framework = "cis"
    log_retention_days   = 90
  }

  assert {
    condition     = output.effective_settings.log_retention_days == 365 && output.effective_settings.require_flow_logs && !output.effective_settings.enable_kms
    error_message = "CIS raises log retention to a year and requires flow logs, without forcing customer-managed keys."
  }
}

run "cdn_brings_object_storage" {
  command = plan

  variables {
    enable_storage = false
    enable_cdn     = true
    enable_waf     = true
  }

  assert {
    condition     = output.effective_settings.enable_storage
    error_message = "A CDN needs the object storage it serves."
  }
}

run "full_stack_in_production" {
  command = plan

  variables {
    environment              = "production"
    infrastructure_type      = "ml-platform"
    enable_kubernetes        = true
    enable_database          = true
    enable_cdn               = true
    enable_waf               = true
    enable_secrets_manager   = true
    enable_kms               = true
    enable_backup            = true
    compliance_framework     = "pci-dss"
    enable_monitoring        = true
    enable_alerting          = true
    alert_email              = "platform@example.com"
    enable_disaster_recovery = true
    enable_cost_optimization = true
  }

  assert {
    condition     = output.effective_settings.log_retention_days == 365 && output.effective_settings.require_deletion_protection
    error_message = "PCI DSS keeps logs for a year and protects resources from deletion."
  }
}

run "fixed_size_cluster" {
  command = plan

  variables {
    enable_kubernetes  = true
    enable_autoscaling = false
    node_size          = "small"
  }
}

run "rejects_inverted_node_bounds" {
  command = plan

  variables {
    min_nodes = 5
    max_nodes = 2
  }

  expect_failures = [var.max_nodes]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

run "rejects_unknown_compliance_framework" {
  command = plan

  variables {
    compliance_framework = "iso"
  }

  expect_failures = [var.compliance_framework]
}
