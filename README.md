# terraform-google-spanner

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Spanner instance (`google_spanner_instance`) and an optional set of
databases driven by a map input.

## Usage

```hcl
module "spanner" {
  source = "github.com/moveeeax/terraform-google-spanner"

  project_id   = var.project_id
  name         = "prod-instance"
  display_name = "Production Spanner"
  config       = "regional-us-central1"
  num_nodes    = 3

  databases = {
    orders = {
      ddl = ["CREATE TABLE t (id INT64) PRIMARY KEY (id)"]

      # Protect the data. See "Data protection" below.
      enable_drop_protection   = true
      version_retention_period = "7d"
      kms_key_name             = "projects/my-project/locations/us-central1/keyRings/spanner/cryptoKeys/db"
    }
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Data protection

Spanner holds data, so destruction semantics matter more than anything else in
this module.

| Control | Where | Module default | What it stops |
|---------|-------|----------------|---------------|
| `deletion_protection` | per database | `true` | Terraform deleting the database (`destroy`, or removing the key from `databases`). Terraform-side only. |
| `enable_drop_protection` | per database | `false` | Dropping the database through **any** interface, and deleting the **parent instance**. Enforced by the Spanner API. |
| `version_retention_period` | per database | Spanner default (`1h`) | Nothing, but it sets the point-in-time-recovery window. Max `7d`. |
| `kms_key_name` | per database | unset (Google-managed keys) | Nothing, but it switches the database to CMEK. |

Notes:

- `deletion_protection` defaults to `true`, matching the provider default. This
  module deliberately does not weaken it. To destroy a database you must set it
  to `false`, `terraform apply`, and only then `terraform destroy`.
- Spanner creates **no backups by default**. If you disable both
  `deletion_protection` and `enable_drop_protection` for a database, the module
  emits a plan-time warning from a `check` block, because at that point a
  `terraform destroy` drops the data with nothing to restore from.
- `enable_drop_protection` is the stronger of the two and is recommended for
  production. It also protects the instance, which has no protection flag of its
  own in the provider versions this module supports.
- `database_dialect` and `kms_key_name` force replacement of the database.
  Changing them on a live database destroys and recreates it.

## Instance sizing

`num_nodes` and `processing_units` are mutually exclusive; **1 node = 1000
processing units**. Set at most one:

- Set neither and you get a single node (the module's historical behaviour).
- Set `processing_units = 100` for the smallest billable instance, roughly a
  tenth of the cost of a full node.
- `processing_units` must be a multiple of 100 below 1000, and a multiple of
  1000 at or above 1000. This is validated at plan time.

Setting both fails at plan time via a resource precondition rather than at apply
time via a provider error.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

The test suite under `tests/` additionally needs Terraform >= 1.7 for
`mock_provider`. That requirement is not imposed on consumers of the module.

## Inputs

| Name               | Description                                                        | Type          | Default                   | Required |
|--------------------|--------------------------------------------------------------------|---------------|---------------------------|:--------:|
| `project_id`       | ID of the project in which to create the instance.                 | `string`      | n/a                       |   yes    |
| `name`             | Name (instance id) of the Spanner instance.                        | `string`      | n/a                       |   yes    |
| `display_name`     | Human-readable display name for the instance.                      | `string`      | n/a                       |   yes    |
| `config`           | Instance configuration.                                            | `string`      | `"regional-us-central1"`  |    no    |
| `num_nodes`        | Nodes allocated to the instance. Excludes `processing_units`.      | `number`      | `null` (effectively `1`)  |    no    |
| `processing_units` | Processing units allocated to the instance. Excludes `num_nodes`.  | `number`      | `null`                    |    no    |
| `databases`        | Databases keyed by name. See below.                                | `map(object)` | `{}`                      |    no    |
| `labels`           | Labels applied to the instance.                                    | `map(string)` | `{}`                      |    no    |

### `databases` object

| Attribute                  | Type           | Default              | Description                                                              |
|----------------------------|----------------|----------------------|--------------------------------------------------------------------------|
| `ddl`                      | `list(string)` | `[]`                 | DDL statements applied to the database.                                  |
| `deletion_protection`      | `bool`         | `true`               | Blocks Terraform from deleting the database.                             |
| `enable_drop_protection`   | `bool`         | `false`              | Blocks drops through any interface and deletion of the parent instance.  |
| `database_dialect`         | `string`       | `null`               | `GOOGLE_STANDARD_SQL` or `POSTGRESQL`. Forces replacement.               |
| `version_retention_period` | `string`       | `null` (Spanner: 1h) | PITR window between `1h` and `7d`, e.g. `"3d"`.                          |
| `kms_key_name`             | `string`       | `null`               | Fully qualified Cloud KMS key for CMEK. Forces replacement.              |

## Outputs

| Name           | Description                                       |
|----------------|---------------------------------------------------|
| `id`           | Identifier of the Spanner instance.              |
| `name`         | Name of the Spanner instance.                    |
| `state`        | Current state of the Spanner instance.           |
| `database_ids` | Identifiers of the databases created.            |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
tflint --recursive
```

## License

[MIT](LICENSE)
