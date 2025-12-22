terraform {
  required_version = ">= 1.0"
  
  required_providers {
    {%- if values.provider == 'aws' %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    {%- elif values.provider == 'azure' %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    {%- elif values.provider == 'gcp' %}
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    {%- endif %}
  }
}

module "${{ values.name.replace('terraform-', '') }}" {
  source = "../.."
  
  name        = "example"
  environment = "dev"
  
  {%- if values.provider == 'aws' %}
  aws_region = "us-east-1"
  {%- elif values.provider == 'azure' %}
  location            = "East US"
  resource_group_name = "example-rg"
  {%- elif values.provider == 'gcp' %}
  project_id = "my-project-id"
  region     = "us-central1"
  {%- endif %}
  
  {%- if values.resource_type == 'compute' %}
  instance_type = "{%- if values.provider == 'aws' %}t3.micro{%- elif values.provider == 'azure' %}Standard_B1s{%- elif values.provider == 'gcp' %}e2-micro{%- endif %}"
  min_size      = 1
  max_size      = 3
  {%- elif values.resource_type == 'network' %}
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = true
  {%- elif values.resource_type == 'database' %}
  engine_version     = "{%- if values.provider == 'aws' %}15.3{%- elif values.provider == 'azure' %}15{%- elif values.provider == 'gcp' %}POSTGRES_15{%- endif %}"
  instance_class     = "{%- if values.provider == 'aws' %}db.t3.micro{%- elif values.provider == 'azure' %}GP_Gen5_2{%- elif values.provider == 'gcp' %}db-f1-micro{%- endif %}"
  allocated_storage  = 20
  multi_az          = false
  {%- endif %}
  
  default_tags = {
    Project     = "example"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
