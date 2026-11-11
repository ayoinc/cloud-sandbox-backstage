# Settings shared by every region of the staging environment.
locals {
  environment        = "staging"
  log_retention_days = 90
{%- if values.cloud != 'azure' %}
  force_destroy      = true
{%- endif %}
}
