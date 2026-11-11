# Settings shared by every region of the dev environment.
locals {
  environment        = "dev"
  log_retention_days = 30
{%- if values.cloud != 'azure' %}
  force_destroy      = true
{%- endif %}
}
