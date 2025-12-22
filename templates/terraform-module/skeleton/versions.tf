terraform {
  required_version = "${{ values.terraform_version }}"
  
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
    {%- elif values.provider == 'multi-cloud' %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    {%- endif %}
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

{%- if values.provider == 'aws' %}
# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.default_tags
  }
}
{%- elif values.provider == 'azure' %}
# Configure the Azure Provider
provider "azurerm" {
  features {}
}
{%- elif values.provider == 'gcp' %}
# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}
{%- endif %}
