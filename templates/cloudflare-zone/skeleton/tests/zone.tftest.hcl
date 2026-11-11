# Plans the configuration against a mocked provider: no Cloudflare account is
# needed.   terraform init -backend=false && terraform test

mock_provider "cloudflare" {}

variables {
  account_id  = "0123456789abcdef0123456789abcdef"
  zone_name   = "tests.invalid"
  description = "Zone used by the tests"
  owner       = "group:default/platform-team"
  dns_records = {
    apex = {
      name    = "tests.invalid"
      type    = "A"
      content = "192.0.2.10"
      proxied = true
    }
    mail = {
      name     = "tests.invalid"
      type     = "MX"
      content  = "mail.tests.invalid"
      priority = 10
      ttl      = 3600
    }
  }
}

run "creates_a_hardened_zone" {
  command = plan

  assert {
    condition     = length(cloudflare_zone.this) == 1
    error_message = "The zone must be created when no zone ID is given."
  }

  assert {
    condition     = cloudflare_zone_setting.this["ssl"].value == "strict"
    error_message = "The origin connection must use strict TLS by default."
  }

  assert {
    condition     = cloudflare_zone_setting.this["min_tls_version"].value == "1.2"
    error_message = "TLS 1.2 must be the default minimum."
  }

  assert {
    condition     = cloudflare_zone_setting.this["always_use_https"].value == "on"
    error_message = "HTTP must be redirected to HTTPS."
  }

  assert {
    condition     = cloudflare_zone_dnssec.this[0].status == "active"
    error_message = "DNSSEC must be enabled by default."
  }

  assert {
    condition     = length(cloudflare_ruleset.managed_waf) == 0
    error_message = "The managed rulesets need a paid plan and must be opt-in."
  }
}

run "proxied_records_use_the_automatic_ttl" {
  command = plan

  assert {
    condition     = cloudflare_dns_record.this["apex"].ttl == 1
    error_message = "A proxied record must use the automatic TTL."
  }

  assert {
    condition     = cloudflare_dns_record.this["mail"].ttl == 3600
    error_message = "An unproxied record must keep its TTL."
  }
}

run "manages_an_existing_zone" {
  command = plan

  variables {
    zone_id = "fedcba9876543210fedcba9876543210"
  }

  assert {
    condition     = length(cloudflare_zone.this) == 0
    error_message = "No zone may be created when a zone ID is given."
  }

  assert {
    condition     = output.zone_id == "fedcba9876543210fedcba9876543210"
    error_message = "The given zone must be the one that is managed."
  }
}

run "deploys_the_managed_rulesets_on_paid_plans" {
  command = plan

  variables {
    enable_managed_waf = true
  }

  assert {
    condition     = length(cloudflare_ruleset.managed_waf[0].rules) == 2
    error_message = "Both the Cloudflare Managed and the OWASP Core ruleset must be executed."
  }
}

run "rejects_unencrypted_origin_traffic" {
  command = plan

  variables {
    ssl_mode = "flexible"
  }

  expect_failures = [var.ssl_mode]
}

run "rejects_deprecated_tls_versions" {
  command = plan

  variables {
    min_tls_version = "1.0"
  }

  expect_failures = [var.min_tls_version]
}
