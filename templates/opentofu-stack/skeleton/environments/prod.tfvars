environment        = "prod"
network_cidr       = "10.30.0.0/20"
log_retention_days = 365
{%- if values.cloud == 'aws' %}

availability_zone_count = 3
{%- elif values.cloud == 'azure' %}

lock_resource_group = true
{%- else %}

enable_nat = true
{%- endif %}
