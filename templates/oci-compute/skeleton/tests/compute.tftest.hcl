# Plans the configuration against a mocked provider: no Oracle Cloud account
# is needed.   terraform init -backend=false && terraform test

mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        {
          id             = "ocid1.availabilitydomain.oc1..mock"
          name           = "Mock:EU-FRANKFURT-1-AD-1"
          compartment_id = "ocid1.compartment.oc1..mock"
        },
      ]
    }
  }

  mock_data "oci_core_images" {
    defaults = {
      images = [
        {
          id = "ocid1.image.oc1.eu-frankfurt-1.mock"
        },
      ]
    }
  }

  mock_data "oci_core_services" {
    defaults = {
      services = [
        {
          id         = "ocid1.service.oc1.eu-frankfurt-1.mock"
          cidr_block = "all-fra-services-in-oracle-services-network"
          name       = "All FRA Services In Oracle Services Network"
        },
      ]
    }
  }
}

variables {
  compartment_ocid = "ocid1.compartment.oc1..mock"
  name             = "test-instance"
  environment      = "dev"
  region           = "eu-frankfurt-1"
  description      = "Instance used by the tests"
  owner            = "group:default/platform-team"
  shape            = "VM.Standard.A1.Flex"
  vcn_cidr         = "10.40.0.0/16"
  ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly0000000000000000000000 tests"
}

run "creates_a_private_hardened_instance" {
  command = plan

  assert {
    condition     = oci_core_instance.this.display_name == "test-instance-dev"
    error_message = "The instance must be named <name>-<environment>."
  }

  assert {
    condition     = oci_core_instance.this.create_vnic_details[0].assign_public_ip == "false" && oci_core_subnet.this.prohibit_public_ip_on_vnic
    error_message = "The instance must be private by default."
  }

  assert {
    condition     = length(oci_core_nat_gateway.this) == 1 && length(oci_core_internet_gateway.this) == 0
    error_message = "A private instance needs a NAT gateway and no internet gateway."
  }

  assert {
    condition     = oci_core_instance.this.instance_options[0].are_legacy_imds_endpoints_disabled && oci_core_instance.this.is_pv_encryption_in_transit_enabled
    error_message = "IMDSv1 must be disabled and boot volume traffic encrypted."
  }

  assert {
    condition     = length(oci_core_network_security_group_security_rule.ssh) == 0
    error_message = "SSH must stay closed until a source range is given."
  }

  assert {
    condition     = oci_core_subnet.this.cidr_block == "10.40.0.0/24"
    error_message = "The subnet must take the first /24 of the VCN."
  }
}

run "sizes_the_always_free_ampere_shape" {
  command = plan

  variables {
    ocpus      = 4
    memory_gbs = 24
  }

  assert {
    condition     = oci_core_instance.this.shape_config[0].ocpus == 4 && oci_core_instance.this.shape_config[0].memory_in_gbs == 24
    error_message = "A flexible shape must get the requested OCPUs and memory."
  }
}

run "leaves_fixed_shapes_unsized" {
  command = plan

  variables {
    shape = "VM.Standard.E2.1.Micro"
  }

  assert {
    condition     = !local.is_flexible_shape
    error_message = "VM.Standard.E2.1.Micro is a fixed shape and takes no shape configuration."
  }
}

run "creates_a_public_instance_on_request" {
  command = plan

  variables {
    assign_public_ip  = true
    ssh_allowed_cidrs = ["198.51.100.0/24"]
    allow_web         = true
  }

  assert {
    condition     = length(oci_core_internet_gateway.this) == 1 && length(oci_core_nat_gateway.this) == 0
    error_message = "A public instance needs an internet gateway and no NAT gateway."
  }

  assert {
    condition     = oci_core_network_security_group_security_rule.ssh["198.51.100.0/24"].source == "198.51.100.0/24"
    error_message = "SSH must be limited to the given range."
  }

  assert {
    condition     = length(oci_core_network_security_group_security_rule.web) == 2
    error_message = "HTTP and HTTPS must be allowed when allow_web is set."
  }
}

run "rejects_ssh_from_anywhere" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_allowed_cidrs]
}

run "rejects_a_private_key" {
  command = plan

  variables {
    ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----"
  }

  expect_failures = [var.ssh_public_key]
}
