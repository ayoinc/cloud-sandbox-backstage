# -----------------------------------------------------------------------------
# Identity of the nodes
# -----------------------------------------------------------------------------

# The nodes run as their own service account, which may only write logs and metrics and pull images from
# Artifact Registry, instead of the Compute Engine default service account.
module "node_identity" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.account_prefix}-nodes"
  display_name = "Nodes of ${local.cluster_name}"
  description  = "Service account of the nodes of the GKE cluster ${local.cluster_name}"

  project_roles = [
    "roles/container.defaultNodeServiceAccount",
    "roles/artifactregistry.reader",
  ]

  depends_on = [google_project_service.required]
}

# -----------------------------------------------------------------------------
# Identity of external-dns
# -----------------------------------------------------------------------------

# Workload Identity lets the Kubernetes service account external-dns in namespace external-dns act as this Google
# service account, which may change record sets in the Cloud DNS zones of the project.
module "external_dns_identity" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"
  count  = var.enable_external_dns ? 1 : 0

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.account_prefix}-dns"
  display_name = "external-dns of ${local.cluster_name}"
  description  = "Used by external-dns in the GKE cluster ${local.cluster_name} to manage Cloud DNS records"

  project_roles = ["roles/dns.admin"]

  impersonators = [{
    member = "serviceAccount:${local.workload_identity_pool}[external-dns/external-dns]"
    role   = "roles/iam.workloadIdentityUser"
  }]

  # The workload identity pool of the project exists once a cluster uses it.
  depends_on = [google_container_cluster.this]
}
