{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# Switches every building block on. The security scan of the pipeline uses
# this file so that all of them are scanned; it is also a starting point for
# a full deployment.
project_name = "example"
environment  = "dev"
{%- if gcp %}

gcp_project_id = "example-project"
{%- endif %}

enable_network       = true
enable_security      = true
enable_storage       = true
enable_observability = true
enable_compute       = true
enable_database      = true
enable_kubernetes    = true
enable_serverless    = true
