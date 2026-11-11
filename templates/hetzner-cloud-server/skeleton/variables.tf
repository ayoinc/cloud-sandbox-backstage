# =============================================================================
# Hetzner Cloud Servers - Variables
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

variable "location" {
  description = "Hetzner Cloud location: fsn1, nbg1, hel1, ash, hil or sin."
  type        = string

  validation {
    condition     = contains(["fsn1", "nbg1", "hel1", "ash", "hil", "sin"], var.location)
    error_message = "The location must be fsn1, nbg1, hel1, ash, hil or sin."
  }
}

variable "owner" {
  description = "Team that owns the servers, added as a label."
  type        = string
}

# -----------------------------------------------------------------------------
# Servers
# -----------------------------------------------------------------------------

variable "server_count" {
  description = "Number of servers. A spread placement group holds at most 10."
  type        = number
  default     = 1

  validation {
    condition     = var.server_count >= 1 && var.server_count <= 10
    error_message = "Create between 1 and 10 servers."
  }
}

variable "server_type" {
  description = "Server type, for instance cpx22."
  type        = string
}

variable "image" {
  description = "Image name. The first-boot configuration expects a Debian or Ubuntu image."
  type        = string
}

variable "enable_backups" {
  description = "Take daily backups of the servers."
  type        = bool
  default     = false
}

variable "protection" {
  description = "Protect the servers and the load balancer against deletion and rebuild through the API."
  type        = bool
  default     = false
}

variable "network_cidr" {
  description = "Address range of the private network. The servers get addresses from it, starting at .10."
  type        = string

  validation {
    condition     = can(cidrhost(var.network_cidr, 0))
    error_message = "The network range must be a CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Load balancer
# -----------------------------------------------------------------------------

variable "load_balancer" {
  description = "Put a load balancer in front of the servers. It forwards TCP 80 and 443 over the private network."
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Load balancer type: lb11, lb21 or lb31."
  type        = string
  default     = "lb11"

  validation {
    condition     = contains(["lb11", "lb21", "lb31"], var.load_balancer_type)
    error_message = "The load balancer type must be lb11, lb21 or lb31."
  }
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------

variable "ssh_key_names" {
  description = "Names of SSH keys uploaded to the Hetzner Cloud project. They are installed for the admin user."
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
  description = "Allow HTTP and HTTPS from the internet straight to the servers. Not needed behind the load balancer."
  type        = bool
  default     = false
}
