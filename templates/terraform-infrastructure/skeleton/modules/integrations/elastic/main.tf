# Newest Elastic Stack version offered in the region.
data "ec_stack" "latest" {
  version_regex = "latest"
  region        = local.elastic_region
}

locals {
  # Limits of the Elastic Cloud tags API. Keys that become equal after
  # cutting keep the value of the first one.
  tags_by_cut_key = { for key, value in var.tags : substr(key, 0, 32) => substr(value, 0, 128)... }
  tags            = { for key, values in local.tags_by_cut_key : key => values[0] }
}

resource "ec_deployment" "this" {
  name                   = "${var.name_prefix}-observability"
  region                 = local.elastic_region
  version                = data.ec_stack.latest.version
  deployment_template_id = local.deployment_template_id
  tags                   = local.tags

  # The smallest node Elastic Cloud offers: 1 GB of memory with the storage
  # the template allots to it. Autoscaling stays off so that cost is fixed.
  elasticsearch = {
    autoscale = false

    hot = {
      size        = "1g"
      zone_count  = var.zone_count
      autoscaling = {}
    }
  }

  kibana = {
    size       = "1g"
    zone_count = 1
  }

  # The deployment is created on the newest version. Later releases must not
  # turn an unrelated apply into a cluster upgrade: upgrade deliberately in
  # the Elastic Cloud console.
  lifecycle {
    ignore_changes = [version]
  }
}
