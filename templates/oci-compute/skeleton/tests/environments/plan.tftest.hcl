# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

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
}

run "plan" {
  command = plan

  assert {
    condition     = oci_core_instance.this.display_name == "${var.name}-${var.environment}"
    error_message = "The instance must be named <name>-<environment>."
  }
}
