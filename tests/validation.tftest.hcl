# Requires Terraform >= 1.7 for `mock_provider`.
# Run with: terraform test

mock_provider "google" {}

variables {
  project_id   = "test-project"
  name         = "test-instance"
  display_name = "Test Spanner"
}

run "rejects_num_nodes_and_processing_units_together" {
  command = plan

  variables {
    num_nodes        = 1
    processing_units = 1000
  }

  expect_failures = [google_spanner_instance.this]
}

run "rejects_zero_num_nodes" {
  command = plan

  variables {
    num_nodes = 0
  }

  expect_failures = [var.num_nodes]
}

run "rejects_fractional_num_nodes" {
  command = plan

  variables {
    num_nodes = 1.5
  }

  expect_failures = [var.num_nodes]
}

run "rejects_processing_units_below_100" {
  command = plan

  variables {
    processing_units = 50
  }

  expect_failures = [var.processing_units]
}

run "rejects_processing_units_not_multiple_of_100" {
  command = plan

  variables {
    processing_units = 150
  }

  expect_failures = [var.processing_units]
}

run "rejects_processing_units_above_1000_not_multiple_of_1000" {
  command = plan

  variables {
    processing_units = 1500
  }

  expect_failures = [var.processing_units]
}

run "accepts_processing_units_multiple_of_1000" {
  command = plan

  variables {
    processing_units = 2000
  }

  assert {
    condition     = google_spanner_instance.this.processing_units == 2000
    error_message = "2000 processing units is a valid two-node-equivalent instance."
  }
}

run "rejects_invalid_database_dialect" {
  command = plan

  variables {
    databases = {
      orders = {
        database_dialect = "MYSQL"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_malformed_version_retention_period" {
  command = plan

  variables {
    databases = {
      orders = {
        version_retention_period = "7days"
      }
    }
  }

  expect_failures = [var.databases]
}

run "rejects_short_form_kms_key_name" {
  command = plan

  variables {
    databases = {
      orders = {
        kms_key_name = "spanner-key"
      }
    }
  }

  expect_failures = [var.databases]
}
