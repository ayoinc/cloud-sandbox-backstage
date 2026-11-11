locals {
  # Short environment names keep generated names inside Google Cloud's limits
  # (a service account ID is at most 30 characters).
  environment_short = {
    dev        = "dev"
    staging    = "stg"
    production = "prod"
  }

  name_prefix   = "${var.project_name}-${local.environment_short[var.environment]}"
  is_production = var.environment == "production"

  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  runs_gke       = contains(["gke-autopilot", "gke-standard"], var.compute_type)
  runs_instances = var.compute_type == "mig"

  # A maximum below the minimum is raised to the minimum.
  max_nodes = max(var.min_nodes, var.max_nodes)

  # Ranges carved from vpc_cidr. For 10.0.0.0/16: nodes and instances
  # 10.0.0.0/20, GKE services 10.0.16.0/20, managed services (Cloud SQL)
  # 10.0.32.0/20, GKE pods 10.0.64.0/18.
  subnet_cidr           = cidrsubnet(var.vpc_cidr, 4, 0)
  services_cidr         = cidrsubnet(var.vpc_cidr, 4, 1)
  managed_services_cidr = cidrsubnet(var.vpc_cidr, 4, 2)
  pods_cidr             = cidrsubnet(var.vpc_cidr, 2, 1)

  pods_range_name     = "pods"
  services_range_name = "services"

  # Network tag of the instances, used as the target of the health check firewall rule.
  app_network_tag = "${local.name_prefix}-app"

  # Address ranges Google's load balancers and health checkers connect from.
  load_balancer_source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  required_services = concat(
    [
      "compute.googleapis.com",
      "iam.googleapis.com",
      "secretmanager.googleapis.com",
      "servicenetworking.googleapis.com",
      "sqladmin.googleapis.com",
    ],
    local.runs_gke ? ["container.googleapis.com"] : [],
  )
}

# -----------------------------------------------------------------------------
# Google APIs the stack uses
# -----------------------------------------------------------------------------

resource "google_project_service" "required" {
  for_each = toset(local.required_services)

  project = var.gcp_project_id
  service = each.value

  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# Network: one regional subnet for the application with secondary ranges for
# GKE, Cloud NAT for outbound traffic, and a peering range through which
# Cloud SQL gets a private address.
# -----------------------------------------------------------------------------

module "vpc" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/network/vpc?ref=${{ values.moduleRef }}"

  project_id  = var.gcp_project_id
  name        = var.project_name
  environment = var.environment
  region      = var.region

  subnets = {
    app = {
      ip_cidr_range = local.subnet_cidr
      secondary_ip_ranges = [
        {
          range_name    = local.pods_range_name
          ip_cidr_range = local.pods_cidr
        },
        {
          range_name    = local.services_range_name
          ip_cidr_range = local.services_cidr
        },
      ]
      log_config = {}
    }
  }

  enable_nat = true

  firewall_rules = {
    allow-lb = {
      description   = "Requests and health checks from Google's load balancers to the application"
      source_ranges = local.load_balancer_source_ranges
      target_tags   = local.runs_instances ? [local.app_network_tag] : []
      allow = [
        {
          protocol = "tcp"
          ports    = [tostring(var.container_port)]
        },
      ]
    }
  }

  labels = local.common_labels

  depends_on = [google_project_service.required]
}

resource "google_compute_global_address" "managed_services" {
  name          = "${local.name_prefix}-managed-services"
  description   = "Range Google-managed services such as Cloud SQL take their private addresses from"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = cidrhost(local.managed_services_cidr, 0)
  prefix_length = tonumber(split("/", local.managed_services_cidr)[1])
  network       = module.vpc.network_id
}

resource "google_service_networking_connection" "managed_services" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.managed_services.name]

  depends_on = [google_project_service.required]
}

# -----------------------------------------------------------------------------
# Identity of the application: the service account of the instances or GKE
# nodes. On GKE, pods use it through Workload Identity.
# -----------------------------------------------------------------------------

module "app_service_account" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.name_prefix}-app"
  display_name = "${var.project_name} ${var.environment} application"
  description  = "Runs the application tier and reads the database through Cloud SQL"

  project_roles = concat(
    [
      "roles/artifactregistry.reader",
      "roles/cloudsql.client",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ],
    local.runs_gke ? ["roles/container.defaultNodeServiceAccount"] : [],
  )

  depends_on = [google_project_service.required]
}
