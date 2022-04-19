## Unreleased

### Added

* The `include_deny_unencrypted_inflight_operations_statement` variable, 
  defaulting to `true`, has been added allowing the corresponding statement to
  be excluded from the resulting bucket policy if required.
* The `include_deny_encryption_using_incorrect_algorithm_statement` variable,
  defaulting to `true`, has been added allowing the corresponding statement to
  be excluded from the resulting bucket policy if required.
* The `include_deny_encryption_using_incorrect_key_statement` variable, which
  only applies when using SSE-KMS encryption, defaulting to `true`, has been 
  added allowing the corresponding statement to be excluded from the resulting
  bucket policy if required.

### Changed

* The minimum supported AWS provider version is now 4.0.
* The `source_policy_json` variable is now called `source_policy_document`.
* All variables that previously accepted `"yes"` or `"no"` have now been
  converted to type `bool` accepting `true` or `false`.

### Removed

* The deprecated variable `mfa_delete` has now been removed and 
  `enable_mfa_delete` should be used instead.
* The deprecated variable `bucket_policy_template` has now been removed in
  favour of the newly added `include_*_statement` variables.

## 2.2.0 (Mar 3rd, 2022)

### Added

* Access logging can now be enabled by passing `"yes"` for the 
  `enable_access_logging` variable, along with the name of the access log 
  bucket in `access_log_bucket_name` and the object key prefix for log objects 
  in `access_log_object_key_prefix`. By default, access logging is disabled.
* When using SSE-KMS encryption for the bucket, by passing `kms_key_arn`, an 
  [S3 bucket key][4] can be enabled by passing `"yes"` for the 
  `enable_bucket_key` variable. By default, the bucket key is disabled.
* Versioning can now be disabled by passing `"no"` for the `enable_versioning`
  variable. By default, versioning is enabled.
* MFA delete should now be enabled by passing `"yes"` for the
  `enable_mfa_delete` variable. By default, MFA delete is disabled.
* The bucket policy added to the bucket now enforces that the 
  `"s3:x-amz-server-side-encryption"` header is present as well as set to the 
  correct SSE algorithm for the bucket. When the `kms_key_arn` variable is
  provided, such that SSE-KMS is used, the bucket policy additionally enforces
  that the correct KMS key ARN is passed in the 
  `"s3:x-amz-server-side-encryption-aws-kms-key-id"` header. If the 
  `bucket_policy_template` variable is provided, the template should 
  interpolate the fragments as shown in `policies/bucket-policy.json.tpl`.

### Fixed

* A regression was introduced that meant the `bucket_policy_template` variable 
  no longer had any effect. This was resolved by re-introducing the
  `hashicorp/template` provider so that a template provided as a string could
  be correctly populated. 

### Deprecated

* The `mfa_delete` variable has been superseded by the `enable_mfa_delete`
  variable.
* The `deny_unencrypted_object_upload_fragment` interpolation variable 
  previously available in the `bucket_policy_template` has been superseded by
  the `deny_encryption_using_incorrect_algorithm_fragment` and
  `deny_encryption_using_incorrect_key_fragment` interpolation variables.

## 2.1.0 (Feb 18th, 2022)

### Added

* Public access block settings for the bucket can now be configured with
  `var.public_access_block`. See the [inputs section in the README][3] or 
  [Terraform registry entry][2] for more details. The extra permissions required
  are specified in [required permissions][1].

### Changed

* Removed `hashicorp/template` provider. This allows the module to be used with
  terraform on arm64 architectures.
* `kms_key_arn` is now an empty string by default, which is converted to null
  when being passed to `server_side_encryption_configuration` to preserve module
  defaults.

## 2.0.0 (May 28th, 2021)

### Changed

* This module is now compatible with Terraform 0.14 and higher.

[1]: https://github.com/infrablocks/terraform-aws-encrypted-bucket#required-permissions "Required permissions"
[2]: https://registry.terraform.io/modules/infrablocks/encrypted-bucket/aws/latest "Terraform registry entry"
[3]: https://github.com/infrablocks/terraform-aws-encrypted-bucket#inputs "Inputs section in README"
[4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html "S3 bucket keys documentation"