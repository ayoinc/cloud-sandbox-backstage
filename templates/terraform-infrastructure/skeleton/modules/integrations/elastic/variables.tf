variable "name_prefix" {
  description = "Prefix for the names of all resources: up to 24 lowercase letters, digits and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,24}$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 characters of lowercase letters, digits and hyphens."
  }
}

variable "tags" {
  description = "Tags for the deployment. Elastic Cloud accepts up to 64 tags; keys are cut to 32 and values to 128 characters."
  type        = map(string)

  validation {
    condition     = length(var.tags) <= 64
    error_message = "Elastic Cloud accepts at most 64 tags per deployment."
  }
}

variable "cloud_provider" {
  description = "Cloud that hosts the deployment: aws, azure or gcp."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be aws, azure or gcp."
  }
}

variable "region" {
  description = "Region of the stack in the cloud's own naming (for example eu-west-2, uksouth, europe-west2). The deployment is placed in the Elastic Cloud region of the same name."
  type        = string

  validation {
    condition     = contains(keys(lookup(local.elastic_regions, var.cloud_provider, {})), var.region)
    error_message = "Elastic Cloud has no region for \"${var.region}\" on ${var.cloud_provider}. Supported regions: ${join(", ", keys(lookup(local.elastic_regions, var.cloud_provider, {})))}."
  }
}

variable "zone_count" {
  description = "Number of availability zones the Elasticsearch nodes are spread over. 1 has no redundancy; use 2 or 3 where the logs must survive a zone failure."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.zone_count)
    error_message = "zone_count must be 1, 2 or 3."
  }
}
