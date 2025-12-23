# Basic Example

This example demonstrates the basic usage of the ${{ values.name }} module.

## Usage

```hcl
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
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 3
  {%- elif values.resource_type == 'network' %}
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = true
  {%- elif values.resource_type == 'database' %}
  engine_version     = "15.3"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  multi_az          = false
  {%- endif %}
  
  default_tags = {
    Project     = "example"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Outputs

```hcl
{%- if values.resource_type == 'compute' %}
output "security_group_id" {
  value = module.${{ values.name.replace('terraform-', '') }}.security_group_id
}

output "autoscaling_group_name" {
  value = module.${{ values.name.replace('terraform-', '') }}.autoscaling_group_name
}
{%- elif values.resource_type == 'network' %}
output "vpc_id" {
  value = module.${{ values.name.replace('terraform-', '') }}.vpc_id
}

output "public_subnet_ids" {
  value = module.${{ values.name.replace('terraform-', '') }}.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.${{ values.name.replace('terraform-', '') }}.private_subnet_ids
}
{%- elif values.resource_type == 'database' %}
output "db_instance_endpoint" {
  value     = module.${{ values.name.replace('terraform-', '') }}.db_instance_endpoint
  sensitive = true
}

output "db_instance_port" {
  value = module.${{ values.name.replace('terraform-', '') }}.db_instance_port
}
{%- endif %}
```

## Prerequisites

{%- if values.provider == 'aws' %}
- AWS CLI configured with appropriate credentials
- Terraform ${{ values.terraform_version }}
{%- elif values.provider == 'azure' %}
- Azure CLI configured with appropriate credentials
- Terraform ${{ values.terraform_version }}
{%- elif values.provider == 'gcp' %}
- Google Cloud SDK configured with appropriate credentials
- Terraform ${{ values.terraform_version }}
{%- endif %}

## Running the Example

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. Clean up resources:
   ```bash
   terraform destroy
   ```
