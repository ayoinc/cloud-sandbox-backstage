variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region for Cloud Scheduler jobs"
  type        = string
}

variable "jobs" {
  description = "List of Cloud Scheduler jobs to create"
  type = list(object({
    name             = string
    description      = optional(string)
    schedule         = string
    time_zone        = optional(string, "Etc/UTC")
    attempt_deadline = optional(string, "180s")

    retry_config = optional(object({
      retry_count          = optional(number)
      max_retry_duration   = optional(string)
      min_backoff_duration = optional(string)
      max_backoff_duration = optional(string)
      max_doublings        = optional(number)
    }))

    http_target = optional(object({
      uri         = string
      http_method = optional(string, "POST")
      body        = optional(string)
      headers     = optional(map(string))

      oauth_token = optional(object({
        service_account_email = string
        scope                 = optional(string)
      }))

      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string)
      }))
    }))

    pubsub_target = optional(object({
      topic_name = string
      data       = optional(string)
      attributes = optional(map(string))
    }))

    app_engine_http_target = optional(object({
      http_method  = optional(string, "POST")
      relative_uri = string
      body         = optional(string)
      headers      = optional(map(string))

      app_engine_routing = optional(object({
        service  = optional(string)
        version  = optional(string)
        instance = optional(string)
      }))
    }))
  }))

  validation {
    condition = alltrue([
      for job in var.jobs : (
        (job.http_target != null ? 1 : 0) +
        (job.pubsub_target != null ? 1 : 0) +
        (job.app_engine_http_target != null ? 1 : 0)
      ) == 1
    ])
    error_message = "Each job must have exactly one target: http_target, pubsub_target, or app_engine_http_target."
  }

  validation {
    condition = alltrue([
      for job in var.jobs : (
        job.http_target == null || (
          (job.http_target.oauth_token != null ? 1 : 0) +
          (job.http_target.oidc_token != null ? 1 : 0)
        ) <= 1
      )
    ])
    error_message = "HTTP targets cannot have both oauth_token and oidc_token configured."
  }
}
