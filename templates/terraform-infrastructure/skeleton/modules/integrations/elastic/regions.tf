locals {
  # Elastic Cloud Hosted region ID of every cloud region Elastic operates in,
  # keyed by the cloud's own region name. The older AWS regions carry no
  # "aws-" prefix in Elastic Cloud.
  elastic_regions = {
    aws = {
      "af-south-1"     = "aws-af-south-1"
      "ap-east-1"      = "aws-ap-east-1"
      "ap-northeast-1" = "ap-northeast-1"
      "ap-northeast-2" = "aws-ap-northeast-2"
      "ap-south-1"     = "aws-ap-south-1"
      "ap-southeast-1" = "ap-southeast-1"
      "ap-southeast-2" = "ap-southeast-2"
      "ca-central-1"   = "aws-ca-central-1"
      "eu-central-1"   = "aws-eu-central-1"
      "eu-central-2"   = "aws-eu-central-2"
      "eu-north-1"     = "aws-eu-north-1"
      "eu-south-1"     = "aws-eu-south-1"
      "eu-west-1"      = "eu-west-1"
      "eu-west-2"      = "aws-eu-west-2"
      "eu-west-3"      = "aws-eu-west-3"
      "me-south-1"     = "aws-me-south-1"
      "sa-east-1"      = "sa-east-1"
      "us-east-1"      = "us-east-1"
      "us-east-2"      = "aws-us-east-2"
      "us-west-1"      = "us-west-1"
      "us-west-2"      = "us-west-2"
    }
    azure = {
      "australiaeast"    = "azure-australiaeast"
      "brazilsouth"      = "azure-brazilsouth"
      "canadacentral"    = "azure-canadacentral"
      "centralindia"     = "azure-centralindia"
      "centralus"        = "azure-centralus"
      "eastus"           = "azure-eastus"
      "eastus2"          = "azure-eastus2"
      "francecentral"    = "azure-francecentral"
      "japaneast"        = "azure-japaneast"
      "northeurope"      = "azure-northeurope"
      "southafricanorth" = "azure-southafricanorth"
      "southcentralus"   = "azure-southcentralus"
      "southeastasia"    = "azure-southeastasia"
      "uksouth"          = "azure-uksouth"
      "westeurope"       = "azure-westeurope"
      "westus2"          = "azure-westus2"
    }
    gcp = {
      "asia-east1"              = "gcp-asia-east1"
      "asia-northeast1"         = "gcp-asia-northeast1"
      "asia-northeast3"         = "gcp-asia-northeast3"
      "asia-south1"             = "gcp-asia-south1"
      "asia-southeast1"         = "gcp-asia-southeast1"
      "asia-southeast2"         = "gcp-asia-southeast2"
      "australia-southeast1"    = "gcp-australia-southeast1"
      "europe-north1"           = "gcp-europe-north1"
      "europe-west1"            = "gcp-europe-west1"
      "europe-west2"            = "gcp-europe-west2"
      "europe-west3"            = "gcp-europe-west3"
      "europe-west4"            = "gcp-europe-west4"
      "europe-west9"            = "gcp-europe-west9"
      "me-west1"                = "gcp-me-west1"
      "northamerica-northeast1" = "gcp-northamerica-northeast1"
      "southamerica-east1"      = "gcp-southamerica-east1"
      "us-central1"             = "gcp-us-central1"
      "us-east1"                = "gcp-us-east1"
      "us-east4"                = "gcp-us-east4"
      "us-west1"                = "gcp-us-west1"
    }
  }

  elastic_region = local.elastic_regions[var.cloud_provider][var.region]

  # The storage optimized hardware profile suits log and metric data and
  # exists in every region above under the name of its cloud.
  deployment_template_id = "${var.cloud_provider}-storage-optimized"
}
