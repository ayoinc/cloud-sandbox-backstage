# =============================================================================
# Production Environment
# =============================================================================
# Production settings.
# =============================================================================

name        = "${{ values.name }}"
environment = "prod"
project_id  = "${{ values.gcpProject }}"
region      = "${{ values.region }}"
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'prod' -%}
# Topic{% if fromForm %} (from the template form){% endif %}
message_retention_duration  = "${{ values.messageRetention if fromForm else '604800s' }}"
allowed_persistence_regions = []
kms_key_name                = null

# Schema: NONE, AVRO (schemas/message.avsc) or PROTOCOL_BUFFER (schemas/message.proto)
schema_type            = "${{ values.schemaType }}"
schema_definition_file = ${{ {'AVRO': '"schemas/message.avsc"', 'PROTOCOL_BUFFER': '"schemas/message.proto"'}[values.schemaType] or 'null' }}
schema_encoding        = "JSON"

# Subscriptions by short name. Add push_endpoint and push_service_account_email
# for push delivery; filter, ordering and exactly-once delivery are optional too.
subscriptions = {
{%- for subscription in values.subscriptions %}
  "${{ subscription }}" = {
    ack_deadline_seconds = 30
  }
{%- endfor %}
}

# Dead letters
dead_letter_enabled   = ${{ 'true' if values.deadLetter else 'false' }}
max_delivery_attempts = ${{ values.maxDeliveryAttempts }}

# Access: IAM members such as "serviceAccount:name@project.iam.gserviceaccount.com"
publishers  = []
subscribers = []

enable_apis = true

labels = {
  cost-center = "production"
  criticality = "high"
}
