# =============================================================================
# Oracle Cloud Compute - Variables
# =============================================================================

variable "compartment_ocid" {
  description = "OCID of the compartment the resources are created in. Supplied as TF_VAR_compartment_ocid."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_ocid))
    error_message = "Give the OCID of a compartment (or of the tenancy for the root compartment)."
  }
}

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
  description = "OCI region, for instance eu-frankfurt-1."
  type        = string
}

variable "description" {
  description = "Purpose of the instance, added as a tag."
  type        = string
}

variable "owner" {
  description = "Team that owns the instance, added as a tag."
  type        = string
}

# -----------------------------------------------------------------------------
# Instance
# -----------------------------------------------------------------------------

variable "shape" {
  description = "Compute shape. VM.Standard.A1.Flex and VM.Standard.E2.1.Micro are Always Free eligible."
  type        = string
}

variable "ocpus" {
  description = "OCPUs of a flexible shape. Ignored by fixed shapes."
  type        = number
  default     = 1

  validation {
    condition     = var.ocpus >= 1
    error_message = "A flexible shape needs at least one OCPU."
  }
}

variable "memory_gbs" {
  description = "Memory of a flexible shape in GB. Ignored by fixed shapes."
  type        = number
  default     = 6

  validation {
    condition     = var.memory_gbs >= 1
    error_message = "A flexible shape needs at least 1 GB of memory."
  }
}

variable "operating_system" {
  description = "Platform image: oracle-linux-9 or ubuntu-24.04. The newest image for the shape is used at creation."
  type        = string
  default     = "oracle-linux-9"

  validation {
    condition     = contains(["oracle-linux-9", "ubuntu-24.04"], var.operating_system)
    error_message = "The operating system must be oracle-linux-9 or ubuntu-24.04."
  }
}

variable "boot_volume_gbs" {
  description = "Size of the boot volume in GB. Always Free tenancies get 200 GB of block storage in total."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_gbs >= 50
    error_message = "Platform images need a boot volume of at least 50 GB."
  }
}

variable "availability_domain_index" {
  description = "Index of the availability domain to place the instance in, starting at 0."
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Network and access
# -----------------------------------------------------------------------------

variable "vcn_cidr" {
  description = "Address range of the VCN. The subnet takes the first /24 of it."
  type        = string

  validation {
    condition     = can(cidrsubnet(var.vcn_cidr, 8, 0))
    error_message = "The VCN range must be a CIDR block of /16 or larger."
  }
}

variable "assign_public_ip" {
  description = "Give the instance a public IP address in a public subnet. When false it is placed in a private subnet behind a NAT gateway."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key installed for the default user of the image (opc or ubuntu)."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)) ", var.ssh_public_key))
    error_message = "Give an OpenSSH public key, never a private key."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Networks allowed to reach SSH. An empty list keeps SSH closed; use the OCI Bastion service instead."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"])
    error_message = "Give CIDR blocks of known networks; SSH must not be open to the whole internet."
  }
}

variable "allow_web" {
  description = "Allow HTTP and HTTPS from the internet. Only useful with a public IP address."
  type        = bool
  default     = false
}
