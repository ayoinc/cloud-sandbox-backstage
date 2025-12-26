# ==============================================================================
# Terraform Integration Tests
# ==============================================================================
# These tests create and validate real infrastructure
# WARNING: These tests will incur cloud costs

# Test: Network module creates expected resources
run "integration_network" {
  command = apply

  variables {
    environment        = "test"
    project_name       = "integration-test"
    enable_compute     = false
    enable_network     = true
    enable_storage     = false
    enable_database    = false
    enable_security    = false
    enable_observability = false
    enable_kubernetes  = false
    enable_serverless  = false
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws_region   = "us-east-1"
    aws_vpc_cidr = "10.99.0.0/16"
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azure_location = "eastus"
    azure_vnet_cidr = "10.99.0.0/16"
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    gcp_project_id   = "integration-test"
    gcp_region       = "us-central1"
    gcp_network_cidr = "10.99.0.0/16"
{%- endif %}
  }

{%- if values.provider == 'aws' %}
  assert {
    condition     = output.aws_vpc_id != null
    error_message = "VPC should be created"
  }
{%- endif %}
{%- if values.provider == 'azure' %}
  assert {
    condition     = output.azure_vnet_id != null
    error_message = "VNet should be created"
  }
{%- endif %}
{%- if values.provider == 'gcp' %}
  assert {
    condition     = output.gcp_network_name != null
    error_message = "VPC network should be created"
  }
{%- endif %}
}

# Test: Full stack deployment
run "integration_full_stack" {
  command = apply

  variables {
    environment        = "test"
    project_name       = "integration-test"
    enable_compute     = true
    enable_network     = true
    enable_storage     = true
    enable_database    = false
    enable_security    = true
    enable_observability = true
    enable_kubernetes  = false
    enable_serverless  = false
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws_region = "us-east-1"
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azure_location = "eastus"
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    gcp_project_id = "integration-test"
    gcp_region     = "us-central1"
{%- endif %}
  }

  assert {
    condition     = output.environment == "test"
    error_message = "Environment should be 'test'"
  }
}
