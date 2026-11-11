{%- set windows = values.base_os == "windows-2022" -%}
{%- set provider = values.cloud_provider -%}
packer {
  required_version = ">= 1.9.0"

  required_plugins {
{%- if provider == "aws" %}
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
{%- elif provider == "azure" %}
    azure = {
      version = ">= 2.1.0"
      source  = "github.com/hashicorp/azure"
    }
{%- elif provider == "gcp" %}
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
{%- elif provider == "vmware" %}
    vsphere = {
      version = ">= 2.0.0"
      source  = "github.com/vmware/vsphere"
    }
{%- endif %}
  }
}

variable "image_name" {
  type        = string
  default     = "${{ values.name }}"
  description = "Prefix of the image name; a build timestamp is appended."
}
{%- if provider == "aws" %}

variable "region" {
  type        = string
  default     = "${{ values.region }}"
  description = "AWS region the image is built and registered in."
}

variable "instance_type" {
  type        = string
  default     = "${{ values.instance_type }}"
  description = "EC2 instance type of the temporary build instance."
}
{%- elif provider == "azure" %}

variable "subscription_id" {
  type        = string
  default     = env("ARM_SUBSCRIPTION_ID")
  description = "Azure subscription the image is built in. Defaults to ARM_SUBSCRIPTION_ID."
}

variable "resource_group" {
  type        = string
  default     = "${{ values.name }}-images"
  description = "Existing resource group the managed image is stored in."
}

variable "location" {
  type        = string
  default     = "${{ values.region }}"
  description = "Azure location of the temporary build VM."
}

variable "vm_size" {
  type        = string
  default     = "${{ values.instance_type }}"
  description = "Size of the temporary build VM."
}
{%- elif provider == "gcp" %}

variable "project_id" {
  type        = string
  default     = env("GOOGLE_CLOUD_PROJECT")
  description = "GCP project the image is built in. Defaults to GOOGLE_CLOUD_PROJECT."
}

variable "region" {
  type        = string
  default     = "${{ values.region }}"
  description = "GCP region; the build VM runs in zone a of this region."
}

variable "machine_type" {
  type        = string
  default     = "${{ values.instance_type }}"
  description = "Machine type of the temporary build VM."
}
{%- elif provider == "vmware" %}

variable "vcenter_server" {
  type        = string
  default     = env("VSPHERE_SERVER")
  description = "vCenter Server hostname. Defaults to VSPHERE_SERVER."
}

variable "vcenter_username" {
  type        = string
  default     = env("VSPHERE_USER")
  description = "vCenter user. Defaults to VSPHERE_USER."
}

variable "vcenter_password" {
  type        = string
  default     = env("VSPHERE_PASSWORD")
  sensitive   = true
  description = "vCenter password. Defaults to VSPHERE_PASSWORD."
}

variable "insecure_connection" {
  type        = bool
  default     = false
  description = "Skip TLS verification of the vCenter certificate."
}

variable "datacenter" {
  type        = string
  default     = "${{ values.region }}"
  description = "vSphere datacenter the image is built in."
}

variable "cluster" {
  type        = string
  default     = env("VSPHERE_CLUSTER")
  description = "vSphere cluster that runs the build VM. Defaults to VSPHERE_CLUSTER."
}

variable "datastore" {
  type        = string
  default     = env("VSPHERE_DATASTORE")
  description = "Datastore of the build VM. Defaults to VSPHERE_DATASTORE."
}

variable "source_template" {
  type        = string
  default     = "${{ values.base_os }}"
  description = "Name of the ${{ values.base_os }} VM template that is cloned."
}

variable "cpus" {
  type        = number
  default     = ${{ values.instance_type.split("x")[0] }}
  description = "Number of virtual CPUs."
}

variable "memory_mb" {
  type        = number
  default     = ${{ values.instance_type.split("x")[1] }}
  description = "Memory in MB."
}

variable "guest_username" {
  type        = string
  default     = env("PACKER_GUEST_USERNAME")
  description = "Account in the source template Packer connects with. Defaults to PACKER_GUEST_USERNAME."
}

variable "guest_password" {
  type        = string
  default     = env("PACKER_GUEST_PASSWORD")
  sensitive   = true
  description = "Password of that account. Defaults to PACKER_GUEST_PASSWORD."
}
{%- endif %}

locals {
  build_time = formatdate("YYYYMMDDhhmmss", timestamp())
  image_name = "${var.image_name}-${local.build_time}"
}
{%- if provider == "aws" %}

source "amazon-ebs" "main" {
  ami_name      = local.image_name
  instance_type = var.instance_type
  region        = var.region

  source_ami_filter {
    filters = {
{%- if values.base_os == "ubuntu-22.04" %}
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
{%- elif values.base_os == "ubuntu-20.04" %}
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
{%- elif values.base_os == "amazon-linux-2023" %}
      name                = "al2023-ami-2023.*-x86_64"
{%- elif values.base_os == "rhel-9" %}
      name                = "RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP3"
{%- elif values.base_os == "debian-12" %}
      name                = "debian-12-amd64-*"
{%- elif windows %}
      name                = "Windows_Server-2022-English-Full-Base-*"
{%- endif %}
      architecture        = "x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
{%- if values.base_os == "ubuntu-22.04" or values.base_os == "ubuntu-20.04" %}
    owners      = ["099720109477"] # Canonical
{%- elif values.base_os == "rhel-9" %}
    owners      = ["309956199498"] # Red Hat
{%- elif values.base_os == "debian-12" %}
    owners      = ["136693071363"] # Debian
{%- else %}
    owners      = ["amazon"]
{%- endif %}
  }
{%- if windows %}

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "15m"
  user_data_file = "scripts/enable-winrm.ps1"
{%- elif values.base_os == "ubuntu-22.04" or values.base_os == "ubuntu-20.04" %}

  ssh_username = "ubuntu"
{%- elif values.base_os == "debian-12" %}

  ssh_username = "admin"
{%- else %}

  ssh_username = "ec2-user"
{%- endif %}

  # IMDSv2 only, on the build instance and on instances launched from the AMI.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  imds_support = "v2.0"

  tags = {
    Name      = var.image_name
    BaseOS    = "${{ values.base_os }}"
    ManagedBy = "packer"
  }
}
{%- elif provider == "azure" %}

source "azure-arm" "main" {
  # Uses the identity of `az login`, locally and in the pipeline.
  use_azure_cli_auth = true
  subscription_id    = var.subscription_id

  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.resource_group
{%- if values.base_os == "ubuntu-22.04" %}

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"
{%- elif values.base_os == "ubuntu-20.04" %}

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-focal"
  image_sku       = "20_04-lts-gen2"
{%- elif values.base_os == "rhel-9" %}

  os_type         = "Linux"
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9-lvm-gen2"
{%- elif values.base_os == "debian-12" %}

  os_type         = "Linux"
  image_publisher = "Debian"
  image_offer     = "debian-12"
  image_sku       = "12-gen2"
{%- elif windows %}

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter-g2"

  communicator   = "winrm"
  winrm_username = "packer"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "15m"
{%- endif %}

  location = var.location
  vm_size  = var.vm_size

  azure_tags = {
    BaseOS    = "${{ values.base_os }}"
    ManagedBy = "packer"
  }
}
{%- elif provider == "gcp" %}

source "googlecompute" "main" {
  project_id   = var.project_id
  zone         = "${var.region}-a"
  machine_type = var.machine_type
{%- if values.base_os == "ubuntu-22.04" %}

  source_image_family     = "ubuntu-2204-lts"
  source_image_project_id = ["ubuntu-os-cloud"]
{%- elif values.base_os == "ubuntu-20.04" %}

  source_image_family     = "ubuntu-2004-lts"
  source_image_project_id = ["ubuntu-os-cloud"]
{%- elif values.base_os == "rhel-9" %}

  source_image_family     = "rhel-9"
  source_image_project_id = ["rhel-cloud"]
{%- elif values.base_os == "debian-12" %}

  source_image_family     = "debian-12"
  source_image_project_id = ["debian-cloud"]
{%- elif windows %}

  source_image_family     = "windows-2022"
  source_image_project_id = ["windows-cloud"]
{%- endif %}

  image_name   = local.image_name
  image_family = var.image_name
{%- if windows %}

  communicator   = "winrm"
  winrm_username = "packer_user"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "15m"

  # Creates the account Packer connects with while the VM is specialised.
  metadata = {
    sysprep-specialize-script-cmd = "winrm quickconfig -quiet & net user /add packer_user & net localgroup administrators packer_user /add & winrm set winrm/config/service/auth @{Basic=\"true\"}"
  }
{%- else %}

  ssh_username = "packer"
{%- endif %}

  image_labels = {
    base_os    = "${{ values.base_os | replace(".", "-") }}"
    managed_by = "packer"
  }
}
{%- elif provider == "vmware" %}

source "vsphere-clone" "main" {
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = var.insecure_connection

  datacenter = var.datacenter
  cluster    = var.cluster
  datastore  = var.datastore

  template = var.source_template
  vm_name  = local.image_name
  CPUs     = var.cpus
  RAM      = var.memory_mb
{%- if windows %}

  communicator   = "winrm"
  winrm_username = var.guest_username
  winrm_password = var.guest_password
  winrm_timeout  = "15m"
{%- else %}

  communicator = "ssh"
  ssh_username = var.guest_username
  ssh_password = var.guest_password
{%- endif %}

  convert_to_template = true
}
{%- endif %}

build {
{%- if provider == "aws" %}
  sources = ["source.amazon-ebs.main"]
{%- elif provider == "azure" %}
  sources = ["source.azure-arm.main"]
{%- elif provider == "gcp" %}
  sources = ["source.googlecompute.main"]
{%- elif provider == "vmware" %}
  sources = ["source.vsphere-clone.main"]
{%- endif %}
{%- if windows %}

  provisioner "powershell" {
    script = "scripts/provision.ps1"
  }

  provisioner "windows-restart" {}
{%- if provider == "aws" %}

  # Generalises the instance so that the AMI boots as a new machine.
  provisioner "powershell" {
    inline = [
      "& 'C:/Program Files/Amazon/EC2Launch/EC2Launch.exe' reset --block",
      "& 'C:/Program Files/Amazon/EC2Launch/EC2Launch.exe' sysprep --shutdown --block",
    ]
  }
{%- elif provider == "azure" %}

  # Generalises the VM so that the image boots as a new machine.
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -Seconds 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -Seconds 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $state = (Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State).ImageState; if ($state -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { break }; Start-Sleep -Seconds 10 }",
    ]
  }
{%- elif provider == "gcp" %}

  # Generalises the VM so that the image boots as a new machine.
  provisioner "powershell" {
    inline = ["GCESysprep -NoShutdown"]
  }
{%- endif %}
{%- else %}

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo -E bash '{{ .Path }}'"
    script          = "scripts/provision.sh"
  }
{%- if provider == "azure" %}

  # Removes the build user and machine identity so that the image is generic.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo -E sh '{{ .Path }}'"
    inline          = ["/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
  }
{%- endif %}
{%- endif %}

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
