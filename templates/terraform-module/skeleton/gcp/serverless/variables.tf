variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "service_name" {
  description = "Short name of the service, appended to the project name and environment."
  type        = string
  default     = "api"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,14}[a-z0-9])?$", var.service_name))
    error_message = "service_name must be 1-16 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "description" {
  description = "Description shown on the service or function."
  type        = string
  default     = "Managed by Terraform"
}

variable "deploy_type" {
  description = "What to deploy: run for a Cloud Run service from a container image, function for a 2nd gen Cloud Function from a source archive."
  type        = string
  default     = "run"

  validation {
    condition     = contains(["run", "function"], var.deploy_type)
    error_message = "deploy_type must be run or function."
  }
}

variable "container_image" {
  description = "Cloud Run only: container image to deploy. The default is Google's public sample image."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "container_port" {
  description = "Cloud Run only: port the container listens on."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "Cloud Run only: HTTP path of a liveness probe. Null configures no liveness probe."
  type        = string
  default     = null

  validation {
    condition     = var.health_check_path == null || can(regex("^/", var.health_check_path))
    error_message = "health_check_path must start with a slash."
  }
}

variable "cpu_idle" {
  description = "Cloud Run only: allocate CPU only while a request is processed. False keeps CPU always allocated."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Cloud Run only: prevent Terraform from deleting the service."
  type        = bool
  default     = false
}

variable "source_archive_path" {
  description = "Cloud Functions only: path of a zip archive with the function source. Required when deploy_type is function."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Cloud Functions only: language runtime, for example python313, nodejs22 or go125."
  type        = string
  default     = "python313"
}

variable "entry_point" {
  description = "Cloud Functions only: name of the function in the source that handles requests."
  type        = string
  default     = "main"
}

variable "memory" {
  description = "Memory limit per instance, for example 512Mi or 1Gi."
  type        = string
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi)$", var.memory))
    error_message = "memory must be a whole number followed by Mi or Gi."
  }
}

variable "cpu" {
  description = "CPU limit per instance, for example 1, 2 or 4."
  type        = string
  default     = "1"

  validation {
    condition     = contains(["1", "2", "4", "6", "8"], var.cpu)
    error_message = "cpu must be 1, 2, 4, 6 or 8."
  }
}

variable "timeout_seconds" {
  description = "Maximum time a request may take, in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 3600
    error_message = "timeout_seconds must be between 1 and 3600."
  }
}

variable "min_instances" {
  description = "Instances kept warm. 0 scales to zero."
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0
    error_message = "min_instances must not be negative."
  }
}

variable "max_instances" {
  description = "Upper limit of instances."
  type        = number
  default     = 10

  validation {
    condition     = var.max_instances >= 1
    error_message = "max_instances must be at least 1."
  }
}

variable "max_concurrency" {
  description = "Concurrent requests one instance handles."
  type        = number
  default     = 80

  validation {
    condition     = var.max_concurrency >= 1 && var.max_concurrency <= 1000
    error_message = "max_concurrency must be between 1 and 1000."
  }
}

variable "environment_variables" {
  description = "Plain environment variables of the service."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "secret_environment_variables" {
  description = "Environment variables read from Secret Manager, keyed by variable name. secret is the short secret name in this project; the runtime service account is granted access to it."
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default  = {}
  nullable = false
}

variable "vpc_connector" {
  description = "ID of a Serverless VPC Access connector for reaching private resources. Null attaches none."
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "Traffic routed through the VPC connector: PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], var.vpc_egress)
    error_message = "vpc_egress must be PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  }
}

variable "ingress" {
  description = "Networks requests may come from: all, internal or internal-and-cloud-load-balancing. Callers must still be authorized through IAM."
  type        = string
  default     = "all"

  validation {
    condition     = contains(["all", "internal", "internal-and-cloud-load-balancing"], var.ingress)
    error_message = "ingress must be all, internal or internal-and-cloud-load-balancing."
  }
}

variable "allow_unauthenticated" {
  description = "Let anyone call the service without credentials. Leave false unless the service is a public website or API."
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "IAM members allowed to call the service."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.invoker_members : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Use allow_unauthenticated for public access."
  }
}

variable "service_account_roles" {
  description = "Project roles granted to the runtime service account."
  type        = list(string)
  default     = ["roles/logging.logWriter", "roles/monitoring.metricWriter", "roles/cloudtrace.agent"]
  nullable    = false

  validation {
    condition     = alltrue([for r in var.service_account_roles : !contains(["roles/owner", "roles/editor"], r)])
    error_message = "The basic roles roles/owner and roles/editor are too broad for a runtime service account."
  }
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key that encrypts the Pub/Sub topic. The Pub/Sub service agent must be allowed to use it. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "enable_pubsub" {
  description = "Create a Pub/Sub topic whose messages are pushed to the service with an authenticated request."
  type        = bool
  default     = false
}

variable "pubsub_message_retention_duration" {
  description = "How long the topic retains messages, in seconds with an s suffix (600s to 2678400s)."
  type        = string
  default     = "86400s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.pubsub_message_retention_duration)) && try(tonumber(trimsuffix(var.pubsub_message_retention_duration, "s")) >= 600 && tonumber(trimsuffix(var.pubsub_message_retention_duration, "s")) <= 2678400, false)
    error_message = "pubsub_message_retention_duration must be between 600s and 2678400s."
  }
}

variable "pubsub_ack_deadline_seconds" {
  description = "Seconds the service has to answer a pushed message before it is redelivered (10 to 600)."
  type        = number
  default     = 60

  validation {
    condition     = var.pubsub_ack_deadline_seconds >= 10 && var.pubsub_ack_deadline_seconds <= 600
    error_message = "pubsub_ack_deadline_seconds must be between 10 and 600."
  }
}

variable "schedule_cron" {
  description = "Cron expression on which Cloud Scheduler calls the service with an authenticated POST. Null creates no schedule."
  type        = string
  default     = null

  validation {
    condition     = var.schedule_cron == null || try(length(split(" ", trimspace(var.schedule_cron))) == 5, false)
    error_message = "schedule_cron must be a five-field cron expression such as \"0 6 * * *\"."
  }
}

variable "schedule_time_zone" {
  description = "IANA time zone in which schedule_cron is evaluated."
  type        = string
  default     = "Etc/UTC"
}
