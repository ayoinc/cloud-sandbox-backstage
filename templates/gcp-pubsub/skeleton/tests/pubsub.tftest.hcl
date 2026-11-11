# =============================================================================
# GCP Pub/Sub - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Google Cloud account and create nothing.
# =============================================================================

mock_provider "google" {
  mock_data "google_project" {
    defaults = {
      number = "123456789012"
    }
  }

  mock_resource "google_pubsub_topic" {
    defaults = {
      id = "projects/test-project-123/topics/mocked"
    }
  }

  mock_resource "google_pubsub_schema" {
    defaults = {
      id = "projects/test-project-123/schemas/test-dev"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  project_id  = "test-project-123"
  region      = "europe-west1"
  owner       = "group:default/platform-team"

  subscriptions = {
    worker = {}
    audit = {
      ack_deadline_seconds = 60
      filter               = "attributes.type = \"audit\""
    }
  }
}

run "creates_topic_subscriptions_and_dead_letters" {
  command = apply

  assert {
    condition     = output.topic_name == "test-dev"
    error_message = "The topic must be named <name>-<environment>"
  }

  assert {
    condition     = length(output.subscription_names) == 3 && output.subscription_names["worker"] == "test-dev-worker" && output.subscription_names["dead-letter"] == "test-dev-dead-letter"
    error_message = "Every subscription and the dead-letter subscription must be created"
  }

  assert {
    condition     = output.dead_letter_topic_name == "test-dev-dead-letter"
    error_message = "A dead-letter topic must exist by default"
  }

  assert {
    condition     = output.schema_id == null
    error_message = "A schema must be opt-in"
  }
}

run "defaults" {
  command = plan

  module {
    source = "./modules/pubsub"
  }

  assert {
    condition     = google_pubsub_topic.main.message_storage_policy[0].allowed_persistence_regions == toset(["europe-west1"])
    error_message = "Messages must stay in the region by default"
  }

  assert {
    condition     = google_pubsub_subscription.main["worker"].expiration_policy[0].ttl == ""
    error_message = "Subscriptions must never expire"
  }

  assert {
    condition     = google_pubsub_subscription.main["worker"].dead_letter_policy[0].max_delivery_attempts == 5
    error_message = "Messages must go to the dead-letter topic after 5 attempts"
  }

  assert {
    condition     = google_pubsub_subscription.main["audit"].filter == "attributes.type = \"audit\"" && google_pubsub_subscription.main["audit"].ack_deadline_seconds == 60
    error_message = "Per-subscription settings must be applied"
  }

  assert {
    condition     = length(google_pubsub_subscription.main["worker"].push_config) == 0
    error_message = "Subscriptions must be pull subscriptions unless an endpoint is given"
  }

  assert {
    condition     = google_pubsub_topic_iam_member.dead_letter_publisher[0].member == "serviceAccount:service-123456789012@gcp-sa-pubsub.iam.gserviceaccount.com"
    error_message = "The Pub/Sub service agent must be allowed to publish dead letters"
  }

  assert {
    condition     = length(google_pubsub_subscription_iam_member.dead_letter_forwarder) == 2
    error_message = "The Pub/Sub service agent must be allowed to forward from every subscription"
  }
}

run "schema_push_and_access" {
  command = apply

  module {
    source = "./modules/pubsub"
  }

  variables {
    schema_type            = "AVRO"
    schema_definition_file = "schemas/message.avsc"
    subscriptions = {
      webhook = {
        push_endpoint              = "https://orders.test.internal/events"
        push_service_account_email = "pusher@test-project-123.iam.gserviceaccount.com"
      }
    }
    publishers  = ["serviceAccount:orders@test-project-123.iam.gserviceaccount.com"]
    subscribers = ["serviceAccount:worker@test-project-123.iam.gserviceaccount.com"]
  }

  assert {
    condition     = google_pubsub_schema.main[0].type == "AVRO" && google_pubsub_topic.main.schema_settings[0].encoding == "JSON"
    error_message = "The topic must validate messages against the Avro schema"
  }

  assert {
    condition     = google_pubsub_subscription.main["webhook"].push_config[0].oidc_token[0].service_account_email == "pusher@test-project-123.iam.gserviceaccount.com"
    error_message = "Push deliveries must carry an OIDC token"
  }

  assert {
    condition     = length(google_pubsub_topic_iam_member.publisher) == 1
    error_message = "Listed publishers must be bound to the topic"
  }

  assert {
    condition     = length(google_pubsub_subscription_iam_member.subscriber) == 2
    error_message = "Listed subscribers must be bound to the subscription and the dead-letter subscription"
  }
}

run "protocol_buffer_schema" {
  command = plan

  module {
    source = "./modules/pubsub"
  }

  variables {
    schema_type            = "PROTOCOL_BUFFER"
    schema_definition_file = "schemas/message.proto"
    dead_letter_enabled    = false
  }

  assert {
    condition     = google_pubsub_schema.main[0].type == "PROTOCOL_BUFFER"
    error_message = "The schema must be a Protocol Buffers schema"
  }

  assert {
    condition     = length(google_pubsub_topic.dead_letter) == 0 && length(google_pubsub_subscription.main["worker"].dead_letter_policy) == 0
    error_message = "No dead-letter resources must exist when disabled"
  }
}

run "rejects_unauthenticated_push" {
  command = plan

  variables {
    subscriptions = {
      webhook = {
        push_endpoint = "https://orders.test.internal/events"
      }
    }
  }

  expect_failures = [var.subscriptions]
}

run "rejects_a_schema_without_a_definition" {
  command = plan

  variables {
    schema_type = "AVRO"
  }

  expect_failures = [var.schema_definition_file]
}
