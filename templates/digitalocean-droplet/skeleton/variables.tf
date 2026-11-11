# =============================================================================
# DigitalOcean Droplets - Variables
# =============================================================================

variable "name" {
  description = "Name used in resource names; the environment is appended."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Use lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment: dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "region" {
  description = "DigitalOcean region of the Droplets and the VPC."
  type        = string
}

variable "description" {
  description = "Purpose of the Droplets, shown on the DigitalOcean project and the VPC."
  type        = string
}

variable "owner" {
  description = "Team that owns the Droplets, added as a tag."
  type        = string
}

# -----------------------------------------------------------------------------
# Droplets
# -----------------------------------------------------------------------------

variable "droplet_count" {
  description = "Number of Droplets."
  type        = number
  default     = 1

  validation {
    condition     = var.droplet_count >= 1 && var.droplet_count <= 10
    error_message = "Create between 1 and 10 Droplets."
  }
}

variable "size" {
  description = "Droplet size slug."
  type        = string
}

variable "image" {
  description = "Image slug. The first-boot configuration expects a Debian or Ubuntu image."
  type        = string
}

variable "enable_backups" {
  description = "Take weekly backups of the Droplets."
  type        = bool
  default     = false
}

variable "reserved_ip" {
  description = "Give every Droplet a reserved IPv4 address that survives a rebuild."
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "Address range of the VPC. It must not overlap other VPCs of the account."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The VPC range must be a CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------

variable "ssh_key_names" {
  description = "Names of SSH keys uploaded to the DigitalOcean account. They are installed for the admin user."
  type        = list(string)

  validation {
    condition     = length(var.ssh_key_names) > 0
    error_message = "At least one SSH key is needed: password sign-in is disabled."
  }
}

variable "admin_user" {
  description = "Name of the administrative user created on first boot. Root cannot sign in over SSH."
  type        = string
  default     = "ops"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_user)) && var.admin_user != "root"
    error_message = "Give a valid Linux user name other than root."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Networks allowed to reach SSH. An empty list keeps SSH closed to the internet."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0)) && !contains(["0.0.0.0/0", "::/0"], cidr)])
    error_message = "Give CIDR blocks of known networks; SSH must not be open to the whole internet."
  }
}

variable "allow_web" {
  description = "Allow HTTP and HTTPS from the internet."
  type        = bool
  default     = false
}
