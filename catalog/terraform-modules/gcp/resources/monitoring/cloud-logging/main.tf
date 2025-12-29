terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

# Custom Log Buckets
resource "google_logging_project_bucket_config" "buckets" {
  for_each = { for bucket in var.log_buckets : bucket.bucket_id => bucket }

  project        = var.project_id
  location       = each.value.location
  bucket_id      = each.value.bucket_id
  retention_days = each.value.retention_days
  description    = each.value.description
}

# Log Sinks for routing logs to various destinations (BigQuery, Cloud Storage, Pub/Sub)
resource "google_logging_project_sink" "sinks" {
  for_each = { for sink in var.log_sinks : sink.name => sink }

  project                = var.project_id
  name                   = each.value.name
  destination            = each.value.destination
  filter                 = each.value.filter
  unique_writer_identity = each.value.unique_writer_identity

  dynamic "exclusions" {
    for_each = each.value.exclusions != null ? each.value.exclusions : []
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = lookup(exclusions.value, "description", null)
      disabled    = lookup(exclusions.value, "disabled", false)
    }
  }

  dynamic "bigquery_options" {
    for_each = startswith(each.value.destination, "bigquery.googleapis.com/") ? [1] : []
    content {
      use_partitioned_tables = true
    }
  }
}

# Log Exclusions for filtering out unwanted logs
resource "google_logging_project_exclusion" "exclusions" {
  for_each = { for exclusion in var.log_exclusions : exclusion.name => exclusion }

  project     = var.project_id
  name        = each.value.name
  filter      = each.value.filter
  description = each.value.description
  disabled    = each.value.disabled
}

# Log-based Metrics
resource "google_logging_metric" "metrics" {
  for_each = { for metric in var.log_metrics : metric.name => metric }

  project = var.project_id
  name    = each.value.name
  filter  = each.value.filter

  dynamic "metric_descriptor" {
    for_each = each.value.metric_descriptor != null ? [each.value.metric_descriptor] : []
    content {
      metric_kind = metric_descriptor.value.metric_kind
      value_type  = metric_descriptor.value.value_type
      unit        = lookup(metric_descriptor.value, "unit", "1")

      dynamic "labels" {
        for_each = lookup(metric_descriptor.value, "labels", [])
        content {
          key         = labels.value.key
          value_type  = lookup(labels.value, "value_type", "STRING")
          description = lookup(labels.value, "description", null)
        }
      }
    }
  }

  dynamic "bucket_options" {
    for_each = each.value.bucket_options != null ? [each.value.bucket_options] : []
    content {
      dynamic "linear_buckets" {
        for_each = lookup(bucket_options.value, "linear_buckets", null) != null ? [bucket_options.value.linear_buckets] : []
        content {
          num_finite_buckets = linear_buckets.value.num_finite_buckets
          width              = linear_buckets.value.width
          offset             = linear_buckets.value.offset
        }
      }

      dynamic "exponential_buckets" {
        for_each = lookup(bucket_options.value, "exponential_buckets", null) != null ? [bucket_options.value.exponential_buckets] : []
        content {
          num_finite_buckets = exponential_buckets.value.num_finite_buckets
          growth_factor      = exponential_buckets.value.growth_factor
          scale              = exponential_buckets.value.scale
        }
      }

      dynamic "explicit_buckets" {
        for_each = lookup(bucket_options.value, "explicit_buckets", null) != null ? [bucket_options.value.explicit_buckets] : []
        content {
          bounds = explicit_buckets.value.bounds
        }
      }
    }
  }

  value_extractor  = each.value.value_extractor
  label_extractors = lookup(each.value, "label_extractors", null)
  bucket_name      = lookup(each.value, "bucket_name", null)
  disabled         = lookup(each.value, "disabled", false)
}
