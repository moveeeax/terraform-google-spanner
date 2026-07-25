# Requires Terraform >= 1.7 for `mock_provider` (the module itself only needs
# >= 1.5 -- do not raise required_version in versions.tf for these tests).
# Run with: terraform test

mock_provider "google" {}

variables {
  project_id   = "test-project"
  name         = "test-instance"
  display_name = "Test Spanner"
}

run "database_deletion_protection_defaults_to_true" {
  variables {
    databases = {
      orders = {}
    }
  }

  assert {
    condition     = google_spanner_database.this["orders"].deletion_protection == true
    error_message = "deletion_protection must default to true; the provider default is true and the module must not weaken it."
  }
}

run "no_cmek_key_means_no_encryption_config_block" {
  variables {
    databases = {
      orders = {}
    }
  }

  assert {
    condition     = length(google_spanner_database.this["orders"].encryption_config) == 0
    error_message = "No CMEK key was supplied, so no encryption_config block should be emitted."
  }

  assert {
    condition     = google_spanner_database.this["orders"].enable_drop_protection == false
    error_message = "enable_drop_protection must default to false, matching the provider default."
  }
}

run "instance_defaults_to_one_node" {
  assert {
    condition     = google_spanner_instance.this.num_nodes == 1
    error_message = "Omitting both num_nodes and processing_units must still produce a one-node instance."
  }
}

# The interesting half of this case -- that num_nodes is *not* sent alongside
# processing_units -- is asserted by the second precondition on
# google_spanner_instance.this, because num_nodes is an optional+computed
# attribute whose post-apply value the mock provider fills in.
run "processing_units_suppresses_num_nodes" {
  variables {
    processing_units = 100
  }

  assert {
    condition     = google_spanner_instance.this.processing_units == 100
    error_message = "processing_units must be passed through to the instance."
  }
}

run "explicit_num_nodes_is_passed_through" {
  variables {
    num_nodes = 3
  }

  assert {
    condition     = google_spanner_instance.this.num_nodes == 3
    error_message = "num_nodes must be passed through to the instance."
  }
}

run "cmek_key_produces_encryption_config" {
  variables {
    databases = {
      orders = {
        kms_key_name = "projects/test-project/locations/us-central1/keyRings/spanner/cryptoKeys/db"
      }
    }
  }

  assert {
    condition     = one(google_spanner_database.this["orders"].encryption_config).kms_key_name == "projects/test-project/locations/us-central1/keyRings/spanner/cryptoKeys/db"
    error_message = "A supplied kms_key_name must be wired into encryption_config."
  }
}

run "drop_protection_and_pitr_are_passed_through" {
  variables {
    databases = {
      orders = {
        enable_drop_protection   = true
        version_retention_period = "7d"
        database_dialect         = "POSTGRESQL"
      }
    }
  }

  assert {
    condition     = google_spanner_database.this["orders"].enable_drop_protection == true
    error_message = "enable_drop_protection must be passed through to the database."
  }

  assert {
    condition     = google_spanner_database.this["orders"].version_retention_period == "7d"
    error_message = "version_retention_period must be passed through to the database."
  }

  assert {
    condition     = google_spanner_database.this["orders"].database_dialect == "POSTGRESQL"
    error_message = "database_dialect must be passed through to the database."
  }
}
