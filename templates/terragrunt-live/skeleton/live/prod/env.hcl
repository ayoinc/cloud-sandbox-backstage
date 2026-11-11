# Settings shared by every region of the prod environment.
locals {
  environment        = "prod"
  log_retention_days = 365
{%- if values.cloud != 'azure' %}
  force_destroy      = false
{%- endif %}
}
