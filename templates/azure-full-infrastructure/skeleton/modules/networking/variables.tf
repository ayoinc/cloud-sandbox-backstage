variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "address_space" {
  description = "Address space of the virtual network in CIDR notation"
  type        = string
}

variable "subnets" {
  description = "Subnets to create, keyed by name"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegation        = optional(string)
  }))
}

variable "dns_servers" {
  description = "Custom DNS servers (empty uses Azure DNS)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for outbound traffic"
  type        = bool
  default     = false
}

variable "nat_gateway_subnets" {
  description = "Names of the subnets that send outbound traffic through the NAT gateway"
  type        = list(string)
  default     = []
}

variable "enable_bastion" {
  description = "Create an Azure Bastion host for access to virtual machines"
  type        = bool
  default     = false
}

variable "bastion_subnet_prefix" {
  description = "Address prefix of AzureBastionSubnet (at least a /26)"
  type        = string
  default     = null
}

variable "enable_ddos_protection" {
  description = "Create a DDoS protection plan and attach it to the virtual network"
  type        = bool
  default     = false
}
