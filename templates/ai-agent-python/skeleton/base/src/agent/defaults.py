"""Values chosen when the repository was created. Environment variables override them."""

PROVIDER = "${{ values.provider }}"
DEFAULT_MODEL = "${{ values.model }}"
{%- if values.provider == 'bedrock' %}
DEFAULT_AWS_REGION = "${{ values.aws_region }}"
{%- endif %}
