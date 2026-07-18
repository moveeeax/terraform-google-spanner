output "id" {
  description = "Identifier of the Spanner instance."
  value       = google_spanner_instance.this.id
}

output "name" {
  description = "Name of the Spanner instance."
  value       = google_spanner_instance.this.name
}

output "state" {
  description = "Current state of the Spanner instance."
  value       = google_spanner_instance.this.state
}

output "database_ids" {
  description = "Identifiers of the databases created within the instance."
  value       = { for k, db in google_spanner_database.this : k => db.id }
}
