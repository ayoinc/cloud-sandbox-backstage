environment         = "dev"
region              = "{{ .default_region }}"
project_name        = "{{ .project_name }}"
resource_group_name = "{{ .resource_group_name }}"

tags = {
  Environment = "dev"
  Project     = "{{ .project_name }}"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}