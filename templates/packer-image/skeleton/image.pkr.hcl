packer {
  required_plugins {
    {%- if values.cloud_provider == "aws" %}
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    {%- elif values.cloud_provider == "azure" %}
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
    {%- elif values.cloud_provider == "gcp" %}
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
    {%- elif values.cloud_provider == "vmware" %}
    vsphere = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/vsphere"
    }
    {%- endif %}
  }
}

variable "image_name" {
  type    = string
  default = "${{ values.name }}"
}

{%- if values.cloud_provider == "aws" %}
source "amazon-ebs" "main" {
  ami_name      = "${var.image_name}-{{timestamp}}"
  instance_type = "${{ values.instance_type }}"
  region        = "${{ values.region }}"
  
  source_ami_filter {
    filters = {
      {%- if values.base_os == "ubuntu-22.04" %}
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      {%- elif values.base_os == "ubuntu-20.04" %}
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      {%- elif values.base_os == "amazon-linux-2023" %}
      name                = "al2023-ami-*-x86_64"
      {%- endif %}
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon", "099720109477"]
  }
  
  ssh_username = "{% if 'amazon' in values.base_os %}ec2-user{% else %}ubuntu{% endif %}"
  
  tags = {
    Name        = var.image_name
    Environment = "production"
    ManagedBy   = "packer"
  }
}
{%- elif values.cloud_provider == "azure" %}
source "azure-arm" "main" {
  subscription_id = "${env("AZURE_SUBSCRIPTION_ID")}"
  
  managed_image_name                = var.image_name
  managed_image_resource_group_name = "${env("AZURE_RESOURCE_GROUP")}"
  
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
  
  location = "${{ values.region }}"
  vm_size  = "${{ values.instance_type }}"
}
{%- elif values.cloud_provider == "gcp" %}
source "googlecompute" "main" {
  project_id   = "${env("GCP_PROJECT_ID")}"
  source_image = "ubuntu-2204-jammy-v20231101"
  zone         = "${{ values.region }}-a"
  machine_type = "${{ values.instance_type }}"
  image_name   = var.image_name
  ssh_username = "packer"
}
{%- endif %}

build {
  sources = ["source.{% if values.cloud_provider == 'aws' %}amazon-ebs{% elif values.cloud_provider == 'azure' %}azure-arm{% elif values.cloud_provider == 'gcp' %}googlecompute{% endif %}.main"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y {% for pkg in values.custom_packages %}{{ pkg }} {% endfor %}",
      {%- if values.install_docker %}
      "curl -fsSL https://get.docker.com | sudo sh",
      {%- endif %}
      {%- if values.install_ansible %}
      "sudo apt-get install -y ansible",
      {%- endif %}
      "sudo apt-get clean"
    ]
  }
}
