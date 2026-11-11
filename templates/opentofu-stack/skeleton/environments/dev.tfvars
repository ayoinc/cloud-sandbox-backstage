environment        = "dev"
network_cidr       = "10.10.0.0/20"
log_retention_days = 30
{%- if values.cloud == 'aws' %}

availability_zone_count = 2
{%- elif values.cloud == 'azure' %}

lock_resource_group = false
{%- else %}

enable_nat = false
{%- endif %}
