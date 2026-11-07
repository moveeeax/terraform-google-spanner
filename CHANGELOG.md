# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `autoscaling` input: managed autoscaling through `autoscaling_config`
  (processing-unit limits plus high-priority CPU and storage targets). Mutually
  exclusive with `num_nodes` and `processing_units`, enforced by a resource
  precondition. Null by default, so existing plans do not change.

### Changed

- Minimum `hashicorp/google` provider version raised from `>= 5.0` to `>= 5.6`,
  the first release whose `google_spanner_instance` schema has
  `autoscaling_config`.

[Unreleased]: https://github.com/moveeeax/terraform-google-spanner/compare/v1.1.0...HEAD
