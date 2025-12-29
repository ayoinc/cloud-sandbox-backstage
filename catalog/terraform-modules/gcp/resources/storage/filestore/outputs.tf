output "instance_id" {
  description = "The ID of the Filestore instance"
  value       = google_filestore_instance.this.id
}

output "instance_name" {
  description = "The name of the Filestore instance"
  value       = google_filestore_instance.this.name
}

output "networks" {
  description = "The network configuration of the Filestore instance"
  value       = google_filestore_instance.this.networks
}

output "file_shares" {
  description = "The file shares of the Filestore instance"
  value       = google_filestore_instance.this.file_shares
}
