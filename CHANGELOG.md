## 2.1.0 (Feb 18th, 2022)

### Added
* Public access block settings for the bucket can now be configured with
  `var.public_access_block`. See the [inputs section in the README](https://github.com/infrablocks/terraform-aws-encrypted-bucket#inputs)
  or [Terraform registry entry](https://registry.terraform.io/modules/infrablocks/encrypted-bucket/aws/latest) for more details.
  The extra permissions required are specified in [required permissions](https://github.com/infrablocks/terraform-aws-encrypted-bucket#required-permissions).
* Access logging can be enabled with `var.enable_access_logging` (this will also creates a new bucket for the access logs). 
  To change the default name of the access bucket(`<bucket-name>-access-log`) use `var.access_log_bucket_name`. This is off by default.
* [S3 Bucket Keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html) can be enabled (when encryption is set to kms)
  by configuring `var.bucket_key_enabled`. This is off by default.

### Changed

* Removed `hashicorp/template` provider. This allows the module to be used with terraform
  on arm64 architectures.
* `kms_key_arn` is now an empty string by default, which is converted to null
when being passed to `server_side_encryption_configuration` to preserve module defaults.

## 2.0.0 (May 28th, 2021)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 0.14 and higher.
