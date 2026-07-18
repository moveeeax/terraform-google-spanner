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
  description = "Number of nodes allocated to the instance. Mutually exclusive with processing_units."
  type        = number
  default     = 1

  validation {
    condition     = var.num_nodes >= 1
    error_message = "num_nodes must be at least 1."
  }
}

variable "databases" {
  description = "Databases to create within the instance, keyed by database name."
  type = map(object({
    ddl                 = optional(list(string), [])
    deletion_protection = optional(bool, true)
  }))
  default = {}
}

variable "labels" {
  description = "Labels applied to the instance."
  type        = map(string)
  default     = {}
}
