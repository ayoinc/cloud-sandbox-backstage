# =============================================================================
# Oracle Cloud Compute - Outputs
# =============================================================================

output "instance_id" {
  description = "OCID of the instance."
  value       = oci_core_instance.this.id
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = oci_core_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance. Empty for a private instance."
  value       = oci_core_instance.this.public_ip
}

output "ssh_user" {
  description = "Default user of the image."
  value       = local.image.user
}

output "vcn_id" {
  description = "OCID of the VCN."
  value       = oci_core_vcn.this.id
}

output "subnet_id" {
  description = "OCID of the subnet the instance is in."
  value       = oci_core_subnet.this.id
}

output "network_security_group_id" {
  description = "OCID of the network security group of the instance."
  value       = oci_core_network_security_group.this.id
}
