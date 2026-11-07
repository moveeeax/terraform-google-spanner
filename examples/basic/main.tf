terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "spanner" {
  source = "../.."

  project_id   = var.project_id
  name         = "example-instance"
  display_name = "Example Spanner"
  config       = "regional-${var.region}"

  # 100 processing units is the smallest billable Spanner instance; a full node
  # is 1000 processing units and roughly ten times the cost.
  processing_units = 100

  databases = {
    app = {
      # deletion_protection is deliberately left at its default of true.
      # To tear this example down: set it to false, `terraform apply`, then
      # `terraform destroy`. Spanner keeps no backups by default, so the extra
      # step is the point.
      version_retention_period = "3d"
    }
  }
}

variable "project_id" {
  description = "Project ID to deploy the example Spanner instance into."
  type        = string
}

variable "region" {
  description = "Region for the google provider and instance config."
  type        = string
  default     = "us-central1"
}

output "spanner_id" {
  value = module.spanner.id
}
