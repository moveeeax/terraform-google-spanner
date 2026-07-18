terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
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
  num_nodes    = 1

  databases = {
    app = {
      deletion_protection = false
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
