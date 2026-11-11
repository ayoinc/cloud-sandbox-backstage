# -----------------------------------------------------------------------------
# Streaming: a Pub/Sub topic for events. Pub/Sub itself writes the events to the
# raw zone of the lake and to the staging dataset of the warehouse, whichever
# exist. A pull subscription serves pipelines. The topic module cannot create
# subscriptions with this provider version, so they are declared here.
# -----------------------------------------------------------------------------

locals {
  # Pub/Sub keeps messages for 10 minutes to 31 days.
  streaming_retention_seconds = floor(min(max(var.streaming_retention_hours * 3600, 600), 2678400))
  streaming_retention         = "${local.streaming_retention_seconds}s"

  streaming_to_lake      = var.enable_streaming && var.enable_data_lake
  streaming_to_warehouse = var.enable_streaming && var.enable_data_warehouse

  events_topic_name = "${local.name_prefix}-events"
}

# Creates the Pub/Sub service agent, so it can be given access before the first topic exists.
resource "google_project_service_identity" "pubsub" {
  provider = google-beta
  count    = var.enable_streaming ? 1 : 0

  project = var.gcp_project_id
  service = "pubsub.googleapis.com"

  depends_on = [google_project_service.apis]
}

# Messages that a subscription cannot deliver end up here instead of blocking it.
module "dead_letter_topic" {
  count  = var.enable_streaming ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/messaging/pub-sub?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  topic_name                 = "${local.events_topic_name}-dead-letter"
  message_retention_duration = local.streaming_retention
  kms_key_name               = local.kms_key_ids["pubsub"]

  depends_on = [google_project_service.apis, google_kms_crypto_key_iam_member.service_agent]
}

module "events_topic" {
  count  = var.enable_streaming ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/messaging/pub-sub?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  topic_name                 = local.events_topic_name
  message_retention_duration = local.streaming_retention
  kms_key_name               = local.kms_key_ids["pubsub"]

  depends_on = [google_project_service.apis, google_kms_crypto_key_iam_member.service_agent]
}

# Keeps dead-lettered messages until someone inspects them.
resource "google_pubsub_subscription" "dead_letter" {
  count = var.enable_streaming ? 1 : 0

  name  = "${local.events_topic_name}-dead-letter"
  topic = module.dead_letter_topic[0].topic_id

  message_retention_duration = local.streaming_retention

  expiration_policy {
    ttl = "" # never expires
  }
}

# For pipelines that read the events themselves.
resource "google_pubsub_subscription" "pull" {
  count = var.enable_streaming ? 1 : 0

  name  = "${local.events_topic_name}-pull"
  topic = module.events_topic[0].topic_id

  ack_deadline_seconds       = 60
  message_retention_duration = local.streaming_retention

  dead_letter_policy {
    dead_letter_topic     = module.dead_letter_topic[0].topic_id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  expiration_policy {
    ttl = ""
  }
}

# --- Events to the raw zone of the lake --------------------------------------

resource "google_storage_bucket_iam_member" "pubsub_lake_writer" {
  for_each = local.streaming_to_lake ? toset(["roles/storage.objectCreator", "roles/storage.legacyBucketReader"]) : toset([])

  bucket = local.lake_bucket_names["raw"]
  role   = each.value
  member = google_project_service_identity.pubsub[0].member
}

resource "google_pubsub_subscription" "to_lake" {
  count = local.streaming_to_lake ? 1 : 0

  name  = "${local.events_topic_name}-to-lake"
  topic = module.events_topic[0].topic_id

  # A file is written at least every five minutes, so messages are acknowledged within that time.
  ack_deadline_seconds       = 300
  message_retention_duration = local.streaming_retention

  cloud_storage_config {
    bucket                   = local.lake_bucket_names["raw"]
    filename_prefix          = "streaming/events/"
    filename_suffix          = ".avro"
    filename_datetime_format = "YYYY-MM-DD/hh_mm_ssZ"
    max_duration             = "300s"

    avro_config {
      write_metadata = true
    }
  }

  dead_letter_policy {
    dead_letter_topic     = module.dead_letter_topic[0].topic_id
    max_delivery_attempts = 5
  }

  expiration_policy {
    ttl = ""
  }

  depends_on = [google_storage_bucket_iam_member.pubsub_lake_writer]
}

# --- Events to the staging dataset of the warehouse --------------------------

resource "google_bigquery_table" "events" {
  count = local.streaming_to_warehouse ? 1 : 0

  dataset_id          = google_bigquery_dataset.this["staging"].dataset_id
  table_id            = "events"
  description         = "Events of the topic ${local.events_topic_name}, written by Pub/Sub"
  deletion_protection = local.is_production

  time_partitioning {
    type  = "DAY"
    field = "publish_time"
  }

  # The columns a BigQuery subscription writes when it includes the message metadata.
  schema = jsonencode([
    { name = "subscription_name", type = "STRING", mode = "NULLABLE", description = "Subscription that delivered the message" },
    { name = "message_id", type = "STRING", mode = "NULLABLE", description = "ID of the message" },
    { name = "publish_time", type = "TIMESTAMP", mode = "NULLABLE", description = "Time the message was published" },
    { name = "data", type = "STRING", mode = "NULLABLE", description = "Message body" },
    { name = "attributes", type = "JSON", mode = "NULLABLE", description = "Message attributes" },
  ])
}

resource "google_bigquery_table_iam_member" "pubsub_warehouse_writer" {
  count = local.streaming_to_warehouse ? 1 : 0

  dataset_id = google_bigquery_table.events[0].dataset_id
  table_id   = google_bigquery_table.events[0].table_id
  role       = "roles/bigquery.dataEditor"
  member     = google_project_service_identity.pubsub[0].member
}

resource "google_pubsub_subscription" "to_warehouse" {
  count = local.streaming_to_warehouse ? 1 : 0

  name  = "${local.events_topic_name}-to-warehouse"
  topic = module.events_topic[0].topic_id

  message_retention_duration = local.streaming_retention

  bigquery_config {
    table          = "${var.gcp_project_id}.${google_bigquery_table.events[0].dataset_id}.${google_bigquery_table.events[0].table_id}"
    write_metadata = true
  }

  dead_letter_policy {
    dead_letter_topic     = module.dead_letter_topic[0].topic_id
    max_delivery_attempts = 5
  }

  expiration_policy {
    ttl = ""
  }

  depends_on = [google_bigquery_table_iam_member.pubsub_warehouse_writer]
}

# --- Dead lettering -----------------------------------------------------------

locals {
  dead_lettered_subscriptions = merge(
    var.enable_streaming ? { pull = google_pubsub_subscription.pull[0].name } : {},
    local.streaming_to_lake ? { lake = google_pubsub_subscription.to_lake[0].name } : {},
    local.streaming_to_warehouse ? { warehouse = google_pubsub_subscription.to_warehouse[0].name } : {},
  )
}

# Pub/Sub forwards undeliverable messages itself: it publishes to the dead letter
# topic and acknowledges on the source subscription.
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  count = var.enable_streaming ? 1 : 0

  project = var.gcp_project_id
  topic   = module.dead_letter_topic[0].topic_name
  role    = "roles/pubsub.publisher"
  member  = google_project_service_identity.pubsub[0].member
}

resource "google_pubsub_subscription_iam_member" "dead_letter_forwarder" {
  for_each = local.dead_lettered_subscriptions

  project      = var.gcp_project_id
  subscription = each.value
  role         = "roles/pubsub.subscriber"
  member       = google_project_service_identity.pubsub[0].member
}
