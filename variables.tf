variable "project_id" {
  description = "ID of the project in which to create the Spanner instance."
  type        = string
}

variable "name" {
  description = "Name (instance id) of the Spanner instance."
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the instance."
  type        = string
}

variable "config" {
  description = "Instance configuration, e.g. regional-us-central1 or nam-eur-asia1."
  type        = string
  default     = "regional-us-central1"
}

variable "num_nodes" {
  description = "Number of nodes allocated to the instance. Mutually exclusive with processing_units; 1 node is equivalent to 1000 processing units. When both are null the instance is created with 1 node."
  type        = number
  default     = null

  validation {
    condition     = var.num_nodes == null || try(var.num_nodes >= 1, false)
    error_message = "num_nodes must be at least 1."
  }

  validation {
    condition     = var.num_nodes == null || try(floor(var.num_nodes) == var.num_nodes, false)
    error_message = "num_nodes must be a whole number."
  }
}

variable "processing_units" {
  description = "Processing units allocated to the instance. Mutually exclusive with num_nodes; 1000 processing units is equivalent to 1 node. Must be a multiple of 100 below 1000 and a multiple of 1000 at or above 1000."
  type        = number
  default     = null

  validation {
    condition     = var.processing_units == null || try(var.processing_units >= 100, false)
    error_message = "processing_units must be at least 100."
  }

  validation {
    condition = var.processing_units == null || try(
      var.processing_units < 1000 ? var.processing_units % 100 == 0 : var.processing_units % 1000 == 0,
      false
    )
    error_message = "processing_units must be a multiple of 100 below 1000, and a multiple of 1000 at or above 1000."
  }
}

variable "databases" {
  description = <<-EOT
    Databases to create within the instance, keyed by database name.

      ddl                      - DDL statements applied to the database.
      deletion_protection      - Blocks Terraform from deleting the database. Defaults to true.
      enable_drop_protection   - Blocks database drops through any interface, and blocks deletion of
                                 the parent instance. Defaults to false. Recommended for production.
      database_dialect         - GOOGLE_STANDARD_SQL (default) or POSTGRESQL. Forces replacement.
      version_retention_period - Point-in-time-recovery window, between 1h and 7d (e.g. "3d").
                                 Defaults to the Spanner default of 1h.
      kms_key_name             - Fully qualified Cloud KMS key for CMEK. Must live in the same
                                 location as the database. Null means Google-managed encryption.
                                 Forces replacement.
  EOT

  type = map(object({
    ddl                      = optional(list(string), [])
    deletion_protection      = optional(bool, true)
    enable_drop_protection   = optional(bool, false)
    database_dialect         = optional(string)
    version_retention_period = optional(string)
    kms_key_name             = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for db in values(var.databases) :
      db.database_dialect == null ? true : contains(["GOOGLE_STANDARD_SQL", "POSTGRESQL"], db.database_dialect)
    ])
    error_message = "database_dialect must be either GOOGLE_STANDARD_SQL or POSTGRESQL."
  }

  validation {
    condition = alltrue([
      for db in values(var.databases) :
      db.version_retention_period == null ? true : can(regex("^[1-9][0-9]*(s|m|h|d)$", db.version_retention_period))
    ])
    error_message = "version_retention_period must be a positive duration suffixed with s, m, h or d (e.g. \"3d\"), between 1h and 7d."
  }

  validation {
    condition = alltrue([
      for db in values(var.databases) :
      db.kms_key_name == null ? true : can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", db.kms_key_name))
    ])
    error_message = "kms_key_name must be a fully qualified key: projects/<project>/locations/<location>/keyRings/<ring>/cryptoKeys/<key>."
  }
}

variable "labels" {
  description = "Labels applied to the instance."
  type        = map(string)
  default     = {}
}
