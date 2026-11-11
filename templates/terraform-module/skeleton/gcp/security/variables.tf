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

variable "kms_key_rotation_period" {
  description = "Rotation period of the encryption key in seconds with an s suffix. At most 90 days."
  type        = string
  default     = "7776000s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.kms_key_rotation_period)) && try(tonumber(trimsuffix(var.kms_key_rotation_period, "s")) >= 86400 && tonumber(trimsuffix(var.kms_key_rotation_period, "s")) <= 7776000, false)
    error_message = "kms_key_rotation_period must be between 86400s (1 day) and 7776000s (90 days)."
  }
}

variable "kms_key_protection_level" {
  description = "Protection level of the encryption key: SOFTWARE or HSM."
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.kms_key_protection_level)
    error_message = "kms_key_protection_level must be SOFTWARE or HSM."
  }
}

variable "kms_encrypter_decrypters" {
  description = "Additional IAM members allowed to encrypt and decrypt with the key (for example serviceAccount:name@project.iam.gserviceaccount.com)."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.kms_encrypter_decrypters : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Public principals are not allowed."
  }
}

variable "grant_storage_service_agent" {
  description = "Allow the project's Cloud Storage service agent to use the key so buckets can be encrypted with it."
  type        = bool
  default     = true
}

variable "service_account_roles" {
  description = "Project roles granted to the application service account."
  type        = list(string)
  default     = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
  nullable    = false

  validation {
    condition     = alltrue([for r in var.service_account_roles : !contains(["roles/owner", "roles/editor"], r)])
    error_message = "The basic roles roles/owner and roles/editor are too broad for an application service account."
  }
}

variable "secret_names" {
  description = "Short names of the Secret Manager secrets to create. Values are added as secret versions outside Terraform."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for n in var.secret_names : can(regex("^[a-zA-Z0-9_-]{1,64}$", n))])
    error_message = "Secret names may contain letters, digits, hyphens and underscores (max 64 characters)."
  }
}

variable "secret_accessors" {
  description = "Additional IAM members allowed to read every secret created by this module."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for m in var.secret_accessors : can(regex("^(user|group|serviceAccount|domain|principal|principalSet):.+", m))])
    error_message = "Members must use an IAM principal prefix such as user:, group: or serviceAccount:. Public principals are not allowed."
  }
}

variable "enable_audit_logs" {
  description = "Enable Admin Read, Data Read and Data Write audit logs for all services in the project."
  type        = bool
  default     = true
}

variable "enable_org_policies" {
  description = "Enforce the organization policies selected below on the project. Requires the Organization Policy Administrator role."
  type        = bool
  default     = false
}

variable "require_os_login" {
  description = "With enable_org_policies, require OS Login on every VM in the project."
  type        = bool
  default     = true
}

variable "restrict_vm_external_ips" {
  description = "With enable_org_policies, forbid external IP addresses on every VM in the project."
  type        = bool
  default     = true
}

variable "allowed_policy_member_domains" {
  description = "With enable_org_policies, Cloud Identity customer IDs (for example C01abc234) whose identities may appear in IAM policies. Empty leaves the constraint unmanaged."
  type        = list(string)
  default     = []
  nullable    = false
}
