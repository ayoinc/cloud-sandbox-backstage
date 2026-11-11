# Plans the configuration against mocked providers: no Cloudflare account is
# needed.   terraform init -backend=false && terraform test

mock_provider "cloudflare" {}
mock_provider "random" {}

variables {
  account_id  = "0123456789abcdef0123456789abcdef"
  name        = "test-worker"
  environment = "dev"
}

run "binds_a_d1_database_by_default" {
  command = plan

  assert {
    condition     = cloudflare_workers_script.this.script_name == "test-worker-dev"
    error_message = "The Worker must be named <name>-<environment>."
  }

  assert {
    condition     = length(cloudflare_d1_database.this) == 1 && length(cloudflare_workers_kv_namespace.this) == 0
    error_message = "The default data store is a D1 database."
  }

  assert {
    condition     = [for binding in local.bindings : binding.name] == ["BUCKET", "DB", "ENVIRONMENT", "API_TOKEN"]
    error_message = "The Worker must be bound to the bucket, the database, the environment and the token."
  }

  assert {
    condition     = cloudflare_r2_bucket.this.name == "test-worker-dev"
    error_message = "The bucket must be named after the Worker."
  }
}

run "binds_a_kv_namespace" {
  command = plan

  variables {
    data_store = "kv"
  }

  assert {
    condition     = length(cloudflare_d1_database.this) == 0 && length(cloudflare_workers_kv_namespace.this) == 1
    error_message = "With the kv data store only a KV namespace must be created."
  }

  assert {
    condition     = [for binding in local.bindings : binding.name] == ["BUCKET", "KV", "ENVIRONMENT", "API_TOKEN"]
    error_message = "The Worker must be bound to the KV namespace."
  }
}

run "is_private_by_default" {
  command = plan

  assert {
    condition     = cloudflare_workers_script_subdomain.this.enabled == false
    error_message = "The workers.dev address must be opt-in."
  }

  assert {
    condition     = length(cloudflare_workers_custom_domain.this) == 0 && length(cloudflare_workers_route.this) == 0
    error_message = "No hostname or route may exist unless one is configured."
  }
}

run "serves_a_custom_hostname_and_routes" {
  command = plan

  variables {
    custom_hostname = "api.tests.invalid"
    routes = [
      {
        pattern = "tests.invalid/api/*"
        zone_id = "fedcba9876543210fedcba9876543210"
      },
    ]
  }

  assert {
    condition     = cloudflare_workers_custom_domain.this[0].hostname == "api.tests.invalid"
    error_message = "The custom hostname must be attached to the Worker."
  }

  assert {
    condition     = cloudflare_workers_route.this["tests.invalid/api/*"].script == "test-worker-dev"
    error_message = "The route must send its traffic to the Worker."
  }

  assert {
    condition     = output.url == "https://api.tests.invalid"
    error_message = "The URL output must be the custom hostname."
  }
}

run "rejects_an_unknown_data_store" {
  command = plan

  variables {
    data_store = "redis"
  }

  expect_failures = [var.data_store]
}
