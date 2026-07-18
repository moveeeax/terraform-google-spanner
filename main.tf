resource "google_spanner_instance" "this" {
  project      = var.project_id
  name         = var.name
  display_name = var.display_name
  config       = var.config
  num_nodes    = var.num_nodes
  labels       = var.labels
}

resource "google_spanner_database" "this" {
  for_each = var.databases

  project             = var.project_id
  instance            = google_spanner_instance.this.name
  name                = each.key
  ddl                 = each.value.ddl
  deletion_protection = each.value.deletion_protection
}
