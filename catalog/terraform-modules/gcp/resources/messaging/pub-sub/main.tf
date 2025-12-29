terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )
}

# Pub/Sub Schema (optional)
resource "google_pubsub_schema" "this" {
  count = var.schema_name != null && var.schema_definition != null ? 1 : 0

  project    = var.project_id
  name       = var.schema_name
  type       = var.schema_type
  definition = var.schema_definition
}

# Pub/Sub Topic
resource "google_pubsub_topic" "this" {
  project = var.project_id
  name    = var.topic_name
  labels  = local.labels

  message_retention_duration = var.message_retention_duration

  dynamic "schema_settings" {
    for_each = var.schema_name != null && var.schema_definition != null ? [1] : []
    content {
      schema   = google_pubsub_schema.this[0].id
      encoding = var.schema_type == "AVRO" ? "JSON" : "BINARY"
    }
  }

  # CMEK encryption
  kms_key_name = var.kms_key_name
}

# Pub/Sub Subscriptions
resource "google_pubsub_subscription" "this" {
  for_each = { for sub in var.subscriptions : sub.name => sub }

  project = var.project_id
  name    = each.value.name
  topic   = google_pubsub_topic.this.id
  labels  = local.labels

  ack_deadline_seconds       = each.value.ack_deadline_seconds
  message_retention_duration = each.value.message_retention_duration
  retain_acked_messages      = each.value.retain_acked_messages
  filter                     = each.value.filter

  dynamic "expiration_policy" {
    for_each = each.value.expiration_policy_ttl != null ? [1] : []
    content {
      ttl = each.value.expiration_policy_ttl
    }
  }

  # Push configuration
  dynamic "push_config" {
    for_each = each.value.push_config != null ? [each.value.push_config] : []
    content {
      push_endpoint = push_config.value.push_endpoint

      dynamic "oidc_token" {
        for_each = push_config.value.oidc_token != null ? [push_config.value.oidc_token] : []
        content {
          service_account_email = oidc_token.value.service_account_email
          audience              = oidc_token.value.audience
        }
      }

      attributes = push_config.value.attributes
    }
  }

  # Dead letter policy
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_topic != null ? [1] : []
    content {
      dead_letter_topic     = each.value.dead_letter_topic
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }

  # Retry policy
  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      minimum_backoff = retry_policy.value.minimum_backoff
      maximum_backoff = retry_policy.value.maximum_backoff
    }
  }
}

# Topic IAM Bindings
resource "google_pubsub_topic_iam_member" "this" {
  for_each = {
    for binding in flatten([
      for iam in var.topic_iam_bindings : [
        for member in iam.members : {
          role   = iam.role
          member = member
        }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }

  project = var.project_id
  topic   = google_pubsub_topic.this.name
  role    = each.value.role
  member  = each.value.member
}
