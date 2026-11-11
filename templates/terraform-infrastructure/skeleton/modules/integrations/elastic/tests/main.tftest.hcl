mock_provider "ec" {
  mock_data "ec_stack" {
    defaults = {
      version = "9.1.0"
    }
  }
}

variables {
  name_prefix    = "acme-dev"
  cloud_provider = "aws"
  region         = "eu-west-2"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "creates_smallest_deployment" {
  command = plan

  assert {
    condition     = ec_deployment.this.name == "acme-dev-observability"
    error_message = "The deployment name must derive from name_prefix."
  }

  assert {
    condition     = ec_deployment.this.version == "9.1.0"
    error_message = "The deployment must use the version the stack data source returns."
  }

  assert {
    condition     = data.ec_stack.latest.version_regex == "latest" && data.ec_stack.latest.region == "aws-eu-west-2"
    error_message = "The newest version of the deployment's region must be looked up."
  }

  assert {
    condition     = ec_deployment.this.elasticsearch.hot.size == "1g" && ec_deployment.this.elasticsearch.hot.zone_count == 1
    error_message = "Elasticsearch must default to one 1 GB node."
  }

  assert {
    condition     = ec_deployment.this.elasticsearch.autoscale == false
    error_message = "Autoscaling must be off."
  }

  assert {
    condition     = ec_deployment.this.kibana.size == "1g" && ec_deployment.this.kibana.zone_count == 1
    error_message = "Kibana must be one 1 GB instance."
  }

  assert {
    condition     = ec_deployment.this.tags == tomap({ Project = "acme", Environment = "development" })
    error_message = "The deployment must carry the tags."
  }
}

run "maps_prefixed_aws_region" {
  command = plan

  assert {
    condition     = ec_deployment.this.region == "aws-eu-west-2" && ec_deployment.this.deployment_template_id == "aws-storage-optimized"
    error_message = "eu-west-2 must map to aws-eu-west-2 with the AWS template."
  }
}

run "maps_unprefixed_aws_region" {
  command = plan

  variables {
    region = "us-east-1"
  }

  assert {
    condition     = ec_deployment.this.region == "us-east-1" && output.elastic_region == "us-east-1"
    error_message = "us-east-1 keeps its name in Elastic Cloud."
  }
}

run "maps_azure_region" {
  command = plan

  variables {
    cloud_provider = "azure"
    region         = "uksouth"
    zone_count     = 2
  }

  assert {
    condition     = ec_deployment.this.region == "azure-uksouth" && ec_deployment.this.deployment_template_id == "azure-storage-optimized"
    error_message = "uksouth must map to azure-uksouth with the Azure template."
  }

  assert {
    condition     = ec_deployment.this.elasticsearch.hot.zone_count == 2
    error_message = "zone_count must set the zones of the Elasticsearch nodes."
  }
}

run "maps_gcp_region" {
  command = plan

  variables {
    cloud_provider = "gcp"
    region         = "europe-west2"
  }

  assert {
    condition     = ec_deployment.this.region == "gcp-europe-west2" && ec_deployment.this.deployment_template_id == "gcp-storage-optimized"
    error_message = "europe-west2 must map to gcp-europe-west2 with the GCP template."
  }
}

run "cuts_tags_to_elastic_limits" {
  command = plan

  variables {
    tags = {
      "a-key-that-is-longer-than-thirty-two-characters" = "value"
      Description                                       = "It's the team's \"main\" service: handles 50% of #1 & more"
      Long                                              = join("", [for index in range(20) : "0123456789"])
    }
  }

  assert {
    condition     = alltrue([for key, value in ec_deployment.this.tags : length(key) <= 32 && length(value) <= 128])
    error_message = "Keys must be cut to 32 and values to 128 characters."
  }

  assert {
    condition     = ec_deployment.this.tags["Description"] == "It's the team's \"main\" service: handles 50% of #1 & more"
    error_message = "Values within the limits must be passed verbatim."
  }

  assert {
    condition     = length(ec_deployment.this.tags) == 3
    error_message = "Every tag must be kept."
  }
}

run "rejects_region_of_another_cloud" {
  command = plan

  variables {
    cloud_provider = "gcp"
    region         = "eu-west-2"
  }

  expect_failures = [var.region]
}

run "rejects_region_without_elastic_cloud" {
  command = plan

  variables {
    cloud_provider = "azure"
    region         = "germanywestcentral"
  }

  expect_failures = [var.region]
}

run "rejects_unknown_cloud" {
  command = plan

  variables {
    cloud_provider = "oci"
  }

  expect_failures = [var.cloud_provider]
}

run "rejects_invalid_zone_count" {
  command = plan

  variables {
    zone_count = 4
  }

  expect_failures = [var.zone_count]
}
