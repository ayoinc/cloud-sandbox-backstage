# =============================================================================
# Oracle Cloud Compute - VCN, gateways, subnet and network security group
# =============================================================================

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${local.name}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = local.dns_label
  freeform_tags  = local.freeform_tags
}

# Every subnet of a VCN uses its default security list unless told otherwise.
# It is emptied, so the network security group below is the only thing that
# allows traffic.
resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
  display_name               = "${local.name}-default-closed"
  freeform_tags              = local.freeform_tags
}

# -----------------------------------------------------------------------------
# Gateways: an internet gateway for a public instance, otherwise a NAT gateway
# for outbound traffic and a service gateway for Oracle services.
# -----------------------------------------------------------------------------

resource "oci_core_internet_gateway" "this" {
  count = var.assign_public_ip ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-igw"
  enabled        = true
  freeform_tags  = local.freeform_tags
}

resource "oci_core_nat_gateway" "this" {
  count = var.assign_public_ip ? 0 : 1

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-nat"
  freeform_tags  = local.freeform_tags
}

data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  count = var.assign_public_ip ? 0 : 1

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-sgw"
  freeform_tags  = local.freeform_tags

  services {
    service_id = data.oci_core_services.all.services[0].id
  }
}

resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-routes"
  freeform_tags  = local.freeform_tags

  dynamic "route_rules" {
    for_each = oci_core_internet_gateway.this

    content {
      description       = "Internet through the internet gateway"
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = route_rules.value.id
    }
  }

  dynamic "route_rules" {
    for_each = oci_core_nat_gateway.this

    content {
      description       = "Outbound internet through the NAT gateway"
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = route_rules.value.id
    }
  }

  dynamic "route_rules" {
    for_each = oci_core_service_gateway.this

    content {
      description       = "Oracle services through the service gateway"
      destination       = data.oci_core_services.all.services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = route_rules.value.id
    }
  }
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-${var.assign_public_ip ? "public" : "private"}"
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 0)
  dns_label      = "main"
  route_table_id = oci_core_route_table.this.id
  freeform_tags  = local.freeform_tags

  security_list_ids          = [oci_core_default_security_list.this.id]
  prohibit_public_ip_on_vnic = !var.assign_public_ip
}

# -----------------------------------------------------------------------------
# Network security group of the instance
# -----------------------------------------------------------------------------

resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name}-nsg"
  freeform_tags  = local.freeform_tags
}

resource "oci_core_network_security_group_security_rule" "egress" {
  # checkov:skip=CKV2_OCI_2: This is an egress rule; it admits no inbound RDP traffic.
  network_security_group_id = oci_core_network_security_group.this.id
  description               = "Outbound traffic for updates and calls to other services"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "ssh" {
  for_each = toset(var.ssh_allowed_cidrs)

  network_security_group_id = oci_core_network_security_group.this.id
  description               = "SSH from an administration network"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web" {
  for_each = var.allow_web ? toset(["80", "443"]) : toset([])

  network_security_group_id = oci_core_network_security_group.this.id
  description               = "Web traffic from the internet"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

# Path MTU discovery breaks without "fragmentation needed" messages.
resource "oci_core_network_security_group_security_rule" "path_mtu" {
  # checkov:skip=CKV2_OCI_2: The rule admits one ICMP message type only, no TCP port.
  network_security_group_id = oci_core_network_security_group.this.id
  description               = "ICMP fragmentation needed, for path MTU discovery"
  direction                 = "INGRESS"
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  icmp_options {
    type = 3
    code = 4
  }
}
