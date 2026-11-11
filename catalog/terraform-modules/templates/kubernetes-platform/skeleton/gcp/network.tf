# -----------------------------------------------------------------------------
# Network: one subnet for the nodes with secondary ranges for pods and Services.
# Nodes have no public addresses and reach the internet through Cloud NAT.
# -----------------------------------------------------------------------------

module "vpc" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/network/vpc?ref=${{ values.moduleRef }}"

  project_id   = var.gcp_project_id
  name         = var.project_name
  environment  = var.environment
  region       = var.region
  routing_mode = "REGIONAL"

  subnets = {
    gke = {
      ip_cidr_range = var.subnet_cidr

      secondary_ip_ranges = [
        { range_name = local.pods_range_name, ip_cidr_range = var.pods_cidr },
        { range_name = local.services_range_name, ip_cidr_range = var.services_cidr },
      ]

      # A tenth of the flows, aggregated over ten minutes, is logged.
      log_config = {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.1
      }
    }
  }

  # The router and the NAT gateway are declared below.
  enable_nat = false

  # GKE lets the control plane reach the nodes on ports 443 and 10250 only. Admission webhooks of the platform
  # components listen on other ports, which this rule opens for the control plane.
  firewall_rules = {
    gke-webhooks = {
      description   = "Control plane of ${local.cluster_name} to admission webhooks on the nodes"
      source_ranges = [var.master_ipv4_cidr_block]
      target_tags   = [local.node_network_tag]
      allow         = [{ protocol = "tcp", ports = var.control_plane_webhook_ports }]
    }
  }

  depends_on = [google_project_service.required]
}

module "router" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/network/cloud-router?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment
  region       = var.region

  name        = "${local.name_prefix}-router"
  network     = module.vpc.network_self_link
  description = "Router of the NAT gateway of ${local.name_prefix}"
}

# Outbound internet access of the nodes and pods, for example to pull images from registries outside Google Cloud.
module "nat" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/network/cloud-nat?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment
  region       = var.region

  nat_name    = "${local.name_prefix}-nat"
  router_name = "${local.name_prefix}-router"

  # Covers the node, pod and Service ranges of the cluster subnet.
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # A node shares its NAT ports among all its pods, so the number of ports grows with the connections it opens.
  enable_dynamic_port_allocation = true
  min_ports_per_vm               = 64
  max_ports_per_vm               = 4096

  log_config_enable = true
  log_config_filter = "ERRORS_ONLY"

  # The router module has no output for the router's name, so the dependency is declared here.
  depends_on = [module.router]
}
