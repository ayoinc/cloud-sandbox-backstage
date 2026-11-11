# =============================================================================
# GCP Pub/Sub Module
# =============================================================================
# Creates a topic with its subscriptions:
# - Topic with message retention and a storage policy limited to your regions
# - Optional schema (Avro or Protocol Buffers) that published messages must match
# - Pull or authenticated push subscriptions with retry backoff
# - Dead-letter topic and subscription, with the grants Pub/Sub needs to use them
# - IAM bindings for publishers and subscribers
# =============================================================================

data "google_project" "main" {
  project_id = var.project_id
}

locals {
  topic_name = "${var.name}-${var.environment}"

  # Label values allow only lowercase letters, digits, underscores and hyphens.
  common_labels = merge(
    var.labels,
    {
      project     = var.name
      environment = var.environment
      managed-by  = "terraform"
    },
    var.owner != "" ? { owner = substr(replace(lower(var.owner), "/[^a-z0-9_-]/", "_"), 0, 63) } : {},
  )
  # Pub/Sub forwards dead letters and decrypts with its own service agent.
  pubsub_service_agent = "serviceAccount:service-${data.google_project.main.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  persistence_regions = length(var.allowed_persistence_regions) > 0 ? var.allowed_persistence_regions : toset([var.region])

  subscription_names = merge(
    { for key, subscription in google_pubsub_subscription.main : key => subscription.name },
    { for subscription in google_pubsub_subscription.dead_letter : "dead-letter" => subscription.name },
  )

  subscriber_bindings = merge([
    for key, name in local.subscription_names : {
      for member in var.subscribers : "${key}/${member}" => { subscription = name, member = member }
    }
  ]...)
}

# =============================================================================
# API
# =============================================================================
resource "google_project_service" "pubsub" {
  count = var.enable_apis ? 1 : 0

  project            = var.project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# =============================================================================
# Schema
# =============================================================================
resource "google_pubsub_schema" "main" {
  count = var.schema_type == "NONE" ? 0 : 1

  project    = var.project_id
  name       = local.topic_name
  type       = var.schema_type
  definition = file(var.schema_definition_file)

  depends_on = [google_project_service.pubsub]
}

# =============================================================================
# Topic
# =============================================================================
resource "google_kms_crypto_key_iam_member" "pubsub_agent" {
  count = var.kms_key_name == null ? 0 : 1

  crypto_key_id = var.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local.pubsub_service_agent
}

resource "google_pubsub_topic" "main" {
  #checkov:skip=CKV_GCP_83:A customer-managed key is opt-in through kms_key_name; messages are always encrypted with Google-managed keys
  project                    = var.project_id
  name                       = local.topic_name
  labels                     = local.common_labels
  message_retention_duration = var.message_retention_duration
  kms_key_name               = var.kms_key_name

  message_storage_policy {
    allowed_persistence_regions = local.persistence_regions
    enforce_in_transit          = true
  }

  dynamic "schema_settings" {
    for_each = google_pubsub_schema.main

    content {
      schema   = schema_settings.value.id
      encoding = var.schema_encoding
    }
  }

  depends_on = [
    google_project_service.pubsub,
    google_kms_crypto_key_iam_member.pubsub_agent,
  ]
}

# =============================================================================
# Dead Letters
# =============================================================================
resource "google_pubsub_topic" "dead_letter" {
  #checkov:skip=CKV_GCP_83:A customer-managed key is opt-in through kms_key_name; messages are always encrypted with Google-managed keys
  count = var.dead_letter_enabled ? 1 : 0

  project                    = var.project_id
  name                       = "${local.topic_name}-dead-letter"
  labels                     = local.common_labels
  message_retention_duration = var.message_retention_duration
  kms_key_name               = var.kms_key_name

  message_storage_policy {
    allowed_persistence_regions = local.persistence_regions
    enforce_in_transit          = true
  }

  depends_on = [
    google_project_service.pubsub,
    google_kms_crypto_key_iam_member.pubsub_agent,
  ]
}

# Without a subscription the dead-letter topic would drop what it receives.
resource "google_pubsub_subscription" "dead_letter" {
  count = var.dead_letter_enabled ? 1 : 0

  project                    = var.project_id
  name                       = "${local.topic_name}-dead-letter"
  topic                      = google_pubsub_topic.dead_letter[0].id
  labels                     = local.common_labels
  ack_deadline_seconds       = 60
  message_retention_duration = "1209600s"

  expiration_policy {
    ttl = ""
  }
}

resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  count = var.dead_letter_enabled ? 1 : 0

  project = var.project_id
  topic   = google_pubsub_topic.dead_letter[0].name
  role    = "roles/pubsub.publisher"
  member  = local.pubsub_service_agent
}

resource "google_pubsub_subscription_iam_member" "dead_letter_forwarder" {
  for_each = var.dead_letter_enabled ? google_pubsub_subscription.main : {}

  project      = var.project_id
  subscription = each.value.name
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_service_agent
}

# =============================================================================
# Subscriptions
# =============================================================================
resource "google_pubsub_subscription" "main" {
  for_each = var.subscriptions

  project = var.project_id
  name    = "${local.topic_name}-${each.key}"
  topic   = google_pubsub_topic.main.id
  labels  = local.common_labels

  ack_deadline_seconds         = each.value.ack_deadline_seconds
  message_retention_duration   = each.value.message_retention_duration
  retain_acked_messages        = each.value.retain_acked_messages
  filter                       = each.value.filter
  enable_message_ordering      = each.value.enable_message_ordering
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery

  # A subscription that is idle for a month must not delete itself.
  expiration_policy {
    ttl = ""
  }

  retry_policy {
    minimum_backoff = each.value.minimum_backoff
    maximum_backoff = each.value.maximum_backoff
  }

  dynamic "dead_letter_policy" {
    for_each = google_pubsub_topic.dead_letter

    content {
      dead_letter_topic     = dead_letter_policy.value.id
      max_delivery_attempts = var.max_delivery_attempts
    }
  }

  dynamic "push_config" {
    for_each = each.value.push_endpoint == null ? [] : [each.value]

    content {
      push_endpoint = push_config.value.push_endpoint

      oidc_token {
        service_account_email = push_config.value.push_service_account_email
      }
    }
  }
}

# =============================================================================
# Access
# =============================================================================
resource "google_pubsub_topic_iam_member" "publisher" {
  for_each = var.publishers

  project = var.project_id
  topic   = google_pubsub_topic.main.name
  role    = "roles/pubsub.publisher"
  member  = each.value
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  for_each = local.subscriber_bindings

  project      = var.project_id
  subscription = each.value.subscription
  role         = "roles/pubsub.subscriber"
  member       = each.value.member
}
