output "database_id" {
  description = "The ID of the Firestore database"
  value       = google_firestore_database.database.name
}

output "database_name" {
  description = "The full resource name of the Firestore database"
  value       = google_firestore_database.database.id
}

output "uid" {
  description = "The system-generated UUID4 for the Firestore database"
  value       = google_firestore_database.database.uid
}

output "create_time" {
  description = "The timestamp at which the Firestore database was created"
  value       = google_firestore_database.database.create_time
}

output "update_time" {
  description = "The timestamp at which the Firestore database was most recently updated"
  value       = google_firestore_database.database.update_time
}
