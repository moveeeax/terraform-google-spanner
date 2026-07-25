locals {
  # Exactly one of num_nodes / processing_units may reach the provider.
  # When the caller sets neither, fall back to a single node so that the
  # historical default (num_nodes = 1) is preserved.
  effective_num_nodes = var.processing_units == null ? coalesce(var.num_nodes, 1) : null

  # Databases the caller has left completely unprotected: `terraform destroy`
  # (or simply removing the key from `var.databases`) will drop them, and a
  # Spanner instance has no automatic backups unless one is configured
  # separately. Surfaced as a plan-time warning by the `check` block below.
  unprotected_databases = [
    for name, db in var.databases : name
    if db.deletion_protection == false && db.enable_drop_protection == false
  ]
}

resource "google_spanner_instance" "this" {
  project      = var.project_id
  name         = var.name
  display_name = var.display_name
  config       = var.config
  labels       = var.labels

  # num_nodes and processing_units are mutually exclusive; 1 node == 1000
  # processing units, so sending both (or defaulting num_nodes to 1 while the
  # caller asks for 100 processing units) is a 10x overprovision at best and a
  # provider error at worst.
  num_nodes        = local.effective_num_nodes
  processing_units = var.processing_units

  lifecycle {
    # Cross-variable checks cannot live in `variable "..." { validation }`
    # while required_version is >= 1.5, so they are enforced here instead.
    precondition {
      condition     = !(var.num_nodes != null && var.processing_units != null)
      error_message = "num_nodes and processing_units are mutually exclusive: set at most one of them (1 node == 1000 processing units)."
    }

    # Guards the local above: whatever the inputs, exactly one of the two
    # capacity fields may reach the API.
    precondition {
      condition     = !(local.effective_num_nodes != null && var.processing_units != null)
      error_message = "Internal error: exactly one of num_nodes / processing_units may be sent to the Spanner API."
    }
  }
}

resource "google_spanner_database" "this" {
  for_each = var.databases

  project  = var.project_id
  instance = google_spanner_instance.this.name
  name     = each.key
  ddl      = each.value.ddl

  database_dialect         = each.value.database_dialect
  version_retention_period = each.value.version_retention_period

  # Blocks Terraform from deleting the database. Defaults to true, matching the
  # provider default -- do not weaken this.
  deletion_protection = each.value.deletion_protection

  # Stronger than deletion_protection: enforced by the Spanner API itself, so it
  # also blocks drops made outside Terraform and blocks deletion of the parent
  # instance.
  enable_drop_protection = each.value.enable_drop_protection

  dynamic "encryption_config" {
    for_each = each.value.kms_key_name == null ? [] : [each.value.kms_key_name]

    content {
      kms_key_name = encryption_config.value
    }
  }
}

check "database_destruction_guard" {
  assert {
    condition = length(local.unprotected_databases) == 0
    error_message = format(
      "Database(s) %s have both deletion_protection and enable_drop_protection disabled. A `terraform destroy`, or removing the key from `databases`, will drop them and Spanner keeps no backups by default.",
      join(", ", local.unprotected_databases)
    )
  }
}
