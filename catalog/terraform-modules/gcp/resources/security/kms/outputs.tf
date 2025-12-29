output "key_ring_id" {
  description = "The ID of the key ring"
  value       = google_kms_key_ring.key_ring.id
}

output "key_ring_name" {
  description = "The name of the key ring"
  value       = google_kms_key_ring.key_ring.name
}

output "crypto_key_ids" {
  description = "Map of crypto key names to their IDs"
  value = {
    for name, key in google_kms_crypto_key.crypto_keys : name => key.id
  }
}

output "crypto_key_names" {
  description = "Map of crypto key names to their full resource names"
  value = {
    for name, key in google_kms_crypto_key.crypto_keys : name => key.name
  }
}
