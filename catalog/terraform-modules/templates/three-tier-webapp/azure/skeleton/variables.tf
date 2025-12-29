variable "project_name" {
  type    = string
  default = "${{ values.projectName }}"
}

variable "environment" {
  type    = string
  default = "${{ values.environment }}"
}

variable "location" {
  type    = string
  default = "${{ values.location }}"
}

variable "vnet_address_space" {
  type    = string
  default = "${{ values.vnetAddressSpace }}"
}

variable "vm_size" {
  type    = string
  default = "${{ values.vmSize }}"
}

variable "min_nodes" {
  type    = number
  default = ${{ values.minNodes }}
}

variable "max_nodes" {
  type    = number
  default = ${{ values.maxNodes }}
}

variable "kubernetes_version" {
  type    = string
  default = "1.28"
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "database_sku" {
  type    = string
  default = "${{ values.databaseSku }}"
}

variable "database_admin_username" {
  type      = string
  default   = "dbadmin"
  sensitive = true
}

variable "database_admin_password" {
  type      = string
  sensitive = true
}
