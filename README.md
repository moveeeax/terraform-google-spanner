# terraform-google-spanner

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Spanner instance (`google_spanner_instance`) and an optional set of
databases driven by a map input.

## Usage

```hcl
module "spanner" {
  source = "github.com/cybercapybara/terraform-google-spanner"

  project_id   = var.project_id
  name         = "prod-instance"
  display_name = "Production Spanner"
  config       = "regional-us-central1"
  num_nodes    = 3

  databases = {
    orders = {
      ddl = ["CREATE TABLE t (id INT64) PRIMARY KEY (id)"]
    }
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name           | Description                                               | Type          | Default                   | Required |
|----------------|-----------------------------------------------------------|---------------|---------------------------|:--------:|
| `project_id`   | ID of the project in which to create the instance.        | `string`      | n/a                       |   yes    |
| `name`         | Name (instance id) of the Spanner instance.               | `string`      | n/a                       |   yes    |
| `display_name` | Human-readable display name for the instance.             | `string`      | n/a                       |   yes    |
| `config`       | Instance configuration.                                   | `string`      | `"regional-us-central1"`  |    no    |
| `num_nodes`    | Number of nodes allocated to the instance.                | `number`      | `1`                       |    no    |
| `databases`    | Databases keyed by name (ddl, deletion_protection).       | `map(object)` | `{}`                      |    no    |
| `labels`       | Labels applied to the instance.                           | `map(string)` | `{}`                      |    no    |

## Outputs

| Name           | Description                                       |
|----------------|---------------------------------------------------|
| `id`           | Identifier of the Spanner instance.              |
| `name`         | Name of the Spanner instance.                    |
| `state`        | Current state of the Spanner instance.           |
| `database_ids` | Identifiers of the databases created.            |

## License

[MIT](LICENSE)
