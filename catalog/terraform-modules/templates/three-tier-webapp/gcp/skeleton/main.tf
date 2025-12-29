terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
  }

  backend "gcs" {
    bucket = "${{ values.projectName }}-terraform-state"
    prefix = "${{ values.environment }}"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.region
}

locals {
  name_prefix = "${{ values.projectName }}-${{ values.environment }}"
  
  common_labels = {
    project     = "${{ values.projectName }}"
    environment = "${{ values.environment }}"
    managed_by  = "terraform"
  }
}

# VPC Network
module "vpc" {
  source = "../../gcp/resources/network/vpc"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  network_name = "${local.name_prefix}-vpc"
  
  subnets = [
    {
      name          = "${local.name_prefix}-public"
      ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 0)
      region        = var.region
      purpose       = "public"
    },
    {
      name          = "${local.name_prefix}-private"
      ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 1)
      region        = var.region
      purpose       = "private"
    },
    {
      name          = "${local.name_prefix}-database"
      ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 2)
      region        = var.region
      purpose       = "database"
    }
  ]

  enable_nat_gateway = true
  
  labels = local.common_labels
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  name    = "${local.name_prefix}-router"
  project = var.gcp_project_id
  region  = var.region
  network = module.vpc.network_id
}

resource "google_compute_router_nat" "main" {
  name                               = "${local.name_prefix}-nat"
  project                            = var.gcp_project_id
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

{%- if values.computeType == "gke-autopilot" or values.computeType == "gke-standard" %}
# GKE Cluster
module "gke" {
  source = "../../gcp/resources/kubernetes/gke"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  cluster_name = "${local.name_prefix}-cluster"
  location     = var.region
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_names[1]  # private subnet

  {%- if values.computeType == "gke-autopilot" %}
  enable_autopilot = true
  {%- else %}
  enable_autopilot = false
  
  node_pools = [
    {
      name           = "default-pool"
      machine_type   = var.machine_type
      min_node_count = var.min_nodes
      max_node_count = var.max_nodes
      disk_size_gb   = 100
      disk_type      = "pd-standard"
      preemptible    = var.environment != "production"
    }
  ]
  {%- endif %}

  master_ipv4_cidr_block = "172.16.0.0/28"
  
  enable_private_nodes    = true
  enable_private_endpoint = false
  
  master_authorized_networks = var.authorized_networks

  labels = local.common_labels
}
{%- endif %}

{%- if values.computeType == "mig" %}
# Managed Instance Group
module "mig" {
  source = "../../gcp/resources/compute/mig"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name        = "${local.name_prefix}-mig"
  region      = var.region
  
  machine_type = var.machine_type
  
  source_image         = var.source_image
  source_image_family  = var.source_image_family
  source_image_project = var.source_image_project
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_names[1]  # private subnet
  
  target_size = var.min_nodes
  
  autoscaling_config = {
    min_replicas    = var.min_nodes
    max_replicas    = var.max_nodes
    cooldown_period = 60
    cpu_target      = 0.6
  }

  named_ports = [
    {
      name = "http"
      port = 80
    }
  ]

  health_check = {
    type                = "http"
    port                = 80
    request_path        = "/health"
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  labels = local.common_labels
}
{%- endif %}

# Global Load Balancer
module "load_balancer" {
  source = "../../gcp/resources/network/load-balancer"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name = "${local.name_prefix}-lb"
  
  {%- if values.computeType == "mig" %}
  backend_type = "INSTANCE_GROUP"
  backends = [
    {
      group           = module.mig.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
  {%- else %}
  backend_type = "NEG"
  backends = [
    {
      group           = google_compute_network_endpoint_group.gke_neg.id
      balancing_mode  = "RATE"
      max_rate        = 10000
    }
  ]
  {%- endif %}

  health_check = {
    request_path = "/health"
    port         = 80
  }

  enable_cdn = ${{ values.enableCloudCdn }}
  
  ssl_certificates = var.ssl_certificate != "" ? [var.ssl_certificate] : []

  labels = local.common_labels
}

{%- if values.computeType != "mig" %}
# Network Endpoint Group for GKE
resource "google_compute_network_endpoint_group" "gke_neg" {
  name         = "${local.name_prefix}-neg"
  project      = var.gcp_project_id
  network      = module.vpc.network_id
  subnetwork   = module.vpc.subnet_ids[1]
  default_port = 80
  zone         = "${var.region}-a"
}
{%- endif %}

{%- if values.enableCloudArmor %}
# Cloud Armor Security Policy
module "cloud_armor" {
  source = "../../gcp/resources/security/cloud-armor"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name = "${local.name_prefix}-armor"

  default_rule_action = "allow"

  rules = [
    {
      action      = "deny(403)"
      priority    = 1000
      expression  = "evaluatePreconfiguredExpr('xss-stable')"
      description = "Block XSS attacks"
    },
    {
      action      = "deny(403)"
      priority    = 1001
      expression  = "evaluatePreconfiguredExpr('sqli-stable')"
      description = "Block SQL injection attacks"
    },
    {
      action      = "deny(403)"
      priority    = 1002
      expression  = "evaluatePreconfiguredExpr('rce-stable')"
      description = "Block remote code execution"
    },
    {
      action          = "throttle"
      priority        = 2000
      expression      = "true"
      description     = "Rate limiting"
      rate_limit_options = {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        rate_limit_threshold = {
          count        = 1000
          interval_sec = 60
        }
      }
    }
  ]
}

resource "google_compute_backend_service_security_policy" "main" {
  provider        = google-beta
  project         = var.gcp_project_id
  backend_service = module.load_balancer.backend_service_id
  security_policy = module.cloud_armor.policy_id
}
{%- endif %}

# Cloud SQL Database
module "cloud_sql" {
  source = "../../gcp/resources/database/cloud-sql"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name             = "${local.name_prefix}-db"
  database_version = "${{ values.databaseEngine }}_15"
  region           = var.region
  
  tier = var.database_tier

  availability_type = ${{ values.highAvailability }} ? "REGIONAL" : "ZONAL"

  network = module.vpc.network_id
  
  enable_private_ip = true
  require_ssl       = true

  database_name = replace(var.project_name, "-", "_")
  
  backup_configuration = {
    enabled                        = true
    binary_log_enabled             = "${{ values.databaseEngine }}" == "MYSQL"
    start_time                     = "03:00"
    location                       = var.region
    point_in_time_recovery_enabled = var.environment == "production"
    transaction_log_retention_days = var.environment == "production" ? 7 : 1
    retained_backups               = var.environment == "production" ? 30 : 7
  }

  maintenance_window = {
    day          = 7  # Sunday
    hour         = 4
    update_track = "stable"
  }

  deletion_protection = var.environment == "production"

  labels = local.common_labels
}

# Firewall Rules
resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "${local.name_prefix}-allow-lb-hc"
  project = var.gcp_project_id
  network = module.vpc.network_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]  # GCP Load Balancer ranges
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name_prefix}-allow-internal"
  project = var.gcp_project_id
  network = module.vpc.network_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
}

# Secret Manager for Database Credentials
resource "google_secret_manager_secret" "db_password" {
  project   = var.gcp_project_id
  secret_id = "${local.name_prefix}-db-password"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.database_password
}
