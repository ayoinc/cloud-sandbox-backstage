# =============================================================================
# Cloudflare Workers - Worker, storage and routing
# =============================================================================

locals {
  worker_name = "${var.name}-${var.environment}"
  worker_file = "${path.module}/worker/index.mjs"

  # Every binding has the same attributes so the list has one type; the
  # attributes a binding type does not use stay null.
  candidate_bindings = [
    {
      enabled      = true
      name         = "BUCKET"
      type         = "r2_bucket"
      bucket_name  = cloudflare_r2_bucket.this.name
      id           = null
      namespace_id = null
      text         = null
    },
    {
      enabled      = var.data_store == "d1"
      name         = "DB"
      type         = "d1"
      bucket_name  = null
      id           = one(cloudflare_d1_database.this[*].id)
      namespace_id = null
      text         = null
    },
    {
      enabled      = var.data_store == "kv"
      name         = "KV"
      type         = "kv_namespace"
      bucket_name  = null
      id           = null
      namespace_id = one(cloudflare_workers_kv_namespace.this[*].id)
      text         = null
    },
    {
      enabled      = true
      name         = "ENVIRONMENT"
      type         = "plain_text"
      bucket_name  = null
      id           = null
      namespace_id = null
      text         = var.environment
    },
    {
      enabled      = true
      name         = "API_TOKEN"
      type         = "secret_text"
      bucket_name  = null
      id           = null
      namespace_id = null
      text         = random_password.api_token.result
    },
  ]

  bindings = [
    for binding in local.candidate_bindings : {
      name         = binding.name
      type         = binding.type
      bucket_name  = binding.bucket_name
      id           = binding.id
      namespace_id = binding.namespace_id
      text         = binding.text
    } if binding.enabled
  ]
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

resource "cloudflare_r2_bucket" "this" {
  account_id    = var.account_id
  name          = local.worker_name
  location      = var.r2_location
  storage_class = "Standard"
}

resource "cloudflare_d1_database" "this" {
  count = var.data_store == "d1" ? 1 : 0

  account_id            = var.account_id
  name                  = local.worker_name
  primary_location_hint = var.r2_location
}

resource "cloudflare_workers_kv_namespace" "this" {
  count = var.data_store == "kv" ? 1 : 0

  account_id = var.account_id
  title      = local.worker_name
}

# -----------------------------------------------------------------------------
# Worker
# -----------------------------------------------------------------------------

# Bearer token the Worker requires on every data request. It is generated here
# so that no person has to handle it; read it with `terraform output -raw api_token`.
resource "random_password" "api_token" {
  length  = 48
  special = false
}

resource "cloudflare_workers_script" "this" {
  account_id  = var.account_id
  script_name = local.worker_name

  main_module    = "index.mjs"
  content_file   = local.worker_file
  content_sha256 = filesha256(local.worker_file)

  compatibility_date  = var.compatibility_date
  compatibility_flags = ["nodejs_compat"]

  bindings = local.bindings

  observability = {
    enabled            = true
    head_sampling_rate = var.log_sampling_rate
    logs = {
      enabled         = true
      invocation_logs = true
    }
  }
}

# -----------------------------------------------------------------------------
# Routing
# -----------------------------------------------------------------------------

resource "cloudflare_workers_script_subdomain" "this" {
  account_id       = var.account_id
  script_name      = cloudflare_workers_script.this.script_name
  enabled          = var.workers_dev_enabled
  previews_enabled = false
}

resource "cloudflare_workers_custom_domain" "this" {
  count = var.custom_hostname != "" ? 1 : 0

  account_id = var.account_id
  hostname   = var.custom_hostname
  service    = cloudflare_workers_script.this.script_name
}

resource "cloudflare_workers_route" "this" {
  for_each = { for route in var.routes : route.pattern => route }

  zone_id = each.value.zone_id
  pattern = each.value.pattern
  script  = cloudflare_workers_script.this.script_name
}
