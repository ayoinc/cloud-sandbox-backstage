locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  is_production = var.environment == "production"

  cluster_name = "${local.name_prefix}-gke"
  cluster_host = "https://${google_container_cluster.this.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint}"

  # Service account IDs are limited to 30 characters, so they carry a short form of the environment.
  environment_short = { dev = "dev", staging = "stg", production = "prod" }
  account_prefix    = "${var.project_name}-${local.environment_short[var.environment]}"

  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Machine type behind each node size of the form: 2 vCPU / 4 GB, 4 vCPU / 16 GB, 8 vCPU / 32 GB.
  node_machine_types = {
    small  = "e2-custom-2-4096"
    medium = "e2-standard-4"
    large  = "e2-standard-8"
  }

  # A regional cluster runs its nodes in three zones of the region.
  node_zone_count = 3

  # The pool never has fewer nodes than node_min_count, so a smaller maximum is raised to it.
  node_max_count = max(var.node_min_count, var.node_max_count)

  # Network tag of the nodes, the target of the firewall rule for the control plane.
  node_network_tag = "${local.cluster_name}-node"

  # Names of the secondary ranges of the cluster subnet.
  pods_range_name     = "pods"
  services_range_name = "services"

  # Kubernetes service accounts of the cluster are known to IAM as members of this pool.
  workload_identity_pool = "${var.gcp_project_id}.svc.id.goog"

  # APIs the stack calls. Cloud DNS is only needed for external-dns.
  required_apis = toset(concat(
    [
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "logging.googleapis.com",
      "monitoring.googleapis.com",
    ],
    var.enable_external_dns ? ["dns.googleapis.com"] : [],
  ))

  # What the platform components in platform*.tf need to know about this cloud.
  cloud = {
    name         = "gcp"
    cluster_name = google_container_cluster.this.name

    # GKE Dataplane V2 enforces NetworkPolicy objects; the cluster uses it when network policies are enabled
    # (cluster.tf).
    network_policy_enforced = var.enable_network_policies

    external_dns = {
      provider = "google"
      service_account_annotations = var.enable_external_dns ? {
        "iam.gke.io/gcp-service-account" = module.external_dns_identity[0].service_account_email
      } : {}
      values = {
        extraArgs = {
          google-project = var.gcp_project_id
        }
      }
    }

    # An external passthrough Network Load Balancer built on a regional backend service.
    ingress_service_annotations = {
      "cloud.google.com/l4-rbs" = "enabled"
    }

    # Balanced persistent disks through the Compute Engine persistent disk CSI driver. GKE creates this class.
    storage_class = "standard-rwo"
  }
}

resource "google_project_service" "required" {
  for_each = local.required_apis

  project = var.gcp_project_id
  service = each.value

  # Other workloads of the project may use the same APIs.
  disable_on_destroy = false
}
