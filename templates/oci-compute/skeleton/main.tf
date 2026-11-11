# =============================================================================
# Oracle Cloud Compute - Instance
# =============================================================================

locals {
  name = "${var.name}-${var.environment}"

  # DNS labels are at most 15 letters and digits.
  dns_label = substr(replace(local.name, "-", ""), 0, 15)

  is_flexible_shape = endswith(var.shape, ".Flex")

  images = {
    "oracle-linux-9" = {
      operating_system = "Oracle Linux"
      version          = "9"
      user             = "opc"
    }
    "ubuntu-24.04" = {
      operating_system = "Canonical Ubuntu"
      version          = "24.04"
      user             = "ubuntu"
    }
  }
  image = local.images[var.operating_system]

  freeform_tags = {
    project     = var.name
    environment = var.environment
    owner       = var.owner
    description = substr(var.description, 0, 255)
    managed-by  = "terraform"
  }
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

# Newest platform image of the operating system that runs on the shape.
data "oci_core_images" "this" {
  compartment_id           = var.compartment_ocid
  operating_system         = local.image.operating_system
  operating_system_version = local.image.version
  shape                    = var.shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain_index].name
  display_name        = local.name
  shape               = var.shape
  freeform_tags       = local.freeform_tags

  dynamic "shape_config" {
    for_each = local.is_flexible_shape ? [1] : []

    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_gbs
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.this.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.this.id
    assign_public_ip = var.assign_public_ip
    nsg_ids          = [oci_core_network_security_group.this.id]
    hostname_label   = local.name
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  # Only the token-based instance metadata service (IMDSv2) answers.
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  # Data between the instance and its boot volume is encrypted in transit;
  # volumes are always encrypted at rest. The first argument applies at
  # creation, the launch option keeps it that way afterwards.
  is_pv_encryption_in_transit_enabled = true

  launch_options {
    is_pv_encryption_in_transit_enabled = true
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false

    # Lets the OCI Bastion service open SSH sessions to a private instance.
    plugins_config {
      name          = "Bastion"
      desired_state = var.assign_public_ip ? "DISABLED" : "ENABLED"
    }
  }

  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }

  lifecycle {
    # A newer platform image must not replace a running instance. To move to a
    # new image on purpose: terraform apply -replace=oci_core_instance.this
    ignore_changes = [source_details[0].source_id]
  }
}
