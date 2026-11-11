# -----------------------------------------------------------------------------
# Network: one private subnet with Private Google Access and Cloud NAT. Pipeline
# workers, Airflow and the Workbench instance have no public addresses.
# -----------------------------------------------------------------------------

module "network" {
  count  = local.needs_network ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/network/vpc?ref=${{ values.moduleRef }}"

  project_id  = var.gcp_project_id
  name        = var.project_name
  environment = var.environment
  region      = var.region

  subnets = {
    data = {
      ip_cidr_range = var.subnet_cidr
      log_config = {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.5
      }
    }
  }

  enable_nat = true

  depends_on = [google_project_service.apis]
}
