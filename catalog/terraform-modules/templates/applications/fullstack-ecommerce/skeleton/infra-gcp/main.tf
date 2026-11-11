locals {
  name = "${var.project_name}-${var.environment}"

  labels = {
    project       = var.project_name
    environment   = var.environment
    business-unit = var.business_unit
    managed-by    = "terraform"
  }

  max_replicas = var.enable_autoscaling ? var.max_replicas : var.min_replicas
  production   = var.environment == "prod"

  # Cloud Run pulls the images through the Artifact Registry repository below.
  image_prefix = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ghcr.repository_id}"
}

resource "google_project_service" "services" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "redis.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# Cloud Run cannot pull from the GitHub Container Registry directly. This
# repository fetches the images from there on first use and keeps a copy.
resource "google_artifact_registry_repository" "ghcr" {
  location      = var.region
  repository_id = "${local.name}-ghcr"
  description   = "Images of ${local.name}, fetched from ghcr.io"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  labels        = local.labels

  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }
  }

  depends_on = [google_project_service.services]
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

resource "random_password" "database" {
  length  = 32
  special = false
}

# The name of a deleted Cloud SQL instance stays reserved for a week, so
# every instance gets a name of its own.
resource "random_id" "database" {
  byte_length = 3
}

resource "google_sql_database_instance" "main" {
  name                = "${local.name}-${random_id.database.hex}"
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = local.production

  settings {
    tier              = var.database_tier
    edition           = "ENTERPRISE"
    availability_type = local.production ? "REGIONAL" : "ZONAL"
    user_labels       = local.labels

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = local.production
    }
  }

  depends_on = [google_project_service.services]
}

resource "google_sql_database" "store" {
  name     = "store"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "store" {
  name     = "store"
  instance = google_sql_database_instance.main.name
  password = random_password.database.result
}

# ---------------------------------------------------------------------------
# Cache, reached from Cloud Run through a VPC connector
# ---------------------------------------------------------------------------

data "google_compute_network" "default" {
  name = "default"

  depends_on = [google_project_service.services]
}

resource "google_redis_instance" "main" {
  count = var.enable_cache ? 1 : 0

  name               = local.name
  region             = var.region
  tier               = local.production ? "STANDARD_HA" : "BASIC"
  memory_size_gb     = 1
  authorized_network = data.google_compute_network.default.id
  labels             = local.labels

  depends_on = [google_project_service.services]
}

resource "google_vpc_access_connector" "main" {
  count = var.enable_cache ? 1 : 0

  # Connector names are limited to 25 characters.
  name          = "store-${var.environment}"
  region        = var.region
  network       = data.google_compute_network.default.name
  ip_cidr_range = "10.8.0.0/28"
  min_instances = 2
  max_instances = 3

  depends_on = [google_project_service.services]
}

# ---------------------------------------------------------------------------
# Secrets of the API
# ---------------------------------------------------------------------------

resource "random_password" "admin_token" {
  length  = 40
  special = false
}

locals {
  secrets = {
    database-url = "postgres://store:${random_password.database.result}@localhost/store?host=/cloudsql/${google_sql_database_instance.main.connection_name}"
    admin-token  = random_password.admin_token.result
  }
}

resource "google_secret_manager_secret" "main" {
  for_each = toset(keys(local.secrets))

  secret_id = "${local.name}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.services]
}

resource "google_secret_manager_secret_version" "main" {
  for_each = google_secret_manager_secret.main

  secret      = each.value.id
  secret_data = local.secrets[each.key]
}

resource "google_service_account" "backend" {
  account_id   = "store-backend-${var.environment}"
  display_name = "API of ${local.name}"
}

resource "google_secret_manager_secret_iam_member" "backend" {
  for_each = google_secret_manager_secret.main

  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.backend.member
}

resource "google_project_iam_member" "backend_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.backend.member
}

# ---------------------------------------------------------------------------
# Containers on Cloud Run
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "backend" {
  name                = "${local.name}-backend"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  labels              = local.labels

  template {
    service_account = google_service_account.backend.email

    scaling {
      min_instance_count = var.min_replicas
      max_instance_count = local.max_replicas
    }

    dynamic "vpc_access" {
      for_each = google_vpc_access_connector.main
      content {
        connector = vpc_access.value.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    # Makes the database reachable as a socket in /cloudsql.
    volumes {
      name = "cloudsql"

      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = "${local.image_prefix}/${trimprefix(var.backend_image, "ghcr.io/")}"

      ports {
        container_port = 8080
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.main["database-url"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "ADMIN_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.main["admin-token"].secret_id
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = google_redis_instance.main
        content {
          name  = "REDIS_URL"
          value = "redis://${env.value.host}:${env.value.port}"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      startup_probe {
        http_get {
          path = "/readyz"
        }
      }

      liveness_probe {
        http_get {
          path = "/healthz"
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_version.main,
    google_secret_manager_secret_iam_member.backend,
    google_project_iam_member.backend_sql,
    google_sql_database.store,
    google_sql_user.store,
  ]
}

resource "google_cloud_run_v2_service" "frontend" {
  name                = "${local.name}-frontend"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  labels              = local.labels

  template {
    scaling {
      min_instance_count = var.min_replicas
      max_instance_count = local.max_replicas
    }

    containers {
      image = "${local.image_prefix}/${trimprefix(var.frontend_image, "ghcr.io/")}"

      ports {
        container_port = 8080
      }

      env {
        name  = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }
  }
}

# Both services answer anyone: the storefront is public, and it calls the API
# without credentials. The admin API has its own token.
resource "google_cloud_run_v2_service_iam_member" "public" {
  for_each = {
    backend  = google_cloud_run_v2_service.backend.name
    frontend = google_cloud_run_v2_service.frontend.name
  }

  name     = each.value
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------------------------------------------------------------------
# Content delivery network: a global load balancer with Cloud CDN in front of
# the storefront
# ---------------------------------------------------------------------------

resource "google_compute_region_network_endpoint_group" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                  = "${local.name}-frontend"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.frontend.name
  }
}

resource "google_compute_backend_service" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                  = "${local.name}-frontend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = true

  # Caches what the storefront's Cache-Control headers allow: hashed assets
  # for a year, pages and API answers not at all.
  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"

    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }

  backend {
    group = google_compute_region_network_endpoint_group.frontend[0].id
  }
}

resource "google_compute_url_map" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name            = "${local.name}-frontend"
  default_service = google_compute_backend_service.frontend[0].id
}

# Plain HTTP on the address below. For HTTPS, point a domain at the address
# and add a managed certificate with an HTTPS proxy.
resource "google_compute_target_http_proxy" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name    = "${local.name}-frontend"
  url_map = google_compute_url_map.frontend[0].id
}

resource "google_compute_global_address" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name = "${local.name}-frontend"

  depends_on = [google_project_service.services]
}

resource "google_compute_global_forwarding_rule" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                  = "${local.name}-frontend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.frontend[0].id
  port_range            = "80"
  target                = google_compute_target_http_proxy.frontend[0].id
}
