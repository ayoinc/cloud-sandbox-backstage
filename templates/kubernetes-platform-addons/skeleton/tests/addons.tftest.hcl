# Plans the configuration against mocked providers: no cluster is needed.
#   terraform init -backend=false && terraform test

mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  name               = "test-cluster"
  environment        = "dev"
  description        = "Add-ons used by the tests"
  owner              = "group:default/platform-team"
  acme_email         = "platform-team@tests.invalid"
  dns_domain_filters = ["tests.invalid"]
  dns_api_token      = "token-used-by-the-tests"
}

run "installs_every_add_on_by_default" {
  command = plan

  assert {
    condition     = length(helm_release.traefik) == 1 && length(helm_release.cert_manager) == 1 && length(helm_release.external_dns) == 1 && length(helm_release.metrics_server) == 1
    error_message = "All four add-ons must be installed by default."
  }

  assert {
    condition     = toset(keys(kubernetes_namespace_v1.this)) == toset(["traefik", "cert-manager", "external-dns"])
    error_message = "Every add-on outside kube-system must get its own namespace."
  }

  assert {
    condition     = alltrue([for namespace in kubernetes_namespace_v1.this : namespace.metadata[0].labels["pod-security.kubernetes.io/enforce"] == "baseline"])
    error_message = "The namespaces must enforce the baseline Pod Security Standard."
  }

  assert {
    condition     = helm_release.traefik[0].version == "42.3.1" && helm_release.cert_manager[0].version == "v1.21.3"
    error_message = "Chart versions must be pinned."
  }
}

run "redirects_http_and_hides_the_dashboard" {
  command = plan

  assert {
    condition     = yamldecode(helm_release.traefik[0].values[0]).ports.web.http.redirections.entryPoint.scheme == "https"
    error_message = "HTTP must be redirected to HTTPS."
  }

  assert {
    condition     = yamldecode(helm_release.traefik[0].values[0]).ingressRoute.dashboard.enabled == false
    error_message = "The Traefik dashboard must not be exposed."
  }
}

run "external_dns_reads_the_token_from_a_secret" {
  command = plan

  assert {
    condition     = length(kubernetes_secret_v1.dns_credentials) == 1
    error_message = "The cloudflare provider needs the credentials Secret."
  }

  assert {
    condition     = yamldecode(helm_release.external_dns[0].values[0]).env[0].name == "CF_API_TOKEN"
    error_message = "ExternalDNS must read the Cloudflare token from the Secret."
  }

  assert {
    condition     = !strcontains(helm_release.external_dns[0].values[0], "token-used-by-the-tests")
    error_message = "The token itself must never be part of the Helm values."
  }

  assert {
    condition     = yamldecode(helm_release.external_dns[0].values[0]).policy == "upsert-only"
    error_message = "ExternalDNS must not delete records by default."
  }
}

run "cloud_providers_use_workload_identity" {
  command = plan

  variables {
    dns_provider = "aws"
    dns_service_account_annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::111122223333:role/external-dns"
    }
  }

  assert {
    condition     = length(kubernetes_secret_v1.dns_credentials) == 0
    error_message = "No token Secret may be created for a provider that uses workload identity."
  }

  assert {
    condition     = length(yamldecode(helm_release.external_dns[0].values[0]).env) == 0
    error_message = "No token variable may be set for a provider that uses workload identity."
  }
}

run "runs_two_replicas_when_highly_available" {
  command = plan

  variables {
    high_availability = true
  }

  assert {
    condition     = yamldecode(helm_release.traefik[0].values[0]).deployment.replicas == 2 && yamldecode(helm_release.traefik[0].values[0]).podDisruptionBudget.enabled
    error_message = "Traefik must run two replicas with a pod disruption budget."
  }

  assert {
    condition     = yamldecode(helm_release.metrics_server[0].values[0]).replicas == 2
    error_message = "Metrics Server must run two replicas."
  }
}

run "installs_only_what_is_enabled" {
  command = plan

  variables {
    enable_ingress        = false
    enable_external_dns   = false
    enable_metrics_server = false
  }

  assert {
    condition     = keys(kubernetes_namespace_v1.this) == ["cert-manager"]
    error_message = "Only the namespace of the enabled add-on may be created."
  }

  assert {
    condition     = length(output.cluster_issuers) == 2 && contains(output.cluster_issuers, "letsencrypt-production")
    error_message = "cert-manager must come with both Let's Encrypt ClusterIssuers."
  }
}

run "requires_the_token_of_a_token_provider" {
  command = plan

  variables {
    dns_provider  = "digitalocean"
    dns_api_token = ""
  }

  expect_failures = [kubernetes_secret_v1.dns_credentials]
}

run "rejects_an_invalid_contact_address" {
  command = plan

  variables {
    acme_email = "not-an-address"
  }

  expect_failures = [var.acme_email]
}
